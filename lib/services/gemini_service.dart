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
      print('=== GEMINI SERVICE: SEND MESSAGE ===');
      print('Message: $message');
      print('Base URL: $baseUrl');
      print('Chat history length: ${_chatHistory.length}');
      print('User context: ${userContext != null ? "Present" : "None"}');
      print('Job context: ${jobContext != null ? "Present (${jobContext.length} jobs)" : "None"}');

      final url = '$baseUrl/api/gemini/chat';
      print('Full URL: $url');

      final requestBody = {
        'message': message,
        'chatHistory': _chatHistory,
        'userContext': userContext,
        'jobContext': jobContext,
      };
      print('Request body: ${jsonEncode(requestBody)}');

      print('Sending POST request...');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');

        if (data['success'] == true) {
          final aiResponse = data['response'] as String;
          print('AI response length: ${aiResponse.length} characters');
          print('AI response preview: ${aiResponse.substring(0, aiResponse.length > 100 ? 100 : aiResponse.length)}...');

          // Update chat history
          _chatHistory.add({'text': message});
          _chatHistory.add({'text': aiResponse});
          print('Chat history updated. New length: ${_chatHistory.length}');

          return aiResponse;
        } else {
          print('ERROR: success = false in response');
          print('Error message: ${data['message']}');
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        print('ERROR: HTTP ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          print('Error response data: $data');
          throw Exception(data['message'] ?? 'Server error');
        } catch (e) {
          print('Failed to parse error response: $e');
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('ERROR in sendMessage: $e');
      print('Stack trace: $stackTrace');
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
      print('=== GEMINI SERVICE: CHECK CONFIGURATION ===');
      print('Base URL: $baseUrl');
      final testUrl = '$baseUrl/test';
      print('Test URL: $testUrl');

      print('Sending GET request to test endpoint...');
      // Try to ping the backend
      final response = await http.get(
        Uri.parse(testUrl),
      ).timeout(const Duration(seconds: 5));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      final isConfigured = response.statusCode == 200;
      print('Is configured: $isConfigured');

      return isConfigured;
    } catch (e, stackTrace) {
      print('ERROR checking configuration: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
