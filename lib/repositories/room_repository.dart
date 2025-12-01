import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/room_model.dart';

class RoomRepository {
  Future<Room> fetchRoomDetails(String roomId) async {
    final response = await http.get(Uri.parse('$kBaseUrl/api/rooms/$roomId'));
    if (response.statusCode == 200) {
      return Room.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load room details');
    }
  }

  Future<List<dynamic>> fetchRoomMembers(String roomId) async {
    final response = await http.get(
      Uri.parse('$kBaseUrl/api/rooms/$roomId/members'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to load room members');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final response = await http.delete(
      Uri.parse('$kBaseUrl/api/rooms/$roomId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete room');
    }
  }
}
