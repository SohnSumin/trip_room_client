import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trip_room_client/config/app_config.dart';
import '../models/room_model.dart';

class HomeViewModel with ChangeNotifier {
  final String userId;

  List<Room> _rooms = [];
  List<Room> _invitedRooms = [];
  bool _isLoading = true;
  bool _isInvitedLoading = true;
  String? _errorMessage;

  List<Room> get rooms => _rooms;
  List<Room> get invitedRooms => _invitedRooms;
  bool get isLoading => _isLoading;
  bool get isInvitedLoading => _isInvitedLoading;
  String? get errorMessage => _errorMessage;

  HomeViewModel({required this.userId}) {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    await Future.wait([fetchRooms(), fetchInvitedRooms()]);
  }

  Future<void> fetchRooms() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/user/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _rooms = decodedData.map((data) => Room.fromJson(data)).toList();
      } else {
        _errorMessage = '여행방 목록을 불러오는데 실패했습니다.';
      }
    } catch (e) {
      _errorMessage = '오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvitedRooms() async {
    _isInvitedLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/invited/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _invitedRooms = decodedData.map((data) => Room.fromJson(data)).toList();
      } else {
        _errorMessage = '초대받은 여행방 목록을 불러오는데 실패했습니다.';
      }
    } catch (e) {
      _errorMessage = '오류 발생: $e';
    } finally {
      _isInvitedLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _handleInvitation(
    String roomId,
    String action,
  ) async {
    try {
      final url = Uri.parse('$kBaseUrl/api/rooms/$roomId/invitation');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'userId': userId, 'action': action});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        fetchAllData(); // 데이터 새로고침
        return {
          'success': true,
          'message': action == 'accept' ? '초대를 수락했습니다.' : '초대를 거절했습니다.',
        };
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '오류: $error'};
      }
    } catch (e) {
      return {'success': false, 'message': '오류 발생: $e'};
    }
  }

  Future<Map<String, dynamic>> acceptInvitation(String roomId) {
    return _handleInvitation(roomId, 'accept');
  }

  Future<Map<String, dynamic>> rejectInvitation(String roomId) {
    return _handleInvitation(roomId, 'reject');
  }
}
