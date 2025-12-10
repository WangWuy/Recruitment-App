import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'all'; // all, candidate, employer

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    final token = context.read<SimpleAuthProvider>().token;
    final provider = context.read<AdminProvider>();
    
    String? role;
    if (_selectedFilter == 'candidate') role = 'candidate';
    if (_selectedFilter == 'employer') role = 'employer';
    
    await provider.loadUsers(token, role: role);
    final err = context.read<AdminProvider>().lastError;
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải người dùng: $err')));
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    String role = user['role'] ?? 'candidate';
    String status = user['status'] ?? 'active';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sửa người dùng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
                const SizedBox(height: 8),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'candidate', child: Text('Ứng viên')),
                    DropdownMenuItem(value: 'employer', child: Text('Nhà tuyển dụng')),
                  ],
                  onChanged: (value) => setState(() => role = value ?? role),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                  ],
                  onChanged: (value) => setState(() => status = value ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final token = context.read<SimpleAuthProvider>().token;
                final success = await context.read<AdminProvider>().updateUser(token, user['id'], {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'role': role,
                  'status': status,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại')));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng ${user['email']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<SimpleAuthProvider>().token;
      final success = await context.read<AdminProvider>().deleteUser(token, user['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Xóa thành công' : 'Xóa thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: Column(
        children: [
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tất cả')),
                    ButtonSegment(value: 'candidate', label: Text('Ứng viên')),
                    ButtonSegment(value: 'employer', label: Text('Nhà TD')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<String> value) {
                    setState(() => _selectedFilter = value.first);
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          
          // User list
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Chưa có dữ liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all' 
                                ? 'Hệ thống chưa có người dùng nào'
                                : 'Không có ${_selectedFilter == 'candidate' ? 'ứng viên' : 'nhà tuyển dụng'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.users.length,
                        itemBuilder: (context, index) {
                          final user = provider.users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(user['name'] ?? user['email'] ?? 'N/A'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email'] ?? ''),
                                  Text('${user['role'] ?? 'N/A'} - ${user['status'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditDialog(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(user),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Dialog tạo user mới
          final nameController = TextEditingController();
          final emailController = TextEditingController();
          final phoneController = TextEditingController();
          final passwordController = TextEditingController();
          String role = 'candidate';
          String status = 'active';

          final created = await showDialog<bool>(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Thêm người dùng'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ tên')),
                      const SizedBox(height: 8),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 8),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
                      const SizedBox(height: 8),
                      TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mật khẩu')),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Vai trò'),
                        items: const [
                          DropdownMenuItem(value: 'candidate', child: Text('Ứng viên')),
                          DropdownMenuItem(value: 'employer', child: Text('Nhà tuyển dụng')),
                        ],
                        onChanged: (value) => setState(() => role = value ?? role),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Trạng thái'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                          DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                        ],
                        onChanged: (value) => setState(() => status = value ?? status),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                  ElevatedButton(
                    onPressed: () async {
                      final token = context.read<SimpleAuthProvider>().token;
                      final ok = await context.read<AdminProvider>().createUser(token, {
                        'name': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                        'password': passwordController.text,
                        'role': role,
                        'status': status,
                      });
                      if (context.mounted) Navigator.pop(context, ok);
                    },
                    child: const Text('Tạo'),
                  ),
                ],
              ),
            ),
          );

          if (created == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo người dùng thành công')));
            _loadUsers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

