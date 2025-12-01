import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_room_client/config/app_config.dart';
import '../models/schedule_item_model.dart';

class TripScheduleViewModel with ChangeNotifier {
  final String roomId;
  final String startDateStr;
  final String endDateStr;

  late List<DateTime> dates;
  Map<String, List<ScheduleItem>> schedule = {};
  bool isLoading = true;
  String? errorMessage;

  TripScheduleViewModel({
    required this.roomId,
    required this.startDateStr,
    required this.endDateStr,
  }) {
    _generateDates();
    fetchScheduleData();
  }

  void _generateDates() {
    final start = DateTime.parse(startDateStr);
    final end = DateTime.parse(endDateStr);
    final difference = end.difference(start).inDays;
    dates = List.generate(difference + 1, (i) => start.add(Duration(days: i)));
  }

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

  Future<void> fetchScheduleData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/$roomId/schedule'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        final Map<String, dynamic> scheduleData =
            responseData['schedule'] as Map<String, dynamic>;

        schedule = scheduleData.map((key, value) {
          final List<dynamic> items = value as List<dynamic>;
          final List<ScheduleItem> scheduleItems = items
              .asMap()
              .entries
              .map((entry) => ScheduleItem.fromJson(entry.value, entry.key))
              .toList();

          scheduleItems.sort(
            (a, b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(
              b.startTime.hour * 60 + b.startTime.minute,
            ),
          );
          return MapEntry(key, scheduleItems);
        });
      } else if (response.statusCode == 404) {
        schedule = {};
      } else {
        throw Exception('Failed to load schedule');
      }
    } catch (e) {
      errorMessage = '스케줄을 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteSchedule(
    int dayIndex,
    int itemIndex,
  ) async {
    try {
      final url = Uri.parse(
        '$kBaseUrl/api/rooms/$roomId/schedule/day/$dayIndex/$itemIndex',
      );
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        fetchScheduleData();
        return {'success': true, 'message': '일정이 삭제되었습니다.'};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '삭제 실패: $error'};
      }
    } catch (e) {
      return {'success': false, 'message': '오류 발생: $e'};
    }
  }

  Future<List<dynamic>?> getFeedbackHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'feedback_history_$roomId';
    final String? historyJson = prefs.getString(historyKey);

    if (historyJson == null || historyJson.isEmpty) {
      return null;
    }
    return json.decode(historyJson);
  }
}
