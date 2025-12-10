import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class JobService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  Future<List<Map<String, dynamic>>> fetchJobs({
    String? keyword,
    int? categoryId,
    int? minSalary,
    int? maxSalary,
    String? location,
    String? employmentType,
    String? experienceLevel,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (minSalary != null) queryParams['salary_min'] = minSalary.toString();
      if (maxSalary != null) queryParams['salary_max'] = maxSalary.toString();
      if (location != null && location.isNotEmpty) queryParams['location'] = location;
      if (employmentType != null && employmentType.isNotEmpty) queryParams['employment_type'] = employmentType;
      if (experienceLevel != null && experienceLevel.isNotEmpty) queryParams['experience_level'] = experienceLevel;

      final uri = Uri.parse('$_baseUrl/api/jobs').replace(queryParameters: queryParams);
      print('GET Jobs URI: $uri');
      final response = await http.get(uri);

      print('Jobs status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        print('Jobs response body: ${response.body}');
        throw Exception('Failed to fetch jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  Future<Map<String, dynamic>?> getJobById(int jobId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/$jobId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch job: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching job: $e');
    }
  }

  Future<void> applyForJob(String token, {
    required int jobId,
    String? coverLetter,
    int? expectedSalary,
    String? availableFrom,
    String? cvUrl,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/apply');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'job_id': jobId,
          'cover_letter': coverLetter,
          'expected_salary': expectedSalary,
          'available_from': availableFrom,
          'cv_url': cvUrl,
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to apply for job');
      }
    } catch (e) {
      throw Exception('Error applying for job: $e');
    }
  }

  Future<Map<String, dynamic>> toggleSaveJob(String token, int jobId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/save');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'job_id': jobId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to save job');
      }
    } catch (e) {
      throw Exception('Error saving job: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedJobs(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/saved');
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
        throw Exception('Failed to fetch saved jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching saved jobs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getApplications(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/applications');
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

  Future<int> createJob(String token, Map<String, dynamic> jobData) async {
    try {
      print('📤 POST to $_baseUrl/api/jobs');
      print('📦 Body: ${jsonEncode(jobData)}');
      
      // Add trailing slash to prevent 301 redirect
      final uri = Uri.parse('$_baseUrl/api/jobs/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(jobData),
      );

      print('📥 Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.body.startsWith('<!DOCTYPE')) {
        print('❌ ERROR: Server returned HTML instead of JSON!');
        print('Full response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        throw Exception('Server returned HTML. Check backend error logs.');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final id = data['id'] ?? data['data']?['id'] ?? 0;
        return int.tryParse(id.toString()) ?? 0;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to create job');
      }
    } catch (e) {
      print('💥 Exception: $e');
      throw Exception('Error creating job: $e');
    }
  }

  // Update job status
  Future<void> updateJobStatus(String token, int jobId, String status) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/jobs/$jobId/status');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to update job status');
      }
    } catch (e) {
      throw Exception('Error updating job status: $e');
    }
  }
}