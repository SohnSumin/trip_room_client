import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_room_client/config/app_config.dart';

class HomeHeaderViewModel with ChangeNotifier {
  final String userId;
  bool _hasInvitations = false;

  HomeHeaderViewModel({required this.userId}) {
    checkInvitations();
  }

  bool get hasInvitations => _hasInvitations;

  Future<void> checkInvitations() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/invited/$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> invitedRooms = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _hasInvitations = invitedRooms.isNotEmpty;
      } else {
        _hasInvitations = false;
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시 뱃지를 표시하지 않음
      _hasInvitations = false;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
