import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';

class CreateRoomViewModel with ChangeNotifier {
  final String userId;

  CreateRoomViewModel({required this.userId});

  final titleController = TextEditingController();
  String? _selectedCountry;
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _image;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  String? get selectedCountry => _selectedCountry;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  XFile? get image => _image;
  bool get isLoading => _isLoading;

  void setSelectedCountry(String? country) {
    _selectedCountry = country;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      _image = pickedImage;
      notifyListeners();
    }
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (isStartDate) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createRoom() async {
    if (titleController.text.isEmpty ||
        _selectedCountry == null ||
        _startDate == null ||
        _endDate == null ||
        _image == null) {
      return {'success': false, 'message': '모든 필드를 입력해주세요.'};
    }

    if (_endDate!.isBefore(_startDate!)) {
      return {'success': false, 'message': '종료일은 시작일보다 빠를 수 없습니다.'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/api/rooms'),
      );
      request.fields['title'] = titleController.text;
      request.fields['country'] = _selectedCountry!;
      request.fields['startDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(_startDate!);
      request.fields['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      request.fields['creatorId'] = userId;

      if (kIsWeb) {
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
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _image!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {'success': true, 'message': '여행방이 성공적으로 생성되었습니다!'};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '생성 실패: $error'};
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
    super.dispose();
  }
}
