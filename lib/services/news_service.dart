import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class NewsService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  Future<List<Map<String, dynamic>>> getNews({
    String? category,
    String? keyword,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null && category.isNotEmpty && category != 'Tất cả') {
        queryParams['category'] = category;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final uri = Uri.parse('$_baseUrl/api/news').replace(queryParameters: queryParams);
      print('GET News URI: $uri');
      final response = await http.get(uri);

      print('News status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        print('News response body: ${response.body}');
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<Map<String, dynamic>?> getNewsById(int newsId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/$newsId');
      print('GET News by ID URI: $uri');
      final response = await http.get(uri);

      print('News by ID status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('News by ID response body: ${response.body}');
        throw Exception('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/categories');
      print('GET News categories URI: $uri');
      final response = await http.get(uri);

      print('News categories status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data'] ?? []);
      } else {
        print('News categories response body: ${response.body}');
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}
