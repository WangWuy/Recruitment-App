import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../core/constants.dart';

class EmployerProfileService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // Get employer/company profile
  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      print('🔍 Fetching employer profile from: $_baseUrl/api/employer/profile');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/employer/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else if (response.statusCode == 404) {
        // Profile doesn't exist yet, return empty profile
        print('ℹ️ Profile not found, returning empty profile');
        return {};
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      print('❌ Error loading employer profile: $e');
      // Return empty profile instead of throwing
      // This allows the user to create a profile even if loading fails
      return {};
    }
  }

  // Update employer/company profile
  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/employer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Upload company logo
  Future<Map<String, dynamic>> uploadLogo(String token, String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/employer/upload-logo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get file
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // Get mime type
      final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
      final mimeTypeSplit = mimeType.split('/');

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to upload logo');
      }
    } catch (e) {
      throw Exception('Error uploading logo: $e');
    }
  }

  // Upload logo from bytes (for web or picked image)
  Future<Map<String, dynamic>> uploadLogoFromBytes(
    String token,
    List<int> bytes,
    String filename,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/employer/upload-logo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Get mime type from filename
      final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
      final mimeTypeSplit = mimeType.split('/');

      // Add file to request
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to upload logo');
      }
    } catch (e) {
      throw Exception('Error uploading logo: $e');
    }
  }
}
