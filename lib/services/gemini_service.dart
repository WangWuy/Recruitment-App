import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/constants.dart';

/// Service to interact with Gemini AI through backend API
/// This approach is more secure as the API key is stored on the server
class GeminiService {
  static final String baseUrl = AppConstants.apiBaseUrl;
  
  final List<Map<String, String>> _chatHistory = [];

  /// Send a message and get AI response
  Future<String> sendMessage(
    String message, {
    Map<String, dynamic>? userContext,
    List<Map<String, dynamic>>? jobContext,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gemini/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'chatHistory': _chatHistory,
          'userContext': userContext,
          'jobContext': jobContext,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final aiResponse = data['response'] as String;
          
          // Update chat history
          _chatHistory.add({'text': message});
          _chatHistory.add({'text': aiResponse});
          
          return aiResponse;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Server error');
      }
    } catch (e) {
      throw Exception('Lỗi khi gọi AI: ${e.toString()}');
    }
  }

  /// Generate job recommendations based on user profile
  Future<String> getJobRecommendations(
    Map<String, dynamic> userProfile,
    List<Map<String, dynamic>> jobs,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gemini/job-recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userProfile': userProfile,
          'jobs': jobs,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'] as String;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Server error');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy gợi ý công việc: ${e.toString()}');
    }
  }

  /// Generate CV improvement suggestions
  Future<String> getCVSuggestions(Map<String, dynamic> cvData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gemini/cv-suggestions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cvData': cvData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'] as String;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Server error');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy gợi ý CV: ${e.toString()}');
    }
  }

  /// Generate interview preparation tips for a specific job
  Future<String> getInterviewPrep(Map<String, dynamic> job) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gemini/interview-prep'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job': job,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'] as String;
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Server error');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy gợi ý phỏng vấn: ${e.toString()}');
    }
  }

  /// Reset chat history
  void resetChat() {
    _chatHistory.clear();
  }

  /// Check if backend is configured
  static Future<bool> isConfigured() async {
    try {
      // Try to ping the backend
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
