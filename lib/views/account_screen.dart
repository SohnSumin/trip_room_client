import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class AccountScreen extends StatefulWidget {
  final String userId;
  final String id;
  const AccountScreen({super.key, required this.userId, required this.id});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool showDeleteForm = false;

  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/main_background.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo_name.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  if (showDeleteForm)
                    _buildDeleteForm()
                  else
                    _buildAccountButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButtons() {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {},
          style: _buttonStyle(),
          child: const Text(
            '내 정보 수정',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        const SizedBox(height: 5),
        OutlinedButton(
          onPressed: () {
            setState(() {
              showDeleteForm = true;

              passwordController.clear();
            });
          },
          style: _buttonStyle(),
          child: const Text(
            '계정 탈퇴',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteForm() {
    return Column(
      children: [
        const Text(
          '탈퇴하시려면 비밀번호를 입력해주세요.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 250,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "비밀번호",
              hintStyle: TextStyle(color: Colors.white70),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _delete,
          style: _buttonStyle(),
          child: const Text(
            "탈퇴하기",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(250, 80),
      side: const BorderSide(color: Colors.white, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _delete() async {
    final response = await http.post(
      Uri.parse('$kBaseUrl/api/auth/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': widget.id,
        'password': passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/start', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계정 탈퇴 실패: ${response.body}')));
    }
  }
}
