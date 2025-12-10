import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final service = NotificationService();
  List<dynamic> items = [];
  bool loading = false;

  Future<void> load() async {
    loading = true; setState((){});
    try {
      final token = context.read<SimpleAuthProvider>().token!;
      items = await service.mine(token);
    } finally { loading = false; setState((){}); }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final n = items[i] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(n['title'] ?? ''),
                    subtitle: Text((n['message'] ?? '').toString()),
                  ),
                );
              },
            ),
    );
  }
}

