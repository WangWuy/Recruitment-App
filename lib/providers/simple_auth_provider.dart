import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SimpleAuthProvider extends ChangeNotifier {
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
    print('Starting login for: $email'); // Debug log
    _loading = true; notifyListeners();
    try {
      // Clear old session first
      await clearSession();
      print('Old session cleared'); // Debug log
      
      final res = await _service.login(email, password);
      print('Login response: $res'); // Debug
      _token = res['token'] as String?;
      _user = res['user'] as Map<String, dynamic>?;
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);
      if (_user != null) await prefs.setString('user', jsonEncode(_user));
      print('Login successful: token=$_token, user=$_user'); // Debug
      print('Current user ID: ${_user?['id']}'); // Debug log
    } catch (e) {
      print('Login error: $e'); // Debug
      rethrow;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> register({required String name, required String email, required String password, String role = 'candidate'}) async {
    _loading = true; notifyListeners();
    try {
      final res = await _service.register(name: name, email: email, password: password, role: role);
      print('Register response: $res'); // Debug
      _token = res['token'] as String?;
      _user = res['user'] as Map<String, dynamic>?;
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('token', _token!);
      if (_user != null) await prefs.setString('user', jsonEncode(_user));
      print('Register successful: token=$_token, user=$_user'); // Debug
    } catch (e) {
      print('Register error: $e'); // Debug
      rethrow;
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

  Future<void> clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // Cập nhật thông tin user sau khi save profile
  void updateUserInfo(Map<String, dynamic> newUserInfo) {
    if (_user != null) {
      _user!.addAll(newUserInfo);
      notifyListeners();
      // Lưu vào SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('user', jsonEncode(_user));
      });
    }
  }

  // Set token và user (dùng cho Google Sign In)
  Future<void> setTokenAndUser(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
    notifyListeners();
  }
}
