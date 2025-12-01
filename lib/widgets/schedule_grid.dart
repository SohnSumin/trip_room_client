import 'package:flutter/material.dart';
import '../models/schedule_item_model.dart';

class ScheduleGrid extends StatelessWidget {
  final List<DateTime> dates;
  final Map<String, List<ScheduleItem>> schedule;
  final Function(int dayIndex, ScheduleItem scheduleItem) onUpdate;
  final Function(int dayIndex, int itemIndex) onDelete;

  const ScheduleGrid({
    super.key,
    required this.dates,
    required this.schedule,
    required this.onUpdate,
    required this.onDelete,
  });

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
        return Colors.blue;
    }
  }

  // 일정 제목에 따라 아이콘을 반환
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
    return Icons.location_on; // 그 외 기본 아이콘
  }

  @override
  Widget build(BuildContext context) {
    const timeCellHeight = 55.0; // 1시간 셀 높이
    final minuteHeight = timeCellHeight / 60; // 1분당 높이
    const dateCellWidth = 160.0;
    const timeLabelWidth = 50.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            // 상단 날짜 헤더
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
            // 스케줄 그리드 영역 (세로 스크롤 가능)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  height: timeCellHeight * 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측 시간 표시줄
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
                      // 날짜별 일정 컬럼
                      ...List.generate(dates.length, (i) {
                        final dayAppointments = schedule[i.toString()] ?? [];
                        return SizedBox(
                          width: dateCellWidth,
                          height: timeCellHeight * 24,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 배경 격자
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
                              // 개별 일정 블록
                              ...dayAppointments.asMap().entries.map((entry) {
                                final a = entry.value;
                                final totalStartMinutes =
                                    a.startTime.hour * 60 + a.startTime.minute;
                                final totalEndMinutes =
                                    a.endTime.hour * 60 + a.endTime.minute;
                                final height =
                                    (totalEndMinutes - totalStartMinutes) *
                                    minuteHeight;

                                return Positioned(
                                  top: totalStartMinutes * minuteHeight,
                                  left: 2,
                                  right: 2,
                                  height: height,
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            _buildScheduleDetailDialog(
                                              context,
                                              a,
                                              i,
                                              entry.key,
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
                                          color: _getColorFromString(
                                            a.color,
                                          ).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getIconForTitle(a.title),
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                a.title,
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

  Widget _buildScheduleDetailDialog(
    BuildContext context,
    ScheduleItem item,
    int dayIndex,
    int itemIndex,
  ) {
    return AlertDialog(
      title: Text(item.title),
      content: Text(
        '장소: ${item.place}\n시간: ${item.startTime.format(context)} ~ ${item.endTime.format(context)}',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onUpdate(dayIndex, item);
          },
          child: const Text('수정'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            final bool? confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('일정 삭제'),
                content: const Text('정말로 이 일정을 삭제하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              onDelete(dayIndex, itemIndex);
            }
          },
          child: const Text('삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
