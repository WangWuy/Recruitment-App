import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AdminService {
  Future<Map<String, dynamic>> getStats(String? token) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> getAllUsers(String? token, {String? role}) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/admin/users${role != null ? '?role=$role' : ''}');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode >= 400) {
      throw Exception('Load users failed: ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(response.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> getUser(String? token, int userId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> updateUser(String? token, int userId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode >= 400) {
      throw Exception('Update user failed: ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(response.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> deleteUser(String? token, int userId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) {
      throw Exception('Delete user failed: ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(response.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> createUser(String? token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode >= 400) {
      throw Exception('Create user failed: ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(response.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> getAllJobs(String? token, {String? status}) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/admin/jobs${status != null ? '?status=$status' : ''}');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> getJob(String? token, int jobId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/jobs/$jobId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> updateJob(String? token, int jobId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/jobs/$jobId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> deleteJob(String? token, int jobId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/jobs/$jobId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> moderateJob(String? token, int jobId, String action) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiBaseUrl}/api/admin/jobs/$jobId/moderate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Moderate failed: ${response.statusCode} ${response.reasonPhrase}\n${utf8.decode(response.bodyBytes)}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

