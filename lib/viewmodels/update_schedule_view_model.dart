import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trip_room_client/config/app_config.dart';
import '../models/schedule_item_model.dart';

class UpdateScheduleViewModel with ChangeNotifier {
  final String roomId;
  final int dayIndex;
  final ScheduleItem scheduleItem;

  UpdateScheduleViewModel({
    required this.roomId,
    required this.dayIndex,
    required this.scheduleItem,
  }) {
    _initializeFields();
  }

  final formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController placeController;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late String _selectedColor;
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

  final Map<Color, String> _reverseColorMap = {
    Colors.red: 'red',
    Colors.green: 'green',
    Colors.blue: 'blue',
    Colors.teal: 'teal',
    Colors.purple: 'purple',
    Colors.orange: 'orange',
    Colors.amber: 'amber',
    Colors.grey: 'grey',
  };

  void _initializeFields() {
    titleController = TextEditingController(text: scheduleItem.title);
    placeController = TextEditingController(text: scheduleItem.place);
    _startTime = scheduleItem.startTime;
    _endTime = scheduleItem.endTime;

    // scheduleItem.color는 'red', 'blue' 같은 문자열입니다.
    // colorMap의 키에 해당 색상이 있는지 확인하고, 없으면 'blue'를 기본값으로 사용합니다.
    _selectedColor = colorMap.containsKey(scheduleItem.color)
        ? scheduleItem.color
        : 'blue';
  }

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

  Future<Map<String, dynamic>> updateSchedule() async {
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
      final scheduleIndex = scheduleItem.index;
      final url = Uri.parse(
        '$kBaseUrl/api/rooms/$roomId/schedule/day/$dayIndex/$scheduleIndex',
      );
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'item': toJson()});

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': '일정이 성공적으로 수정되었습니다!'};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '수정 실패: $error'};
      }
    } catch (e) {
      return {'success': false, 'message': '오류 발생: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text,
      'place': placeController.text,
      'startHour': _startTime!.hour,
      'startMinute': _startTime!.minute,
      'endHour': _endTime!.hour,
      'endMinute': _endTime!.minute,
      'color': _selectedColor,
    };
  }

  @override
  void dispose() {
    titleController.dispose();
    placeController.dispose();
    super.dispose();
  }
}
