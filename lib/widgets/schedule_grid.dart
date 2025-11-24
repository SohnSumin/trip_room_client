import 'package:flutter/material.dart';

class ScheduleGrid extends StatelessWidget {
  final List<DateTime> dates;
  final Map<String, List<Map<String, dynamic>>> schedule;
  final Function(int dayIndex, Map<String, dynamic> scheduleItem) onUpdate;
  final Function(int dayIndex, int itemIndex) onDelete;

  const ScheduleGrid({
    super.key,
    required this.dates,
    required this.schedule,
    required this.onUpdate,
    required this.onDelete,
  });

  // 일정 종류에 따라 아이콘을 반환하는 헬퍼 함수
  IconData _getIconForTitle(String title) {
    if (title.contains('식사') ||
        title.contains('아침') ||
        title.contains('점심') ||
        title.contains('저녁')) {
      return Icons.restaurant;
    } else if (title.contains('공항') ||
        title.contains('비행기') ||
        title.contains('입국') ||
        title.contains('출국')) {
      return Icons.flight;
    } else if (title.contains('숙소') ||
        title.contains('호텔') ||
        title.contains('체크인')) {
      return Icons.hotel;
    } else if (title.contains('구경') ||
        title.contains('관광') ||
        title.contains('투어')) {
      return Icons.camera_alt;
    } else if (title.contains('쇼핑')) {
      return Icons.shopping_bag;
    }
    return Icons.location_on; // 기본 아이콘
  }

  @override
  Widget build(BuildContext context) {
    const timeCellHeight = 55.0; // 1시간 높이
    final minuteHeight = timeCellHeight / 60; // 1분당 높이로 변경
    const dateCellWidth = 160.0;
    const timeLabelWidth = 50.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            // 날짜 헤더
            Row(
              children: [
                Container(
                  width: timeLabelWidth,
                  height: timeCellHeight * 0.666,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey[400]!)),
                  ),
                ),
                ...dates.map((d) {
                  return Container(
                    width: dateCellWidth,
                    height: timeCellHeight * 0.666,
                    alignment: Alignment.center,
                    color: Colors.white,
                    child: Text(
                      '${d.month}/${d.day}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
            ),
            // 스케줄 그리드 (세로 스크롤 영역)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  height: timeCellHeight * 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 시간축
                      Column(
                        children: List.generate(24, (h) {
                          return Container(
                            width: timeLabelWidth,
                            height: timeCellHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Colors.grey[400]!),
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              h < 10 ? '0$h:00' : '$h:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                      ),
                      // 날짜별 컬럼
                      ...List.generate(dates.length, (i) {
                        final dayAppointments = schedule[i.toString()] ?? [];
                        return SizedBox(
                          width: dateCellWidth,
                          height: timeCellHeight * 24,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 격자
                              Column(
                                children: List.generate(24, (index) {
                                  return Container(
                                    height: timeCellHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              // 일정 블록
                              ...dayAppointments.asMap().entries.map((entry) {
                                final a = entry.value;
                                final startHour = a['startHour'] as int;
                                final startMinute =
                                    a['startMinute'] as int? ?? 0;
                                final endHour = a['endHour'] as int;
                                final endMinute = a['endMinute'] as int? ?? 0;

                                final totalStartMinutes =
                                    startHour * 60 + startMinute;
                                final totalEndMinutes =
                                    endHour * 60 + endMinute;
                                final height =
                                    (totalEndMinutes - totalStartMinutes) *
                                    minuteHeight;

                                return Positioned(
                                  top: totalStartMinutes * minuteHeight,
                                  left: 0,
                                  right: 0,
                                  height: height,
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(a['title'] as String),
                                          content: Text(
                                            '장소: ${a['place']}\n시간: ${a['startHour']}:${(a['startMinute'] as int).toString().padLeft(2, '0')}~${a['endHour']}:${(a['endMinute'] as int).toString().padLeft(2, '0')}',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                onUpdate(i, {
                                                  ...a,
                                                  'index': entry.key,
                                                });
                                              },
                                              child: const Text('수정'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                final bool?
                                                confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                        title: const Text(
                                                          '일정 삭제',
                                                        ),
                                                        content: const Text(
                                                          '정말로 이 일정을 삭제하시겠습니까?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              '취소',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              '삭제',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (confirmed == true) {
                                                  onDelete(i, entry.key);
                                                }
                                              },
                                              child: const Text(
                                                '삭제',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                        vertical: 2.0,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4.0),
                                        decoration: BoxDecoration(
                                          color: (a['color'] as Color)
                                              .withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getIconForTitle(a['title']),
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                a['title'] as String,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.left,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
