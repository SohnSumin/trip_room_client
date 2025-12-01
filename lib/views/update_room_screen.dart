import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:trip_room_client/data/countries.dart';
import '../widgets/home_header.dart'; // 경로 변경 없음
import '../config/app_config.dart';
import '../viewmodels/update_room_view_model.dart';

class UpdateRoomScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final String id;
  final String roomId;
  final Map<String, dynamic> roomDetails;

  const UpdateRoomScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
    required this.roomId,
    required this.roomDetails,
  });

  @override
  State<UpdateRoomScreen> createState() => _UpdateRoomScreenState();
}

class _UpdateRoomScreenState extends State<UpdateRoomScreen> {
  late final UpdateRoomViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UpdateRoomViewModel(
      roomId: widget.roomId,
      roomDetails: widget.roomDetails,
    );
    _viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateRoom() async {
    final result = await _viewModel.updateRoom();
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));

    if (result['success']) {
      Navigator.pop(context, true); // 수정 성공 시 true를 반환
    }
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
              onLogoTap: () {
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '여행방 수정하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _viewModel.pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                            image:
                                _viewModel.image == null &&
                                    _viewModel.existingImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      '$kBaseUrl/api/images/${_viewModel.existingImageUrl}',
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _viewModel.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          _viewModel.image!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_viewModel.image!.path),
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : (_viewModel.existingImageUrl == null
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt, size: 50),
                                            Text('대표 사진을 변경하려면 터치하세요'),
                                          ],
                                        ),
                                      )
                                    : null),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _viewModel.titleController,
                        decoration: const InputDecoration(labelText: '여행 이름'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _viewModel.selectedCountry,
                        hint: const Text('여행 국가 선택'),
                        decoration: const InputDecoration(labelText: '여행 국가'),
                        items: countries.map((String country) {
                          return DropdownMenuItem<String>(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _viewModel.setSelectedCountry(newValue);
                          });
                        },
                        isExpanded: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () =>
                                _viewModel.selectDate(context, true),
                            child: Text(
                              _viewModel.startDate == null
                                  ? '시작일 선택'
                                  : DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_viewModel.startDate!),
                            ),
                          ),
                          const Text('~'),
                          TextButton(
                            onPressed: () =>
                                _viewModel.selectDate(context, false),
                            child: Text(
                              _viewModel.endDate == null
                                  ? '종료일 선택'
                                  : DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_viewModel.endDate!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _updateRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _viewModel.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('여행방 수정하기'),
                      ),
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
