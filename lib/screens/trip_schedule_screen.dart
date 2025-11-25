import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';
import 'add_schedule_screen.dart';
import '../widgets/schedule_grid.dart';
import 'schedule_feedback.dart';
import '../config/app_config.dart';
import 'update_schedule_screen.dart';

class TripScheduleScreen extends StatefulWidget {
  final String roomId;
  final String startDate;
  final String endDate;
  final String userId;
  final String nickname;
  final String id;

  const TripScheduleScreen({
    super.key,
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<TripScheduleScreen> createState() => _TripScheduleScreenState();
}

class _TripScheduleScreenState extends State<TripScheduleScreen> {
  late List<DateTime> dates;
  Map<String, List<Map<String, dynamic>>> schedule = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateDates();
    _fetchScheduleData();
  }

  void _generateDates() {
    final start = DateTime.parse(widget.startDate);
    final end = DateTime.parse(widget.endDate);
    final difference = end.difference(start).inDays;
    dates = List.generate(difference + 1, (i) => start.add(Duration(days: i)));
  }

  // 서버에서 받은 색상 이름 문자열을 Color 객체로 변환하는 헬퍼 함수
  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'teal':
        return Colors.teal;
      case 'blueaccent':
        return Colors.blueAccent;
      case 'redaccent':
        return Colors.redAccent;
      case 'indigo':
        return Colors.indigo;
      case 'lightblue':
        return Colors.lightBlue;
      case 'deeporange':
        return Colors.deepOrange;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'cyan':
        return Colors.cyan;
      case 'amber':
        return Colors.amber;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.blue; // 매칭되는 색상이 없을 경우 기본 색상
    }
  }

  Future<void> _fetchScheduleData() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/api/rooms/${widget.roomId}/schedule', // API 엔드포인트
        ), // 'schedules' -> 'schedule'
      );
      if (response.statusCode == 200) {
        // schedules.py 응답 형식에 맞게 수정
        final Map<String, dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final Map<String, dynamic> scheduleData =
            responseData['schedule'] as Map<String, dynamic>;

        final Map<String, List<Map<String, dynamic>>> convertedSchedule =
            scheduleData.map((key, value) {
              final List<dynamic> items = value as List<dynamic>;
              final List<Map<String, dynamic>> typedItems = items.map((item) {
                final scheduleItem = item as Map<String, dynamic>;
                scheduleItem['color'] = _getColorFromString(
                  scheduleItem['color'] as String,
                );
                return scheduleItem;
              }).toList();

              // 시간순으로 정렬
              typedItems.sort(
                (a, b) => (a['startHour'] * 60 + a['startMinute']).compareTo(
                  b['startHour'] * 60 + b['startMinute'],
                ),
              );

              return MapEntry(key, typedItems);
            });

        setState(() {
          schedule = convertedSchedule;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // 스케줄이 없는 경우 (404)
        setState(() {
          schedule = {}; // 빈 맵으로 설정
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load schedule');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('스케줄을 불러오는 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _deleteSchedule(int dayIndex, int itemIndex) async {
    try {
      final url = Uri.parse(
        '$kBaseUrl/api/rooms/${widget.roomId}/schedule/day/$dayIndex/$itemIndex',
      );
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일정이 삭제되었습니다.')));
        }
        _fetchScheduleData(); // Refresh schedule
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $error')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    }
  }

  void _handleUpdateSchedule(int dayIndex, Map<String, dynamic> scheduleItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScheduleScreen(
          userId: widget.userId,
          nickname: widget.nickname,
          id: widget.id,
          roomId: widget.roomId,
          dayIndex: dayIndex,
          date: dates[dayIndex],
          scheduleItem: scheduleItem,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _fetchScheduleData();
      }
    });
  }

  Future<void> _showDaySelectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일정을 추가할 날짜 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dates.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    '${index + 1}일차: ${DateFormat('M/d(E)', 'ko_KR').format(dates[index])}',
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddScheduleScreen(
                          userId: widget.userId,
                          nickname: widget.nickname,
                          id: widget.id,
                          roomId: widget.roomId,
                          dayIndex: index,
                          date: dates[index],
                        ),
                      ),
                    ).then((result) {
                      if (result == true) _fetchScheduleData();
                    });
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleAIFeedback() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFeedbackScreen(
          roomId: widget.roomId,
          userId: widget.userId,
          nickname: widget.nickname,
          id: widget.id,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _fetchScheduleData(); // AI 추천 일정이 적용되었으므로 새로고침
      }
    });
  }

  // 이전 AI 피드백 기록을 보여주는 다이얼로그
  Future<void> _showFeedbackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'feedback_history_${widget.roomId}';
    final String? historyJson = prefs.getString(historyKey);

    if (!mounted) return;

    if (historyJson == null || historyJson.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장된 AI 피드백 기록이 없습니다.')));
      return;
    }

    final List<dynamic> history = json.decode(historyJson);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('AI 피드백 기록'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final feedback = history[index];
                final timestamp = DateTime.parse(feedback['timestamp']);
                final formattedDate = DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format(timestamp);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(feedback['feedback_message'] ?? '피드백 없음'),
                            if (feedback['changes'] != null &&
                                (feedback['changes'] as List).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '변경 내역:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                (feedback['changes'] as List)
                                    .map((c) => '• $c')
                                    .join('\n'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {
                    'userId': widget.userId,
                    'nickname': widget.nickname,
                    'id': widget.id,
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              color: Colors.white,
              onPressed: () {
                // 상세 정보 화면으로 돌아가기
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today), // 현재 화면 아이콘 (채워진 모양)
              color: Colors.white,
              onPressed: () {}, // 현재 화면이므로 동작 없음
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 70.0,
        ), // 하단 네비게이션 바와의 간격을 위해 패딩 추가
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'ai_feedback',
              onPressed: _handleAIFeedback,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'feedback_history',
              onPressed: _showFeedbackHistory,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.history, color: Colors.white),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'add_schedule',
              onPressed: _showDaySelectionDialog,
              backgroundColor: const Color(0xFFFF6000),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              userId: widget.userId,
              nickname: widget.nickname,
              id: widget.id,
              onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
                arguments: {
                  'userId': widget.userId,
                  'nickname': widget.nickname,
                  'id': widget.id,
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ScheduleGrid(
                      dates: dates,
                      schedule: schedule,
                      onUpdate: _handleUpdateSchedule,
                      onDelete: _deleteSchedule,
                    ),
            ), // Expanded
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }
}
