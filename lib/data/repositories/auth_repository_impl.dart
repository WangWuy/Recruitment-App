import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> login(String email, String password) async {
    final response = await _remoteDataSource.login(email, password);
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _remoteDataSource.saveToken(response['token'] as String);
    await _remoteDataSource.saveUser(response['user'] as Map<String, dynamic>);
    return user.toEntity();
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String role = 'candidate',
    String? phone,
  }) async {
    final data = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
    };
    
    final response = await _remoteDataSource.register(data);
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    await _remoteDataSource.saveToken(response['token'] as String);
    await _remoteDataSource.saveUser(response['user'] as Map<String, dynamic>);
    return user.toEntity();
  }

  @override
  Future<User> getCurrentUser() async {
    final token = await _remoteDataSource.getToken();
    if (token == null) {
      throw Exception('No token found');
    }
    
    final response = await _remoteDataSource.getCurrentUser(token);
    return UserModel.fromJson(response['user'] as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.clearStorage();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _remoteDataSource.getToken();
    return token != null;
  }
}
