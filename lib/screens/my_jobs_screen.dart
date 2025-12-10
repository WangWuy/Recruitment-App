import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/employer_service.dart';
import '../widgets/error_dialog.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _employerService = EmployerService();
  List<Map<String, dynamic>> _myJobs = [];
  bool _loading = false;
  String _selectedFilter = 'all';

  final List<String> _filterOptions = ['all', 'pending', 'active', 'paused', 'closed', 'draft', 'rejected'];
  final Map<String, String> _filterLabels = {
    'all': 'Tất cả',
    'pending': 'Chờ xét duyệt',
    'active': 'Đang hoạt động',
    'paused': 'Tạm dừng',
    'closed': 'Đã đóng',
    'draft': 'Bản nháp',
    'rejected': 'Bị từ chối',
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMyJobs();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadMyJobs() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final jobs = await _employerService.getMyJobs(
          auth.token!,
          status: _selectedFilter == 'all' ? null : _selectedFilter,
        );
        setState(() {
          _myJobs = jobs;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải danh sách việc làm: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateJobStatus(int jobId, String newStatus) async {
    try {
      print('Updating job status: jobId=$jobId, newStatus=$newStatus'); // Debug log
      final auth = context.read<SimpleAuthProvider>();
      final jobProvider = context.read<JobProvider>();
      
      if (auth.token != null) {
        // Call API to update status
        await jobProvider.updateJobStatus(auth.token!, jobId, newStatus);
        print('Job status updated successfully'); // Debug log
        
        // Update local state
        setState(() {
          final index = _myJobs.indexWhere((job) => job['id'] == jobId);
          if (index != -1) {
            _myJobs[index]['status'] = newStatus;
            print('Local state updated: ${_myJobs[index]}'); // Debug log
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật trạng thái thành ${_filterLabels[newStatus]}'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating job status: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredJobs {
    if (_selectedFilter == 'all') return _myJobs;
    return _myJobs.where((job) => job['status'] == _selectedFilter).toList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildFilters(),
            _buildJobsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/post_job'),
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Việc làm của tôi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Bộ lọc',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredJobs.length} việc làm',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(_filterLabels[filter]!),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textGray,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobsList() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh sách việc làm',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredJobs.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text(
                                    'Không có việc làm nào',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredJobs.length,
                                itemBuilder: (context, index) {
                                  final job = _filteredJobs[index];
                                  return _buildJobCard(job);
                                },
                              ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'draft';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      job['company_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                    ),
                    Text(
                      '${job['location'] ?? 'N/A'} • ${_formatSalary(job['salary_min'], job['salary_max'])}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đăng ${_formatDate(job['created_at'])}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Stats
          Row(
            children: [
              _buildStatItem(Icons.people, '${job['applications_count'] ?? 0} ứng tuyển'),
              const SizedBox(width: 16),
              _buildStatItem(Icons.visibility, '${job['views_count'] ?? 0} lượt xem'),
              const Spacer(),
              Text(
                '${job['employment_type'] ?? 'N/A'} • ${job['experience_level'] ?? 'N/A'}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showJobDetail(job),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Xem chi tiết'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Luôn hiển thị nút Cập nhật, nhưng làm mờ và vô hiệu hóa cho job pending
              Expanded(
                child: Builder(
                  builder: (context) {
                    final isPending = job['status'] == 'pending' || job['status'] == null || job['status'] == '' || job['status'] == 'rejected';
                    print('Job ${job['id']} status: ${job['status']}, isPending: $isPending'); // Debug log
                    
                    return OutlinedButton.icon(
                      onPressed: isPending 
                          ? null // Vô hiệu hóa nút cho job pending
                          : () => _showStatusDialog(job),
                      icon: Icon(
                        Icons.edit, 
                        size: 16,
                        color: isPending ? Colors.grey : AppColors.secondary,
                      ),
                      label: Text(
                        'Cập nhật',
                        style: TextStyle(
                          color: isPending ? Colors.grey : AppColors.secondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPending
                            ? Colors.grey // Màu xám cho job pending
                            : AppColors.secondary,
                        side: BorderSide(
                          color: isPending
                              ? Colors.grey // Viền xám cho job pending
                              : AppColors.secondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  void _showJobDetail(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Chi tiết việc làm',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic info
                    _buildDetailSection('Thông tin cơ bản', [
                      _buildDetailRow('Tiêu đề', job['title'] ?? 'N/A'),
                      _buildDetailRow('Công ty', job['company_name'] ?? 'N/A'),
                      _buildDetailRow('Địa điểm', job['location'] ?? 'N/A'),
                      _buildDetailRow('Mức lương', _formatSalary(job['salary_min'], job['salary_max'])),
                      _buildDetailRow('Loại hình', job['employment_type'] ?? 'N/A'),
                      _buildDetailRow('Kinh nghiệm', job['experience_level'] ?? 'N/A'),
                      _buildDetailRow('Trạng thái', _getStatusText(job['status'])),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Stats
                    _buildDetailSection('Thống kê', [
                      _buildDetailRow('Số ứng tuyển', '${job['applications_count'] ?? 0}'),
                      _buildDetailRow('Lượt xem', '${job['views_count'] ?? 0}'),
                      _buildDetailRow('Ngày đăng', _formatDate(job['created_at'])),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    if (job['description'] != null) ...[
                      const Text(
                        'Mô tả công việc',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job['description'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Requirements
                    if (job['requirements'] != null) ...[
                      const Text(
                        'Yêu cầu',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job['requirements'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusDialog(job);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Cập nhật trạng thái'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/manage_candidates');
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('Xem ứng viên'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> job) {
    // Kiểm tra nếu job đang pending hoặc rejected thì không cho phép cập nhật
    if (job['status'] == 'pending' || job['status'] == null || job['status'] == '' || job['status'] == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái cho việc làm đang chờ xét duyệt hoặc bị từ chối'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    print('Showing status dialog for job: ${job['id']}'); // Debug log
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cập nhật trạng thái',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Việc làm: ${job['title']}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: (job['status'] == 'all' || job['status'] == null || job['status'] == '') ? null : job['status'],
              decoration: const InputDecoration(
                labelText: 'Trạng thái mới',
                border: OutlineInputBorder(),
              ),
              items: _filterOptions.where((status) => status != 'all').map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_filterLabels[status] ?? status),
                );
              }).toList(),
              onChanged: (newStatus) async {
                if (newStatus != null) {
                  print('Dialog onChanged: newStatus=$newStatus'); // Debug log
                  await _updateJobStatus(job['id'], newStatus);
                  print('Dialog: About to pop with true'); // Debug log
                  Navigator.pop(context, true); // Trả về true để báo có thay đổi
                  print('Dialog: Popped successfully'); // Debug log
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật trạng thái thành ${_filterLabels[newStatus]}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) {
      return Colors.amber; // Mặc định là pending nếu null hoặc empty
    }
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.amber; // Mặc định là pending thay vì grey
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) {
      return 'Chờ xét duyệt'; // Mặc định là pending nếu null hoặc empty
    }
    switch (status) {
      case 'pending':
        return 'Chờ xét duyệt';
      case 'active':
        return 'Đang hoạt động';
      case 'paused':
        return 'Tạm dừng';
      case 'closed':
        return 'Đã đóng';
      case 'draft':
        return 'Bản nháp';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Chờ xét duyệt'; // Mặc định là pending thay vì "Không xác định"
    }
  }

  String _formatSalary(int? min, int? max) {
    if (min == null && max == null) return 'Thương lượng';
    if (min == null) return 'Đến ${_formatMoney(max!)}';
    if (max == null) return 'Từ ${_formatMoney(min)}';
    return '${_formatMoney(min)} - ${_formatMoney(max)}';
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}M VNĐ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K VNĐ';
    }
    return '${amount.toString()} VNĐ';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không xác định';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Không xác định';
    }
  }
}
