import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApplicationService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // Apply for a job
  Future<Map<String, dynamic>> applyForJob(String token, int jobId, String coverLetter, {String? cvUrl}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'job_id': jobId,
          'cover_letter': coverLetter,
          'cv_url': cvUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final detail = errorData['error'] != null ? ' - ${errorData['error']}' : '';
        throw Exception((errorData['message'] ?? 'Failed to apply for job') + detail);
      }
    } catch (e) {
      throw Exception('Error applying for job: $e');
    }
  }

  // Check applied and get application_id
  Future<Map<String, dynamic>> checkApplied(String token, int jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/check/$jobId'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'has_applied': false};
    } catch (e) {
      return {'has_applied': false};
    }
  }

  // Cancel application
  Future<Map<String, dynamic>> cancelApplication(String token, int applicationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/applications/$applicationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel application');
      }
    } catch (e) {
      throw Exception('Error canceling application: $e');
    }
  }

  // Get user's applications
  Future<List<Map<String, dynamic>>> getUserApplications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      throw Exception('Error loading applications: $e');
    }
  }

  // Check if user has applied for a job
  Future<bool> hasAppliedForJob(String token, int jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/check/$jobId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['has_applied'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get application details
  Future<Map<String, dynamic>?> getApplicationDetails(String token, int applicationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/$applicationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update application status (for employers)
  Future<Map<String, dynamic>> updateApplicationStatus(
    String token, 
    int applicationId, 
    String status, 
    String? feedback
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/applications/$applicationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'feedback': feedback,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update application status');
      }
    } catch (e) {
      throw Exception('Error updating application status: $e');
    }
  }

  // Get applications for a job (for employers)
  Future<List<Map<String, dynamic>>> getJobApplications(String token, int jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/applications/job/$jobId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load job applications');
      }
    } catch (e) {
      throw Exception('Error loading job applications: $e');
    }
  }
}