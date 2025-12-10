import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/admin_provider.dart';
import 'admin_users_screen.dart';
import 'admin_jobs_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Map<String, dynamic>? stats;
  bool loading = false;

  Future<void> load() async {
    setState(() => loading = true);
    final token = context.read<SimpleAuthProvider>().token;
    await context.read<AdminProvider>().loadStats(token);
    setState(() {
      stats = context.read<AdminProvider>().stats;
      loading = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<SimpleAuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : stats == null
                ? const Center(child: Text('Đang tải dữ liệu...'))
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade700, Colors.blue.shade500],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Bảng điều khiển', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                      Text('Quản lý hệ thống', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Stats grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            children: [
                              _StatCard(title: 'Người dùng', value: stats?['users'] ?? 0, icon: Icons.people, color: Colors.blue),
                              _StatCard(title: 'Doanh nghiệp', value: stats?['companies'] ?? 0, icon: Icons.business, color: Colors.green),
                              _StatCard(title: 'Tin tuyển dụng', value: stats?['jobs'] ?? 0, icon: Icons.work, color: Colors.orange),
                              _StatCard(title: 'Ứng tuyển', value: stats?['applications'] ?? 0, icon: Icons.description, color: Colors.purple),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Management menus
                          _ManagementCard(
                            icon: Icons.people,
                            iconColor: Colors.blue,
                            title: 'Quản lý người dùng',
                            subtitle: 'Xem, sửa, xóa ứng viên và nhà tuyển dụng',
                            onTap: () {
                              Navigator.push(context, 
                                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                              ).then((_) => load());
                            },
                          ),
                          const SizedBox(height: 12),
                          _ManagementCard(
                            icon: Icons.work,
                            iconColor: Colors.orange,
                            title: 'Quản lý tin tuyển dụng',
                            subtitle: 'Kiểm duyệt, sửa, xóa tin tuyển dụng',
                            onTap: () {
                              Navigator.push(context, 
                                MaterialPageRoute(builder: (_) => const AdminJobsScreen()),
                              ).then((_) => load());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Object value;
  final IconData icon;
  final Color color;
  
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}


