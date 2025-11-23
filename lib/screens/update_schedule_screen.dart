import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';

class UpdateScheduleScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final String id;
  final String roomId;
  final int dayIndex;
  final DateTime date;
  final Map<String, dynamic> scheduleItem;

  const UpdateScheduleScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
    required this.roomId,
    required this.dayIndex,
    required this.date,
    required this.scheduleItem,
  });

  @override
  State<UpdateScheduleScreen> createState() => _UpdateScheduleScreenState();
}

class _UpdateScheduleScreenState extends State<UpdateScheduleScreen> {
  final String baseUrl = "http://127.0.0.1:5000";
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _placeController;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late String _selectedColor;
  bool _isLoading = false;

  final Map<String, Color> _colorMap = {
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.scheduleItem['title'],
    );
    _placeController = TextEditingController(
      text: widget.scheduleItem['place'],
    );
    _startTime = TimeOfDay(
      hour: widget.scheduleItem['startHour'],
      minute: widget.scheduleItem['startMinute'],
    );
    _endTime = TimeOfDay(
      hour: widget.scheduleItem['endHour'],
      minute: widget.scheduleItem['endMinute'],
    );
    _selectedColor = _reverseColorMap[widget.scheduleItem['color']] ?? 'blue';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _updateSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('시작 시간과 종료 시간을 모두 선택해주세요.')));
      return;
    }

    if ((_startTime!.hour * 60 + _startTime!.minute) >=
        (_endTime!.hour * 60 + _endTime!.minute)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료 시간은 시작 시간보다 늦어야 합니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheduleIndex = widget.scheduleItem['index'];
      final url = Uri.parse(
        '$baseUrl/api/rooms/${widget.roomId}/schedule/day/${widget.dayIndex}/$scheduleIndex',
      );
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'item': {
          'title': _titleController.text,
          'place': _placeController.text,
          'startHour': _startTime!.hour,
          'startMinute': _startTime!.minute,
          'endHour': _endTime!.hour,
          'endMinute': _endTime!.minute,
          'color': _selectedColor,
        },
      });

      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일정이 성공적으로 수정되었습니다!')));
          Navigator.pop(context, true); // 성공 시 true 반환
        }
      } else {
        String errorMessage;
        try {
          errorMessage = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        } catch (e) {
          errorMessage = utf8.decode(response.bodyBytes);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('수정 실패: $errorMessage')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '${DateFormat('M/d(E)', 'ko_KR').format(widget.date)} 일정 수정',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '일정 이름'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '일정 이름을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _placeController,
                          decoration: const InputDecoration(
                            labelText: '장소',
                            hintText: 'Google Maps API 연동 예정',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '장소를 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('시작 시간'),
                                TextButton(
                                  onPressed: () => _selectTime(context, true),
                                  child: Text(
                                    _startTime == null
                                        ? '선택'
                                        : _startTime!.format(context),
                                  ),
                                ),
                              ],
                            ),
                            const Text('~'),
                            Column(
                              children: [
                                const Text('종료 시간'),
                                TextButton(
                                  onPressed: () => _selectTime(context, false),
                                  child: Text(
                                    _endTime == null
                                        ? '선택'
                                        : _endTime!.format(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedColor,
                          decoration: const InputDecoration(labelText: '색상'),
                          items: _colorMap.keys.map((String colorName) {
                            return DropdownMenuItem<String>(
                              value: colorName,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: _colorMap[colorName],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(colorName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedColor = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateSchedule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('일정 수정하기'),
                        ),
                      ],
                    ),
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
