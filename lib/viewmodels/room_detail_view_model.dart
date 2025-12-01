import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trip_room_client/config/app_config.dart';
import '../models/member_model.dart';
import '../models/room_model.dart';

class RoomDetailViewModel with ChangeNotifier {
  final String roomId;
  final String currentUserId;

  RoomDetail? _roomDetails;
  List<Member> _members = [];
  bool _isLoading = true;
  bool _isMembersLoading = true;
  String? _errorMessage;

  RoomDetail? get roomDetails => _roomDetails;
  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  bool get isMembersLoading => _isMembersLoading;
  String? get errorMessage => _errorMessage;

  bool get isMember => _roomDetails?.members.contains(currentUserId) ?? false;
  bool get isOwner => _roomDetails?.creatorId == currentUserId;

  RoomDetailViewModel({required this.roomId, required this.currentUserId}) {
    fetchAllDetails();
  }

  void fetchAllDetails() {
    fetchRoomDetails();
    fetchMembers();
  }

  Future<void> fetchRoomDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$kBaseUrl/api/rooms/$roomId'));
      if (response.statusCode == 200) {
        _roomDetails = RoomDetail.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else {
        _errorMessage = '방 정보를 불러오는 데 실패했습니다.';
      }
    } catch (e) {
      _errorMessage = '방 정보 로딩 중 오류 발생: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMembers() async {
    _isMembersLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/$roomId/members'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        _members = decodedData.map((data) => Member.fromJson(data)).toList();
      } else {
        _errorMessage = '멤버 정보를 불러오는 데 실패했습니다.';
      }
    } catch (e) {
      _errorMessage = '멤버 정보 로딩 중 오류 발생: $e';
    } finally {
      _isMembersLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRoom() async {
    if (!isOwner) {
      _errorMessage = '방장만 삭제할 수 있습니다.';
      notifyListeners();
      return false;
    }
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/api/rooms/$roomId'),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        _errorMessage =
            jsonDecode(utf8.decode(response.bodyBytes))['error'] ?? '삭제 실패';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '삭제 중 오류 발생: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveRoom() async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/rooms/$roomId/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': currentUserId}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        _errorMessage =
            jsonDecode(utf8.decode(response.bodyBytes))['error'] ?? '나가기 실패';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '나가기 중 오류 발생: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> inviteMember(String inviteeId) async {
    if (inviteeId.isEmpty) {
      return {'success': false, 'message': '초대할 사용자의 ID를 입력해주세요.'};
    }

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/rooms/$roomId/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'inviteeId': inviteeId}),
      );

      if (response.statusCode == 200) {
        fetchMembers(); // 멤버 목록 새로고침
        return {'success': true, 'message': '초대했습니다.'};
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes))['error'];
        return {'success': false, 'message': '초대 실패: $error'};
      }
    } catch (e) {
      return {'success': false, 'message': '초대 중 오류 발생: $e'};
    }
  }

  // ViewModel에서 컨트롤러를 관리할 필요가 없는 경우, 이 메서드는 필요 없습니다.
  // 하지만 만약 ViewModel이 컨트롤러의 생명주기를 관리해야 한다면 여기에 추가합니다.
  @override
  void dispose() {
    // 예: titleController.dispose();
    super.dispose();
  }
}
