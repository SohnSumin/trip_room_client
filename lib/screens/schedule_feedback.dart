import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'dart:convert';
import '../widgets/home_header.dart';

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
  final String baseUrl = "http://127.0.0.1:5000";
  String _loadingMessage = 'AI 피드백을 요청하는 중입니다...';
  String? _feedbackMessage;
  List<String>? _changes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAIFeedback();
  }

  Future<void> _fetchAIFeedback() async {
    try {
      // 단계별 메시지 업데이트
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _loadingMessage.isNotEmpty)
          setState(() => _loadingMessage = 'Gemini AI가 일정을 분석하고 있습니다...');
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}/schedule/feedback/auto'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      final contentType = response.headers['content-type'];
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        if (contentType != null && contentType.contains('application/json')) {
          final data = jsonDecode(body);
          setState(() {
            _feedbackMessage = data['feedback_message'];
            _changes = List<String>.from(data['changes'] ?? []);
          });
        } else {
          throw Exception('서버로부터 유효하지 않은 형식의 응답을 받았습니다.');
        }
      } else {
        String errorMessage = 'AI 피드백을 가져오는데 실패했습니다.';
        if (contentType != null && contentType.contains('application/json')) {
          final errorData = jsonDecode(body);
          errorMessage = errorData['error'] ?? errorMessage;
        } else {
          // HTML 오류 페이지 등이 온 경우, 상태 코드를 기반으로 메시지 표시
          errorMessage = '오류가 발생했습니다 (상태 코드: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) {
      setState(() => _loadingMessage = ''); // 로딩 완료
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
