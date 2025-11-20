import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  final String userId; // 로그인 후 전달받는 userId
  final String nickname;
  final String id;
  const HomeScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "http://127.0.0.1:5000"; // Flask 서버 주소
  List rooms = [];
  bool isLoading = true;

  String _sortOption = '최신순';
  final List<String> _sortOptions = ['최신순', '오래된 순', '가나다 순'];

  @override
  void initState() {
    super.initState();
    _fetchUserRooms();
  }

  Future<void> _fetchUserRooms() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/user/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(utf8.decode(response.bodyBytes));
        // 정렬
        data.sort((a, b) {
          if (_sortOption == '최신순') {
            final format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
            final dateA = a['createdAt'] != null
                ? format.parse(a['createdAt'], true)
                : DateTime.now();
            final dateB = b['createdAt'] != null
                ? format.parse(b['createdAt'], true)
                : DateTime.now();
            return dateB.compareTo(dateA);
          } else if (_sortOption == '오래된 순') {
            final format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
            final dateA = a['createdAt'] != null
                ? format.parse(a['createdAt'], true)
                : DateTime.now();
            final dateB = b['createdAt'] != null
                ? format.parse(b['createdAt'], true)
                : DateTime.now();
            return dateA.compareTo(dateB);
          } else if (_sortOption == '가나다 순') {
            return (a['title'] ?? '').compareTo(b['title'] ?? '');
          }
          return 0;
        });

        setState(() {
          rooms = data;
          isLoading = false;
        });
      } else {
        setState(() {
          rooms = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        rooms = [];
        isLoading = false;
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

            // 정렬 옵션
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: Color(0xFFFF6000)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortOption,
                    items: _sortOptions
                        .map(
                          (opt) =>
                              DropdownMenuItem(value: opt, child: Text(opt)),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _sortOption = val!;
                        _fetchUserRooms(); // 정렬 옵션 변경 시 다시 정렬
                      });
                    },
                  ),
                ],
              ),
            ),

            // 방 리스트
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rooms.isEmpty
                  ? const Center(child: Text('참여 중인 여행방이 없습니다.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _buildTravelRoomCard(room);
                      },
                    ),
            ),

            // 하단 네비
            Padding(
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
                      icon: const Icon(Icons.home),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_box),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.person),
                      color: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/account',
                          arguments: {'userId': widget.userId, 'id': widget.id},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelRoomCard(dynamic room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF6000), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
                image: const DecorationImage(
                  image: AssetImage('assets/room_thumbnail.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['title'] ?? '제목 없음',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${room['country'] ?? ''} / ${room['startDate'] ?? ''} ~ ${room['endDate'] ?? ''}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
