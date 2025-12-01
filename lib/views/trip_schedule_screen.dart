import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_room_client/viewmodels/trip_schedule_view_model.dart';
import '../widgets/home_header.dart';
import '../models/schedule_item_model.dart';
import 'add_schedule_screen.dart'; // 경로 변경
import '../widgets/schedule_grid.dart';
import 'schedule_feedback.dart';
import 'update_schedule_screen.dart'; // 경로 변경

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
  late final TripScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TripScheduleViewModel(
      roomId: widget.roomId,
      startDateStr: widget.startDate,
      endDateStr: widget.endDate,
    );
    _viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
      if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
      }
    }
  }

  Future<void> _deleteSchedule(int dayIndex, int itemIndex) async {
    final result = await _viewModel.deleteSchedule(dayIndex, itemIndex);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  void _handleUpdateSchedule(int dayIndex, ScheduleItem scheduleItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScheduleScreen(
          userId: widget.userId,
          nickname: widget.nickname,
          id: widget.id,
          roomId: widget.roomId,
          dayIndex: dayIndex,
          date: _viewModel.dates[dayIndex],
          scheduleItem: scheduleItem,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _viewModel.fetchScheduleData();
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
              itemCount: _viewModel.dates.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    '${index + 1}일차: ${DateFormat('M/d(E)', 'ko_KR').format(_viewModel.dates[index])}',
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
                          date: _viewModel.dates[index],
                        ),
                      ),
                    ).then((result) {
                      if (result == true) _viewModel.fetchScheduleData();
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
        _viewModel.fetchScheduleData(); // AI 추천 일정이 적용되었으므로 새로고침
      }
    });
  }

  // 이전 AI 피드백 기록을 보여주는 다이얼로그
  Future<void> _showFeedbackHistory() async {
    final history = await _viewModel.getFeedbackHistory();

    if (!mounted) return;

    if (history == null || history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장된 AI 피드백 기록이 없습니다.')));
      return;
    }

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
              icon: const Icon(Icons.calendar_today), // 현재 화면 아이콘
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
        padding: const EdgeInsets.only(bottom: 70.0),
        // 하단 네비게이션 바와의 간격을 위해 패딩 추가
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
              child: _viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ScheduleGrid(
                      dates: _viewModel.dates,
                      schedule: _viewModel.schedule,
                      onUpdate: _handleUpdateSchedule,
                      onDelete: _deleteSchedule,
                    ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }
}
