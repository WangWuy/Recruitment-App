import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../core/constants.dart';
import '../models/news_article.dart';

class ApiService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // ==================== NEWS ARTICLE ENDPOINTS ====================

  /// Get all news articles with optional filters
  static Future<List<NewsArticle>> getNewsArticles({
    String? category,
    String? keyword,
    bool? isFeatured,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (isFeatured != null) {
        queryParams['is_featured'] = isFeatured ? '1' : '0';
      }

      final uri = Uri.parse('$_baseUrl/api/news').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newsData = data['data'] ?? [];
        return newsData.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch news articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news articles: $e');
    }
  }

  /// Get a single news article by ID
  static Future<NewsArticle> getNewsArticle(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsArticle.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('News article not found');
      } else {
        throw Exception('Failed to fetch news article: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news article: $e');
    }
  }

  /// Create a new news article (admin only)
  static Future<NewsArticle> createNewsArticle(
    Map<String, dynamic> articleData,
    String token,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(articleData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsArticle.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create news article');
      }
    } catch (e) {
      throw Exception('Error creating news article: $e');
    }
  }

  /// Update an existing news article (admin/author only)
  static Future<NewsArticle> updateNewsArticle(
    int id,
    Map<String, dynamic> articleData,
    String token,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/$id');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(articleData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NewsArticle.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update news article');
      }
    } catch (e) {
      throw Exception('Error updating news article: $e');
    }
  }

  /// Delete a news article (admin/author only)
  static Future<void> deleteNewsArticle(int id, String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete news article');
      }
    } catch (e) {
      throw Exception('Error deleting news article: $e');
    }
  }

  /// Increment view count for a news article
  static Future<void> incrementNewsViews(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/news/$id/view');
      final response = await http.post(uri);

      if (response.statusCode != 200 && response.statusCode != 204) {
        // Don't throw error for view count failure
        print('Failed to increment view count: ${response.statusCode}');
      }
    } catch (e) {
      // Don't throw error for view count failure
      print('Error incrementing view count: $e');
    }
  }

  // ==================== IMAGE UPLOAD ENDPOINTS ====================

  /// Upload an image file and return the URL
  static Future<String> uploadImage(File imageFile, String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/upload/image');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Get mime type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'] ?? data['data']['url'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload multiple images
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String token,
  ) async {
    try {
      final uploadedUrls = <String>[];

      for (final file in imageFiles) {
        final url = await uploadImage(file, token);
        uploadedUrls.add(url);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Error uploading multiple images: $e');
    }
  }

  // ==================== GENERAL HELPERS ====================

  /// Check if user has permission to edit/delete article
  static bool canEditArticle(NewsArticle article, Map<String, dynamic>? user) {
    if (user == null) return false;

    final role = user['role'];
    final userId = user['id'];

    // Admin can edit any article
    if (role == 'admin') return true;

    // Author can edit their own article
    if (userId == article.authorId) return true;

    return false;
  }
}
