import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/simple_auth_provider.dart';
import '../services/employer_service.dart';
import '../widgets/error_dialog.dart';

class ManageCandidatesScreen extends StatefulWidget {
  const ManageCandidatesScreen({super.key});

  @override
  State<ManageCandidatesScreen> createState() => _ManageCandidatesScreenState();
}

class _ManageCandidatesScreenState extends State<ManageCandidatesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _employerService = EmployerService();
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _filteredApplications = [];
  bool _loading = false;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'all',
    'pending',
    'reviewed',
    'shortlisted',
    'interview',
    'rejected',
    'hired',
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Tất cả',
    'pending': 'Chờ xem xét',
    'reviewed': 'Đã xem xét',
    'shortlisted': 'Đã lọt vào vòng sau',
    'interview': 'Phỏng vấn',
    'rejected': 'Từ chối',
    'hired': 'Đã tuyển',
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadApplications();
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

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final applications = await _employerService.getApplications(
          auth.token!,
          status: _selectedFilter == 'all' ? null : _selectedFilter,
        );
        setState(() {
          _applications = applications;
          _filteredApplications = applications;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải danh sách ứng viên: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterApplications() {
    setState(() {
      _filteredApplications = _applications.where((app) {
        final appStatus =
            (app['status'] == null || (app['status'] as String).isEmpty)
                ? 'pending'
                : app['status'];
        final matchesFilter =
            _selectedFilter == 'all' || appStatus == _selectedFilter;
        final matchesSearch = _searchQuery.isEmpty ||
            app['candidate_name']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            app['job_title']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            app['skills'].toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updateApplicationStatus(
      int applicationId, String newStatus) async {
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        await _employerService.updateApplicationStatus(
            auth.token!, applicationId,
            status: newStatus);

        setState(() {
          final index =
              _applications.indexWhere((app) => app['id'] == applicationId);
          if (index != -1) {
            _applications[index]['status'] = newStatus;
            _filterApplications();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể cập nhật trạng thái: $e');
      }
    }
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
            _buildApplicationsList(),
          ],
        ),
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
          'Quản lý ứng viên',
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
                    const Text(
                      'Bộ lọc và tìm kiếm',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    TextField(
                      controller: TextEditingController(text: _searchQuery),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (value) {
                        _filterApplications();
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên, vị trí, kỹ năng...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search,
                              color: AppColors.primary),
                          onPressed: () {
                            _filterApplications();
                            // Đóng bàn phím
                            FocusScope.of(context).unfocus();
                          },
                          tooltip: 'Tìm kiếm',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter chips
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
                                _filterApplications();
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textGray,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
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

  Widget _buildApplicationsList() {
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
                    Row(
                      children: [
                        const Text(
                          'Danh sách ứng viên',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredApplications.length} ứng viên',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredApplications.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Text(
                                    'Không có ứng viên nào',
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
                                itemCount: _filteredApplications.length,
                                itemBuilder: (context, index) {
                                  final application =
                                      _filteredApplications[index];
                                  return _buildApplicationCard(application);
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

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = (application['status'] == null ||
            (application['status'] as String).isEmpty)
        ? 'pending'
        : application['status'];
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
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 25,
                child: Text(
                  (application['candidate_name'] ?? 'N/A')[0].toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['candidate_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      application['job_title'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textGray,
                      ),
                    ),
                    Text(
                      'Kinh nghiệm: ${application['experience'] ?? 'N/A'}',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    _formatDate(application['applied_at']),
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

          // Skills
          if (application['skills'] != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kỹ năng: ${application['skills']}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCandidateDetail(application),
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStatusDialog(application),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Cập nhật'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCandidateDetail(Map<String, dynamic> application) {
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
                    'Chi tiết ứng viên',
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
                      _buildDetailRow(
                          'Họ tên', application['candidate_name'] ?? 'N/A'),
                      _buildDetailRow(
                          'Email', application['candidate_email'] ?? 'N/A'),
                      _buildDetailRow('Số điện thoại',
                          application['candidate_phone'] ?? 'N/A'),
                      _buildDetailRow('Vị trí ứng tuyển',
                          application['job_title'] ?? 'N/A'),
                      _buildDetailRow('Ngày ứng tuyển',
                          _formatDate(application['applied_at'])),
                    ]),

                    const SizedBox(height: 20),

                    // Experience & Skills
                    _buildDetailSection('Kinh nghiệm & Kỹ năng', [
                      _buildDetailRow(
                          'Kinh nghiệm', application['experience'] ?? 'N/A'),
                      _buildDetailRow(
                          'Học vấn', application['education'] ?? 'N/A'),
                      _buildDetailRow(
                          'Kỹ năng', application['skills'] ?? 'N/A'),
                    ]),

                    const SizedBox(height: 20),

                    // Cover letter
                    if (application['cover_letter'] != null) ...[
                      const Text(
                        'Thư xin việc',
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
                          application['cover_letter'],
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

                    // Interview info
                    if (application['interview_date'] != null) ...[
                      _buildDetailSection('Thông tin phỏng vấn', [
                        _buildDetailRow('Ngày phỏng vấn',
                            _formatDate(application['interview_date'])),
                        if (application['interview_notes'] != null)
                          _buildDetailRow(
                              'Ghi chú', application['interview_notes']),
                      ]),
                      const SizedBox(height: 20),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusDialog(application);
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
                              _showContactDialog(application);
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('Liên hệ'),
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

  void _showStatusDialog(Map<String, dynamic> application) {
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
              'Ứng viên: ${application['candidate_name']}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filterOptions.contains(application['status']) &&
                      application['status'] != 'all'
                  ? application['status']
                  : null,
              decoration: const InputDecoration(
                labelText: 'Trạng thái mới',
                border: OutlineInputBorder(),
              ),
              items: _filterOptions.where((s) => s != 'all').map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_filterLabels[status]!),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  _updateApplicationStatus(application['id'], newStatus);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Đã cập nhật trạng thái thành ${_filterLabels[newStatus]}'),
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

  void _showContactDialog(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Liên hệ ứng viên',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ứng viên: ${application['candidate_name']}',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn phương thức liên hệ:',
              style:
                  TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Gửi email'),
              subtitle: Text(application['candidate_email'] ?? 'N/A'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng gửi email sẽ được phát triển'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Gọi điện'),
              subtitle: Text(application['candidate_phone'] ?? 'N/A'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng gọi điện sẽ được phát triển'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'shortlisted':
        return Colors.green;
      case 'interview':
        return Colors.purple;
      case 'rejected':
        return Colors.red;
      case 'hired':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xem xét';
      case 'reviewed':
        return 'Đã xem xét';
      case 'shortlisted':
        return 'Đã lọt vào vòng sau';
      case 'interview':
        return 'Phỏng vấn';
      case 'rejected':
        return 'Từ chối';
      case 'hired':
        return 'Đã tuyển';
      default:
        return 'Không xác định';
    }
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
