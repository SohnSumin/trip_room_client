import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class InvitationDrawer extends StatefulWidget {
  final String userId;
  final VoidCallback onInvitationHandled;

  const InvitationDrawer({
    super.key,
    required this.userId,
    required this.onInvitationHandled,
  });

  @override
  State<InvitationDrawer> createState() => _InvitationDrawerState();
}

class _InvitationDrawerState extends State<InvitationDrawer> {
  List<dynamic> invitedRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvitedRooms();
  }

  Future<void> _fetchInvitedRooms() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/api/rooms/invited/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          invitedRooms = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      // 에러 처리
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInvite(String roomId, bool accept) async {
    final action = accept ? 'accept' : 'decline';
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/api/rooms/$roomId/$action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대를 ${accept ? '수락' : '거절'}했습니다.')),
        );
        widget.onInvitationHandled(); // 홈 화면 갱신 콜백 호출
        _fetchInvitedRooms(); // 드로어 목록 갱신
      } else {
        final error = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '초대받은 여행방',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : invitedRooms.isEmpty
                  ? const Center(child: Text('초대받은 여행방이 없습니다.'))
                  : ListView.builder(
                      itemCount: invitedRooms.length,
                      itemBuilder: (context, index) {
                        final room = invitedRooms[index];
                        return ListTile(
                          title: Text(room['title'] ?? '제목 없음'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _handleInvite(room['_id'], true),
                                child: const Text('수락'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _handleInvite(room['_id'], false),
                                child: const Text(
                                  '거절',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
