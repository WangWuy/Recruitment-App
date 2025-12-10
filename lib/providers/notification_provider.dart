import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import 'simple_auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();
  List<dynamic> notifications = [];
  bool loading = false;

  int get unreadCount => notifications.where((e) => (e as Map<String, dynamic>)['is_read'] == 0).length;

  Future<void> load(BuildContext context) async {
    final auth = context.read<SimpleAuthProvider>();
    final token = auth.token;
    if (token == null) return;
    loading = true; notifyListeners();
    try {
      notifications = await _service.mine(token);
    } finally {
      loading = false; notifyListeners();
    }
  }
}

