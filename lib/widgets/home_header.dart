import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeHeader extends StatefulWidget {
  final String userId;
  final String nickname;
  final VoidCallback? onLogoTap;
  final String id;

  const HomeHeader({
    super.key,
    required this.userId,
    required this.nickname,
    required this.id,
    this.onLogoTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final String baseUrl = "http://127.0.0.1:5000";
  bool _hasInvitations = false;

  // 메뉴 선택 시 처리 로직
  void _onMenuSelected(String value, BuildContext context) async {
    if (value == 'logout') {
      // 로그아웃 처리
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // 저장된 모든 데이터 삭제 (로그인 정보 등)

      // 로그인 화면으로 이동하고, 이전 화면 기록을 모두 제거
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/start', (route) => false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInvitations();
  }

  Future<void> _checkInvitations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/invited/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> invitedRooms = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        if (mounted) {
          setState(() {
            _hasInvitations = invitedRooms.isNotEmpty;
          });
        }
      }
    } catch (e) {
      // 네트워크 오류 등 예외 처리
      // 여기서는 뱃지를 표시하지 않는 것으로 조용히 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFFF6000), width: 1)),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (value) => _onMenuSelected(value, context),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'logout', child: Text('로그아웃')),
            ],
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundImage: AssetImage(
                    'assets/profile_placeholder.jpg',
                  ), //일단은 jpg로 고정
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nickname,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onLogoTap,
            child: Image.asset(
              'assets/logo_name.png',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFFFF6000),
                ),
                onPressed: () {
                  _checkInvitations(); // 드로어를 열 때마다 초대 목록을 다시 확인
                  Scaffold.of(context).openEndDrawer();
                },
              ),
              if (_hasInvitations)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
