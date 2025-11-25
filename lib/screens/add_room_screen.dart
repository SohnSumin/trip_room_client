import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/countries.dart';
import '../config/app_config.dart';
import '../widgets/home_header.dart';

class AddRoomScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final String id;

  const AddRoomScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _titleController = TextEditingController();
  String? _selectedCountry;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _image;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createRoom() async {
    if (_titleController.text.isEmpty ||
        _selectedCountry == null ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('종료일은 시작일보다 빠를 수 없습니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/api/rooms'),
    );

    request.fields['title'] = _titleController.text;
    request.fields['country'] = _selectedCountry!;
    request.fields['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    request.fields['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    request.fields['creatorId'] = widget.userId;

    if (_image != null) {
      if (kIsWeb) {
        // 웹 환경
        request.files.add(
          http.MultipartFile(
            'image',
            _image!.readAsBytes().asStream(),
            await _image!.length(),
            filename: _image!.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // 모바일 환경
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _image!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행방이 성공적으로 생성되었습니다!')));
          // 홈 화면으로 돌아가서 리스트를 갱신하도록 합니다.
          Navigator.pop(context, true);
        }
      } else {
        final error = jsonDecode(responseBody)['error'];
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('생성 실패: $error')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                '여행방 추가하기',
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
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          _image!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_image!.path),
                                          fit: BoxFit.cover,
                                        ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 50),
                                      Text('대표 사진을 선택하세요'),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: '여행 이름'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
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
                            _selectedCountry = newValue;
                          });
                        },
                        isExpanded: true,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () => _selectDate(context, true),
                            child: Text(
                              _startDate == null
                                  ? '시작일 선택'
                                  : DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_startDate!),
                            ),
                          ),
                          const Text('~'),
                          TextButton(
                            onPressed: () => _selectDate(context, false),
                            child: Text(
                              _endDate == null
                                  ? '종료일 선택'
                                  : DateFormat('yyyy-MM-dd').format(_endDate!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('여행방 생성하기'),
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
