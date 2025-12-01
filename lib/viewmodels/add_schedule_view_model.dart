import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trip_room_client/config/app_config.dart';

class AddScheduleViewModel with ChangeNotifier {
  final String roomId;
  final int dayIndex;

  AddScheduleViewModel({required this.roomId, required this.dayIndex});

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final placeController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedColor = 'blue';
  bool _isLoading = false;

  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  String get selectedColor => _selectedColor;
  bool get isLoading => _isLoading;

  final Map<String, Color> colorMap = {
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'teal': Colors.teal,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'amber': Colors.amber,
    'grey': Colors.grey,
  };

  void setStartTime(TimeOfDay? time) {
    _startTime = time;
    notifyListeners();
  }

  void setEndTime(TimeOfDay? time) {
    _endTime = time;
    notifyListeners();
  }

  void setSelectedColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addSchedule() async {
    if (!formKey.currentState!.validate()) {
      return {'success': false, 'message': '모든 필드를 올바르게 입력해주세요.'};
    }
    if (_startTime == null || _endTime == null) {
      return {'success': false, 'message': '시작 시간과 종료 시간을 모두 선택해주세요.'};
    }

    if ((_startTime!.hour * 60 + _startTime!.minute) >=
        (_endTime!.hour * 60 + _endTime!.minute)) {
      return {'success': false, 'message': '종료 시간은 시작 시간보다 늦어야 합니다.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        '$kBaseUrl/api/rooms/$roomId/schedule/day/$dayIndex',
      );
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'item': {
          'title': titleController.text,
          'place': placeController.text,
          'startHour': _startTime!.hour,
          'startMinute': _startTime!.minute,
          'endHour': _endTime!.hour,
          'endMinute': _endTime!.minute,
          'color': _selectedColor,
        },
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': '일정이 성공적으로 추가되었습니다!'};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '추가 실패: $error'};
      }
    } catch (e) {
      return {'success': false, 'message': '오류 발생: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    placeController.dispose();
    super.dispose();
  }
}
