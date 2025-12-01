import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:convert';
import '../widgets/home_header.dart';
import '../config/app_config.dart';

class ScheduleFeedbackScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String nickname;
  final String id;

  const ScheduleFeedbackScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<ScheduleFeedbackScreen> createState() => _ScheduleFeedbackScreenState();
}

class _ScheduleFeedbackScreenState extends State<ScheduleFeedbackScreen> {
  String _loadingMessage = 'AI 피드백을 요청하는 중입니다...';
  String? _feedbackMessage;
  List<String>? _changes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAIFeedback();
  }

  // SharedPreferences에 피드백 저장
  Future<void> _saveFeedbackToHistory(
    String feedbackMessage,
    List<String> changes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'feedback_history_${widget.roomId}';

    // 1. 기존 기록 불러오기
    final String? historyJson = prefs.getString(historyKey);
    List<dynamic> history = historyJson != null ? json.decode(historyJson) : [];

    // 2. 새 피드백을 목록 맨 위에 추가
    history.insert(0, {
      'timestamp': DateTime.now().toIso8601String(),
      'feedback_message': feedbackMessage,
      'changes': changes,
    });

    // 3. 기록 개수를 10개로 제한 (선택 사항)
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    // 4. 업데이트된 기록 저장
    await prefs.setString(historyKey, json.encode(history));
  }

  Future<void> _fetchAIFeedback() async {
    try {
      setState(() {
        _loadingMessage = 'AI 피드백을 요청하는 중입니다...';
        _errorMessage = null;
      });

      // 1️⃣ POST 요청으로 AI 처리 시작
      final postResponse = await http.post(
        Uri.parse(
          '$kBaseUrl/api/rooms/${widget.roomId}/schedule/feedback/auto',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (postResponse.statusCode == 202) {
        // 2️⃣ 백그라운드 처리 중 → 폴링 시작
        setState(() {
          _loadingMessage = 'Gemini AI가 일정을 분석하고 있습니다...';
        });
        _pollForFeedback();
      } else {
        throw Exception('AI 피드백 요청 실패 (status: ${postResponse.statusCode})');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loadingMessage = '';
      });
    }
  }

  // 폴링 함수
  void _pollForFeedback({int retryCount = 0}) async {
    const maxRetries = 30; // 최대 30회 (~30초)
    const delaySec = 1;

    await Future.delayed(Duration(seconds: delaySec));

    try {
      final getResponse = await http.get(
        Uri.parse(
          '$kBaseUrl/api/rooms/${widget.roomId}/schedule/feedback/latest',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (getResponse.statusCode == 200) {
        // AI 처리 완료 → 결과 표시
        _handleFeedbackResponse(getResponse);
      } else if (getResponse.statusCode == 202 && retryCount < maxRetries) {
        // 아직 처리 중 → 재시도
        _pollForFeedback(retryCount: retryCount + 1);
      } else {
        throw Exception('AI 피드백을 가져오는데 실패했습니다.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loadingMessage = '';
      });
    }
  }

  // 공통 처리 함수
  void _handleFeedbackResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    final data = jsonDecode(body);

    setState(() {
      _feedbackMessage = data['feedback_message'];
      _changes = List<String>.from(data['changes'] ?? []);
      _loadingMessage = '';
    });

    // 기록 저장
    if (_feedbackMessage != null) {
      _saveFeedbackToHistory(_feedbackMessage!, _changes ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 배경 이미지
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/ai_feedback.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // 2. 메인 콘텐츠
          SafeArea(
            child: Column(
              children: [
                HomeHeader(
                  userId: widget.userId,
                  nickname: widget.nickname,
                  id: widget.id,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'AI 일정 피드백',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _loadingMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _loadingMessage,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : _buildFeedbackContent(),
                ),
                if (_loadingMessage.isEmpty && _errorMessage == null)
                  _buildConfirmButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // true 반환하여 새로고침
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            (_changes?.isNotEmpty ?? false) ? '확인' : '뒤로가기',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    if (_feedbackMessage == null && _changes == null) {
      return const Center(
        child: Text('피드백 데이터가 없습니다.', style: TextStyle(color: Colors.white)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'AI가 일정을 자동으로 최적화하고 적용했습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  '🤖 AI 피드백',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _feedbackMessage ?? '피드백 메시지가 없습니다.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_changes != null && _changes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white30),
                  const SizedBox(height: 24),
                  const Text(
                    '🔧 변경된 내용',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _changes!.map((change) => '• $change').join('\n'),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
