import 'package:flutter/material.dart';

class ScheduleItem {
  final String? id;
  final String title;
  final String place;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String color;
  final int? index; // 리스트 내에서의 인덱스

  ScheduleItem({
    this.id,
    required this.title,
    required this.place,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.index,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json, int itemIndex) {
    return ScheduleItem(
      id: json['_id'],
      title: json['title'],
      place: json['place'],
      startTime: TimeOfDay(
        hour: json['startHour'],
        minute: json['startMinute'],
      ),
      endTime: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
      color: json['color'],
      index: itemIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'place': place,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'color': color,
    };
  }
}
