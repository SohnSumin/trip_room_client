import 'package:flutter/material.dart';
import 'package:trip_room_client/viewmodels/start_view_model.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final StartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StartViewModel();
    _viewModel.addListener(_onViewModelUpdated);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (!mounted) return;

    // 인증 확인이 끝나면 상태에 따라 화면 전환 또는 UI 업데이트
    if (!_viewModel.isCheckingAuth) {
      if (_viewModel.authenticatedUser != null) {
        // 로그인된 사용자이면 홈으로 이동
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {
            'userId': _viewModel.authenticatedUser!.userId,
            'nickname': _viewModel.authenticatedUser!.nickname,
            'id': _viewModel.authenticatedUser!.id,
          },
        );
      } else {
        // 로그인되지 않은 사용자이면 버튼을 보여주기 위해 UI 갱신
        setState(() {});
      }
    } else {
      // 인증 확인 중이면 로딩 UI를 위해 갱신
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _viewModel.isCheckingAuth
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo_name.png', height: 120),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: Color(0xFFFF6000)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo_name.png', height: 120),
                  const SizedBox(height: 80),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6000),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('로그인', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF6000)),
                      minimumSize: const Size(250, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(fontSize: 16, color: Color(0xFFFF6000)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
