import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool showLoginForm = false;
  bool showRegisterForm = false;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  final String baseUrl = "http://127.0.0.1:5000"; // Flask 서버 주소

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/main_background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
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
                  if (showLoginForm)
                    _buildLoginForm()
                  else if (showRegisterForm)
                    _buildRegisterForm()
                  else
                    _buildStartButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButtons() {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              showRegisterForm = true;

              idController.clear();
              passwordController.clear();
              nameController.clear();
            });
          },
          style: _buttonStyle(),
          child: const Text(
            "시작하기",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showLoginForm = true;

              idController.clear();
              passwordController.clear();
              nameController.clear();
            });
          },
          child: const Text(
            "이미 계정이 있으신가요? 로그인",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        SizedBox(
          width: 250,
          child: TextField(
            controller: idController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "ID",
              hintStyle: TextStyle(color: Colors.white70),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
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
          onPressed: _login,
          style: _buttonStyle(),
          child: const Text(
            "로그인",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showLoginForm = false;
            });
          },
          child: const Text("뒤로", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        const Text(
          "당신은 누구신가요?",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 250,
          child: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "이름",
              hintStyle: TextStyle(color: Colors.white70),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 250,
          child: TextField(
            controller: idController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "ID",
              hintStyle: TextStyle(color: Colors.white70),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
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
          onPressed: _signup,
          style: _buttonStyle(),
          child: const Text(
            "가입완료",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              showRegisterForm = false;
            });
          },
          child: const Text("뒤로", style: TextStyle(color: Colors.white)),
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

  Future<void> _login() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': idController.text.trim(),
        'password': passwordController.text.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // 로그인 성공 → 홈 화면 이동
      Navigator.pushReplacementNamed(context, '/home', arguments: data);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['error'] ?? '로그인 실패')));
    }
  }

  Future<void> _signup() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': idController.text.trim(),
        'password': passwordController.text.trim(),
        'nickname': nameController.text.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원가입 완료! 로그인 해주세요.')));
      setState(() {
        showRegisterForm = false;
        showLoginForm = true;

        idController.clear();
        passwordController.clear();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['error'] ?? '회원가입 실패')));
    }
  }
}
