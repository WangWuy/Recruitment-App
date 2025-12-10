import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../core/di/service_locator.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase = sl<LoginUseCase>();
  final RegisterUseCase _registerUseCase = sl<RegisterUseCase>();
  
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _loginUseCase(email, password);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = 'candidate',
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      _user = await _registerUseCase(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    _clearError();
    notifyListeners();
  }

  Future<void> restoreSession() async {
    // This method will be implemented to restore user session from storage
    // For now, we'll leave it empty as the old implementation
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
