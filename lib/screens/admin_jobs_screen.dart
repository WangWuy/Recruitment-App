import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  String _selectedFilter = 'all'; // all, active, pending, rejected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    final token = context.read<SimpleAuthProvider>().token;
    final provider = context.read<AdminProvider>();
    
    String? status;
    if (_selectedFilter != 'all') status = _selectedFilter;
    
    await provider.loadJobs(token, status: status);
  }

  void _showJobDetail(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Chi tiết tin tuyển dụng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              // Job details
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Tiêu đề', job['title'] ?? 'N/A'),
                      _buildDetailRow('Công ty', job['company_name'] ?? 'N/A'),
                      _buildDetailRow('Địa điểm', job['location'] ?? 'N/A'),
                      _buildDetailRow('Mức lương', _formatSalary(job['salary_min'], job['salary_max'])),
                      _buildDetailRow('Loại hình', _getEmploymentTypeText(job['employment_type'])),
                      _buildDetailRow('Kinh nghiệm', _getExperienceLevelText(job['experience_level'])),
                      _buildDetailRow('Trạng thái', _getStatusText(job['status'])),
                      _buildDetailRow('Ngày tạo', _formatDate(job['created_at'])),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Mô tả công việc',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job['description'] ?? 'Không có mô tả',
                        style: const TextStyle(fontSize: 14),
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Yêu cầu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        job['requirements'] ?? 'Không có yêu cầu',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              if (job['status'] == 'pending' || job['status'] == null || job['status'] == '')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _moderateJob(job, 'approve');
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Phê duyệt', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _moderateJob(job, 'reject');
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Từ chối', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatSalary(dynamic min, dynamic max) {
    if (min == null && max == null) return 'Thương lượng';
    if (min == null) return 'Đến ${_formatMoney(max)}';
    if (max == null) return 'Từ ${_formatMoney(min)}';
    return '${_formatMoney(min)} - ${_formatMoney(max)}';
  }

  String _formatMoney(dynamic amount) {
    if (amount == null) return '0';
    final num = int.tryParse(amount.toString()) ?? 0;
    return '${(num / 1000000).toStringAsFixed(1)}M';
  }

  String _getEmploymentTypeText(String? type) {
    switch (type) {
      case 'full_time': return 'Toàn thời gian';
      case 'part_time': return 'Bán thời gian';
      case 'contract': return 'Hợp đồng';
      case 'internship': return 'Thực tập';
      default: return type ?? 'N/A';
    }
  }

  String _getExperienceLevelText(String? level) {
    switch (level) {
      case 'entry': return 'Mới tốt nghiệp';
      case 'mid': return 'Kinh nghiệm';
      case 'senior': return 'Chuyên gia';
      case 'lead': return 'Trưởng nhóm';
      default: return level ?? 'N/A';
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) return 'Chờ xét duyệt';
    switch (status) {
      case 'pending': return 'Chờ xét duyệt';
      case 'active': return 'Đang hoạt động';
      case 'paused': return 'Tạm dừng';
      case 'closed': return 'Đã đóng';
      case 'draft': return 'Bản nháp';
      case 'rejected': return 'Bị từ chối';
      default: return 'Chờ xét duyệt';
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  Future<void> _moderateJob(Map<String, dynamic> job, String action) async {
    try {
      final token = context.read<SimpleAuthProvider>().token;
      final success = await context.read<AdminProvider>().moderateJob(token, job['id'], action);
      // Optimistic UI: cập nhật ngay khi thành công
      if (success && mounted) {
        final provider = context.read<AdminProvider>();
        final idx = provider.jobs.indexWhere((e) => e['id'] == job['id']);
        if (idx != -1) {
          final updated = Map<String, dynamic>.from(provider.jobs[idx]);
          updated['status'] = action == 'approve' ? 'active' : 'rejected';
          provider.jobs[idx] = updated;
          // Nếu đang ở tab Chờ duyệt thì loại bỏ phần tử vừa duyệt/từ chối
          if (_selectedFilter == 'pending') {
            provider.jobs.removeAt(idx);
          }
        }
        // Yêu cầu rebuild ngay
        setState(() {});
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Thao tác thành công' : 'Thao tác thất bại'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        _loadJobs(); // Đồng bộ lại với server
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showModerateDialog(Map<String, dynamic> job) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm duyệt tin tuyển dụng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check, color: Colors.green),
              title: const Text('Duyệt tin'),
              onTap: () async {
                final token = context.read<SimpleAuthProvider>().token;
                final success = await context.read<AdminProvider>().moderateJob(token, job['id'], 'approve');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Duyệt tin thành công' : 'Duyệt tin thất bại')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Từ chối tin'),
              onTap: () async {
                final token = context.read<SimpleAuthProvider>().token;
                final success = await context.read<AdminProvider>().moderateJob(token, job['id'], 'reject');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Từ chối tin thành công' : 'Từ chối tin thất bại')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa tin tuyển dụng "${job['title']}"?'),
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
      final success = await context.read<AdminProvider>().deleteJob(token, job['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Xóa thành công' : 'Xóa thất bại')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.isEmpty) return Colors.orange; // Xử lý empty string như pending
    switch (status) {
      case 'active': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tin tuyển dụng')),
      body: Column(
        children: [
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tất cả')),
                    ButtonSegment(value: 'active', label: Text('Hoạt động')),
                    ButtonSegment(value: 'pending', label: Text('Chờ duyệt')),
                    ButtonSegment(value: 'rejected', label: Text('Từ chối')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (Set<String> value) {
                    setState(() => _selectedFilter = value.first);
                    _loadJobs();
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          
          // Job list
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_outline, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Chưa có dữ liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilter == 'all' 
                                ? 'Hệ thống chưa có tin tuyển dụng nào'
                                : 'Không có tin tuyển dụng ở trạng thái "${_getStatusText(_selectedFilter)}"',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.jobs.length,
                        itemBuilder: (context, index) {
                          final job = provider.jobs[index];
                          final statusColor = _getStatusColor(job['status'] ?? '');
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(job['title'] ?? 'N/A'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job['company_name'] ?? 'N/A'),
                                  Text('${job['location'] ?? 'N/A'} - ${job['salary'] ?? 'N/A'}'),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStatusText(job['status'] ?? ''),
                                      style: TextStyle(color: statusColor, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Nút xem chi tiết
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    color: Colors.blue,
                                    onPressed: () => _showJobDetail(job),
                                  ),
                                  // Nút xóa
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(job),
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
    );
  }
}

