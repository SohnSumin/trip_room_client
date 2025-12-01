import 'package:flutter/material.dart';
import 'package:trip_room_client/viewmodels/home_header_view_model.dart';

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
  late final HomeHeaderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeHeaderViewModel(userId: widget.userId);
    _viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  // 메뉴 선택 처리
  void _onMenuSelected(String value, BuildContext context) async {
    if (value == 'logout') {
      await _viewModel.logout();

      // 시작 화면으로 이동하고 이전 화면 기록을 모두 제거
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
                  radius: 14,
                  backgroundImage: AssetImage('assets/profile_placeholder.jpg'),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.nickname,
                  style: const TextStyle(fontSize: 11, color: Colors.black),
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
                  _viewModel.checkInvitations(); // 알림 아이콘 클릭 시 초대 목록을 다시 확인
                  Scaffold.of(context).openEndDrawer();
                },
              ),
              if (_viewModel.hasInvitations)
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
