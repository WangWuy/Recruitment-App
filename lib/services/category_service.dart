import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class CategoryService {
  Future<List<dynamic>> list() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/categories');
    final r = await http.get(url);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode == 200) return (data['data'] as List<dynamic>);
    throw Exception(data['message'] ?? 'Lỗi tải danh mục');
  }
}

