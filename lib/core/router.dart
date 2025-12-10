import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/saved_jobs_screen.dart';
import '../screens/application_history_screen.dart';
import '../screens/news_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/employer_dashboard_screen.dart';
import '../screens/post_job_screen.dart';
import '../screens/manage_candidates_screen.dart';
import '../screens/my_jobs_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/employer_analytics_screen.dart';
import '../screens/all_jobs_screen.dart';
import '../screens/employer_profile_edit_screen.dart';
import '../screens/cv_builder_screen.dart';
import '../screens/news_editor_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/ai_chatbot_screen.dart';
import '../models/news_article.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/job_detail':
        final job = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => JobDetailScreen(job: job));
      case '/saved_jobs':
        return MaterialPageRoute(builder: (_) => const SavedJobsScreen());
      case '/application_history':
        return MaterialPageRoute(builder: (_) => const ApplicationHistoryScreen());
      case '/news':
        return MaterialPageRoute(builder: (_) => const NewsScreen());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminPanelScreen());
          case '/employer':
            return MaterialPageRoute(builder: (_) => const EmployerDashboardScreen());
          case '/post_job':
            return MaterialPageRoute(builder: (_) => const PostJobScreen());
          case '/manage_candidates':
            return MaterialPageRoute(builder: (_) => const ManageCandidatesScreen());
          case '/my_jobs':
            return MaterialPageRoute(builder: (_) => const MyJobsScreen());
          case '/employer_analytics':
            return MaterialPageRoute(builder: (_) => const EmployerAnalyticsScreen());
          case '/all_jobs':
            return MaterialPageRoute(builder: (_) => const AllJobsScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/employer_profile_edit':
            return MaterialPageRoute(builder: (_) => const EmployerProfileEditScreen());
          case '/cv_builder':
            return MaterialPageRoute(builder: (_) => const CVBuilderScreen());
          case '/news_editor':
            final article = settings.arguments as NewsArticle?;
            return MaterialPageRoute(builder: (_) => NewsEditorScreen(article: article));
          case '/news_detail':
            final article = settings.arguments as NewsArticle;
            return MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article));
          case '/ai_chatbot':
            return MaterialPageRoute(builder: (_) => const AIChatbotScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('No route defined for ${settings.name}')),
              ),
            );
    }
  }
}

