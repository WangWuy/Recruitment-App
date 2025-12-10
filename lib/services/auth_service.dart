import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'candidate',
    String? phone,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/register');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
        }));
    return _handle(resp);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login');
    final resp = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    return _handle(resp);
  }

  Future<Map<String, dynamic>> me(String token) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/me');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    return _handle(resp);
  }

  Map<String, dynamic> _handle(http.Response r) {
    print('Response status: ${r.statusCode}'); // Debug
    print('Response body: ${r.body}'); // Debug
    
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    print('Parsed data: $data'); // Debug
    
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return data;
    }
    
    final errorMessage = data['message'] ?? 'Lỗi kết nối';
    print('Error: $errorMessage'); // Debug
    throw Exception(errorMessage);
  }
}

