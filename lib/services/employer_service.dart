import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class EmployerService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // Get employer's jobs
  Future<List<Map<String, dynamic>>> getMyJobs(String token, {
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/api/employer/jobs').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  // Get applications for employer's jobs
  Future<List<Map<String, dynamic>>> getApplications(String token, {
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/api/employer/applications').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch applications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching applications: $e');
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(String token, int applicationId, {
    required String status,
    String? interviewDate,
    String? interviewLocation,
    String? interviewNotes,
    String? rejectionReason,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/employer/applications/$applicationId');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'interview_date': interviewDate,
          'interview_location': interviewLocation,
          'interview_notes': interviewNotes,
          'rejection_reason': rejectionReason,
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to update application status');
      }
    } catch (e) {
      throw Exception('Error updating application status: $e');
    }
  }

  // Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/employer/dashboard-stats');
      print('Dashboard API URL: $uri'); // Debug log
      print('Token: ${token.substring(0, 20)}...'); // Debug log
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          print('Dashboard data loaded successfully'); // Debug log
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch dashboard stats');
        }
      } else {
        throw Exception('Failed to fetch dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Dashboard API error: $e'); // Debug log
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // Get recent applications
  Future<List<Map<String, dynamic>>> getRecentApplications(String token, {
    int limit = 5,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/api/employer/recent-applications').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch recent applications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recent applications: $e');
    }
  }
}
