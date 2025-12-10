import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return dotenv.env['API_BASE_URL_WEB'] ?? 'http://localhost:8888/backend_php_api';
    }
    if (Platform.isAndroid) {
      // Android Emulator maps host machine's localhost to 10.0.2.2
      return dotenv.env['API_BASE_URL_ANDROID'] ?? 'http://10.0.2.2:8888/backend_php_api';
    }
    return dotenv.env['API_BASE_URL_IOS'] ?? 'http://localhost:8888/backend_php_api';
  }

  // Google Client ID (if needed)
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

  // Gemini API Key (if needed)
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}

class AppColors {
  // Modern gradient colors
  static const Color primary = Color(0xFF667eea); // blue
  static const Color secondary = Color(0xFF764ba2); // purple
  static const Color accent = Color(0xFFf093fb); // pink
  static const Color surface = Color(0xFFf8fafc); // light gray
  static const Color background = Color(0xFFf8fafc); // light gray background
  static const Color onSurface = Color(0xFF2d3748); // dark gray
  static const Color textGray = Color(0xFF718096);
  static const Color textPrimary = Color(0xFF2d3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  
  // Additional modern colors
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightPink = Color(0xFFFCE4EC);
  static const Color lightGreen = Color(0xFFE8F5E8);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFff9a9e)],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, secondary, accent],
  );
}