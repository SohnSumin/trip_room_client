import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_room_client/viewmodels/update_schedule_view_model.dart';
import '../widgets/home_header.dart';
import '../models/schedule_item_model.dart';

class UpdateScheduleScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final String id;
  final String roomId;
  final int dayIndex;
  final DateTime date;
  final ScheduleItem scheduleItem;

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
  late final UpdateScheduleViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UpdateScheduleViewModel(
      roomId: widget.roomId,
      dayIndex: widget.dayIndex,
      scheduleItem: widget.scheduleItem,
    );
    _viewModel.addListener(_onViewModelUpdated);
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          (isStartTime ? _viewModel.startTime : _viewModel.endTime) ??
          TimeOfDay.now(),
    );
    if (isStartTime) {
      _viewModel.setStartTime(picked);
    } else {
      _viewModel.setEndTime(picked);
    }
  }

  Future<void> _updateSchedule() async {
    final result = await _viewModel.updateSchedule();
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['success']) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
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
                    key: _viewModel.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _viewModel.titleController,
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
                          controller: _viewModel.placeController,
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
                                    _viewModel.startTime == null
                                        ? '선택'
                                        : _viewModel.startTime!.format(context),
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
                                    _viewModel.endTime == null
                                        ? '선택'
                                        : _viewModel.endTime!.format(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _viewModel.selectedColor,
                          decoration: const InputDecoration(labelText: '색상'),
                          items: _viewModel.colorMap.keys.map((
                            String colorName,
                          ) {
                            return DropdownMenuItem<String>(
                              value: colorName,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: _viewModel.colorMap[colorName],
                                  ),
                                  const SizedBox(width: 10),
                                  Text(colorName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _viewModel.setSelectedColor(newValue!);
                            });
                          },
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _viewModel.isLoading
                              ? null
                              : _updateSchedule,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _viewModel.isLoading
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
