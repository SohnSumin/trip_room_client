import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StartViewModel with ChangeNotifier {
  bool _isCheckingAuth = true;
  bool get isCheckingAuth => _isCheckingAuth;

  User? _authenticatedUser;
  User? get authenticatedUser => _authenticatedUser;

  StartViewModel() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    // 잠시 딜레이를 주어 로고를 보여줍니다.
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final nickname = prefs.getString('nickname');
    final id = prefs.getString('id');

    if (userId != null && nickname != null && id != null) {
      _authenticatedUser = User(userId: userId, nickname: nickname, id: id);
    } else {
      _authenticatedUser = null;
    }

    _isCheckingAuth = false;
    notifyListeners();
  }
}
