import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class NotificationService {
  Future<List<dynamic>> mine(String token) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/notifications');
    final r = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode == 200) return (data['data'] as List<dynamic>);
    throw Exception(data['message'] ?? 'Lỗi tải thông báo');
  }
}

