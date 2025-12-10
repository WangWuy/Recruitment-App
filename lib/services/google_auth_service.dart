import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class GoogleAuthService {
  static final String _baseUrl = AppConstants.apiBaseUrl;

  // Initialize Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle({String role = 'candidate'}) async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign In was cancelled');
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Prepare data for backend
      final requestData = {
        'google_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? '',
        'photo_url': googleUser.photoUrl,
        'role': role, // candidate or employer
      };

      // Send to backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'token': data['token'],
          'user': data['user'],
          'message': data['message'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Google Sign In failed');
      }
    } catch (e) {
      // Make sure to sign out from Google if backend fails
      await _googleSignIn.signOut();
      throw Exception('Error signing in with Google: $e');
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Error signing out from Google: $e');
    }
  }

  // Check if currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}
