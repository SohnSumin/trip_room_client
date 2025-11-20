import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeopleCard extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final String ownerLoginId;
  final String ownerId;
  final List<dynamic> members;
  final VoidCallback onMembersChanged;

  const PeopleCard({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.ownerLoginId,
    required this.ownerId,
    required this.members,
    required this.onMembersChanged,
  });

  @override
  State<PeopleCard> createState() => _PeopleCardState();
}

class _PeopleCardState extends State<PeopleCard> {
  final String baseUrl = "http://127.0.0.1:5000";
  final TextEditingController _inviteIdController = TextEditingController();

  bool get _isOwner => widget.currentUserId == widget.ownerLoginId;

  Future<void> _removeMember(Map<String, dynamic> member) async {
    Navigator.pop(context); // Close the bottom sheet
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 추방'),
        content: Text("'${member['nickname']}'님을 정말로 추방하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추방'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}/remove_member'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': member['id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('멤버를 추방했습니다.')));
        widget.onMembersChanged();
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

  Future<void> _changeOwner(Map<String, dynamic> member) async {
    Navigator.pop(context); // Close the bottom sheet
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('방장 위임'),
        content: Text("'${member['nickname']}'님에게 방장을 위임하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('위임'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}/change_owner'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newOwnerId': member['id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('방장을 위임했습니다.')));
        widget.onMembersChanged();
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

  Future<void> _inviteMember(String userIdToInvite) async {
    if (userIdToInvite.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('초대할 사용자의 ID를 입력해주세요.')));
      return;
    }

    Navigator.pop(context); // Close the dialog

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userIdToInvite}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$userIdToInvite'님에게 초대 요청을 보냈습니다.")),
        );
      } else {
        final error = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('초대 실패: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('네트워크 오류: $e')));
    }
  }

  void _showMemberActions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            if (_isOwner && member['_id'] != widget.ownerId)
              ListTile(
                leading: const Icon(Icons.person_remove),
                title: const Text('추방하기'),
                onTap: () => _removeMember(member),
              ),
            if (_isOwner && member['_id'] != widget.ownerId)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('방장 위임하기'),
                onTap: () => _changeOwner(member),
              ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog() {
    _inviteIdController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 초대하기'),
        content: TextField(
          controller: _inviteIdController,
          decoration: const InputDecoration(hintText: "초대할 사용자의 ID 입력"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => _inviteMember(_inviteIdController.text.trim()),
            child: const Text('초대'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF6000), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PEOPLE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6000),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 24),
                  onPressed: _showInviteDialog,
                  tooltip: '멤버 초대',
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: widget.members.length,
              itemBuilder: (context, index) {
                final member = widget.members[index];
                final bool isThisMemberOwner = member['_id'] == widget.ownerId;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFF6000), width: 1),
                  ),
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage(
                                'assets/profile_placeholder.jpg',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    member['nickname'] ?? '이름 없음',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isThisMemberOwner)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_isOwner && !isThisMemberOwner)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showMemberActions(member),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
