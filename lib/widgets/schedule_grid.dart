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

  @override
  Widget build(BuildContext context) {
    const timeCellHeight = 45.0; // 1시간 높이
    final minuteHeight = timeCellHeight / 14; // 5분당 높이
    const dateCellWidth = 130.0;
    const timeLabelWidth = 60.0;

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
                  color: Colors.grey[200],
                ),
                ...dates.map((d) {
                  return Container(
                    width: dateCellWidth,
                    height: timeCellHeight * 0.666,
                    alignment: Alignment.center,
                    color: Colors.grey[300],
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
                                top: BorderSide(color: Colors.grey[300]!),
                                right: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              '$h시',
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
                                    (totalEndMinutes - totalStartMinutes) /
                                    5 *
                                    minuteHeight;

                                return Positioned(
                                  top: totalStartMinutes / 5 * minuteHeight,
                                  left: 0,
                                  right: 0,
                                  height: height,
                                  child: GestureDetector(
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
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: a['color'] as Color,
                                        borderRadius: BorderRadius.zero,
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        a['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
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
