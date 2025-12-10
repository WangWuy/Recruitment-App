import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getCurrentUser(String token);
  Future<void> saveToken(String token);
  Future<void> saveUser(Map<String, dynamic> user);
  Future<String?> getToken();
  Future<Map<String, dynamic>?> getUser();
  Future<void> clearStorage();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;

  AuthRemoteDataSourceImpl({required this.client, required this.prefs});

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/register');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/me');
    final response = await client.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get user');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    await prefs.setString('token', token);
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    await prefs.setString('user', jsonEncode(user));
  }

  @override
  Future<String?> getToken() async {
    return prefs.getString('token');
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> clearStorage() async {
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
