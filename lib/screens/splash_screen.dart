import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Delay để hiển thị splash screen
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Restore session từ SharedPreferences
      final authProvider = context.read<SimpleAuthProvider>();
      await authProvider.restoreSession();

      print('🔐 Session restored');
      print('🔐 Token: ${authProvider.token == null ? "NULL" : "EXISTS"}');
      print('🔐 Is logged in: ${authProvider.isLoggedIn}');

      if (!mounted) return;

      // Nếu đã đăng nhập, chuyển đến home, nếu không thì login
      if (authProvider.isLoggedIn) {
        final user = authProvider.user;
        final role = user?['role'] ?? 'candidate';

        print('🔐 User role: $role');

        // Navigate based on role
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'employer') {
          Navigator.pushReplacementNamed(context, '/employer');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('🔐 No session found, going to login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ Error initializing app: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

