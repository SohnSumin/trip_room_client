import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/countries.dart';
import '../widgets/home_header.dart';
import '../config/app_config.dart';

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
  final _titleController = TextEditingController();
  String? _selectedCountry;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _image;
  String? _existingImageUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final details = widget.roomDetails;
    _titleController.text = details['title'] ?? '';
    final countryFromServer = details['country'];
    if (countryFromServer != null && countries.contains(countryFromServer)) {
      _selectedCountry = countryFromServer;
    }
    _startDate = DateTime.tryParse(details['startDate'] ?? '');
    _endDate = DateTime.tryParse(details['endDate'] ?? '');
    _existingImageUrl = details['imageId'];
  }

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
        _existingImageUrl = null; // 새 이미지를 선택하면 기존 이미지는 보이지 않게 함
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
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

  Future<void> _updateRoom() async {
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

    try {
      http.Response response;
      final url = Uri.parse('$kBaseUrl/api/rooms/${widget.roomId}');

      if (_image == null) {
        // 이미지가 없는 경우: application/json 으로 요청
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'title': _titleController.text,
          'country': _selectedCountry!,
          'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
          'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
        });
        response = await http.put(url, headers: headers, body: body);
      } else {
        // 이미지가 있는 경우: multipart/form-data 로 요청
        var request = http.MultipartRequest('PUT', url);
        request.fields['title'] = _titleController.text;
        request.fields['country'] = _selectedCountry!;
        request.fields['startDate'] = DateFormat(
          'yyyy-MM-dd',
        ).format(_startDate!);
        request.fields['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);

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
        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행방이 성공적으로 수정되었습니다!')));
          Navigator.pop(context, true); // 수정 성공 시 true 반환
        }
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('수정 실패: $error')));
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
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                            image: _image == null && _existingImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      '$kBaseUrl/api/images/$_existingImageUrl',
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
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
                              : (_existingImageUrl == null
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
                        onPressed: _isLoading ? null : _updateRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
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
