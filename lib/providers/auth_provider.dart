import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (userStr != null) _user = jsonDecode(userStr) as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      final res = await _service.login(email, password);
      _token = res['token'] as String?;
      _user = res['user'] as Map<String, dynamic>?;
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);
      if (_user != null) await prefs.setString('user', jsonEncode(_user));
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> register({required String name, required String email, required String password, String role = 'candidate'}) async {
    _loading = true; notifyListeners();
    try {
      final res = await _service.register(name: name, email: email, password: password, role: role);
      _token = res['token'] as String?;
      _user = res['user'] as Map<String, dynamic>?;
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);
      if (_user != null) await prefs.setString('user', jsonEncode(_user));
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null; _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}

