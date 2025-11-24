import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';
import 'update_room_screen.dart';
import '../widgets/invitation_drawer.dart';
import '../widgets/people_card.dart';
import 'trip_schedule_screen.dart';
import '../widgets/checklist_card.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String nickname;
  final String id;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final String baseUrl = "http://127.0.0.1:5000";
  Map<String, dynamic>? roomDetails;
  List<dynamic> members = [];
  bool isLoading = true;

  // 방장 여부를 판단하는 중앙 로직
  bool get _isOwner =>
      roomDetails != null && widget.id == roomDetails!['ownerLoginId'];

  @override
  void initState() {
    super.initState();
    _fetchRoomData();
  }

  Future<void> _fetchRoomData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final detailsResponse = await http.get(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}'),
      );
      final membersResponse = await http.get(
        Uri.parse('$baseUrl/api/rooms/${widget.roomId}/members'),
      );

      if (detailsResponse.statusCode == 200 &&
          membersResponse.statusCode == 200) {
        setState(() {
          roomDetails = jsonDecode(utf8.decode(detailsResponse.bodyBytes));
          members = jsonDecode(utf8.decode(membersResponse.bodyBytes));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load room data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // 에러 처리
    }
  }

  Future<void> _deleteRoom() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('여행방 삭제'),
        content: const Text('정말로 이 여행방을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/api/rooms/${widget.roomId}'),
        );

        if (response.statusCode == 200 && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행방이 삭제되었습니다.')));
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
        } else {
          throw Exception('Failed to delete room');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  String _calculateDuration(String startDateStr, String endDateStr) {
    try {
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);
      final difference = endDate.difference(startDate).inDays;
      if (difference < 0) {
        return '기간 오류';
      }
      return '$difference박 ${difference + 1}일';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: InvitationDrawer(
        userId: widget.userId,
        onInvitationHandled: _fetchRoomData, // 초대 처리 후 상세 정보 새로고침
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              userId: widget.userId,
              nickname: widget.nickname,
              id: widget.id,
              onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
                arguments: {
                  'userId': widget.userId,
                  'nickname': widget.nickname,
                  'id': widget.id,
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : roomDetails == null
                  ? const Center(child: Text('여행방 정보를 불러올 수 없습니다.'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단 이미지 배너
                          if (roomDetails?['imageId'] != null)
                            SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: Image.network(
                                '$baseUrl/api/images/${roomDetails!['imageId']!}',
                                fit: BoxFit.cover,
                              ),
                            ),
                          // 카드 섹션
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoCard(),
                                const SizedBox(height: 20),
                                _buildPeopleCard(),
                                const SizedBox(height: 20),
                                ChecklistCard(roomId: widget.roomId),
                                const SizedBox(height: 40),
                                if (_isOwner)
                                  Center(
                                    child: TextButton(
                                      onPressed: _deleteRoom,
                                      child: const Text(
                                        '여행방 삭제',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard({
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6000),
                  ),
                ),
                // 방장에게만 수정 버튼이 보이도록 수정
                if (onEdit != null && _isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCustomCard(
      title: 'INFO',
      onEdit: () {
        if (roomDetails != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UpdateRoomScreen(
                userId: widget.userId,
                nickname: widget.nickname,
                id: widget.id,
                roomId: widget.roomId,
                roomDetails: roomDetails!,
              ),
            ),
          ).then((result) {
            // 수정 화면에서 true를 반환하면 데이터 새로고침
            if (result == true) {
              _fetchRoomData();
            }
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 영역 (제목, 국가)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomDetails!['title'] ?? '제목 없음',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      '여행 국가',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Text(
                      ' | ',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      roomDetails!['country'] ?? '미정',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 오른쪽 영역 (기간)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${roomDetails!['startDate']} ~ ${roomDetails!['endDate']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                _calculateDuration(
                  roomDetails!['startDate'],
                  roomDetails!['endDate'],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleCard() {
    if (roomDetails == null) {
      return const SizedBox.shrink(); // 데이터가 없으면 빈 위젯 반환
    }
    return PeopleCard(
      roomId: widget.roomId,
      currentUserId: widget.id, // DB _id를 전달하여 ownerId와 비교하도록 수정
      ownerLoginId: roomDetails!['ownerLoginId'],
      ownerId: roomDetails!['ownerId'],
      members: members,
      onMembersChanged: _fetchRoomData,
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined),
              color: Colors.white,
              onPressed: () {
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
            IconButton(
              icon: const Icon(Icons.info), // 현재 화면 아이콘
              color: Colors.white,
              onPressed: () {
                // 현재 화면이므로 동작 없음
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              color: Colors.white,
              onPressed: () {
                if (roomDetails != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TripScheduleScreen(
                        // 필요한 파라미터 추가
                        roomId: widget.roomId,
                        startDate: roomDetails!['startDate'],
                        endDate: roomDetails!['endDate'],
                        userId: widget.userId,
                        nickname: widget.nickname,
                        id: widget.id,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
