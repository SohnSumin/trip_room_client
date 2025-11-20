import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHeader extends StatelessWidget {
  final String userId;
  final String nickname;
  final VoidCallback? onLogoTap;

  const HomeHeader({
    super.key,
    required this.userId,
    required this.nickname,
    this.onLogoTap,
  });

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
                  radius: 20,
                  backgroundImage: AssetImage(
                    'assets/profile_placeholder.jpg',
                  ), //일단은 jpg로 고정
                ),
                const SizedBox(height: 4),
                Text(
                  nickname,
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onLogoTap,
            child: Image.asset(
              'assets/logo_name.png',
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFFFF6000),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
