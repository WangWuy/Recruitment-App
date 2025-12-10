import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String role = 'candidate',
    String? phone,
  });
  Future<User> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
}
