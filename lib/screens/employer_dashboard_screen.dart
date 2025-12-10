import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/employer_service.dart';
import '../widgets/error_dialog.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  State<EmployerDashboardScreen> createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _employerService = EmployerService();
  List<Map<String, dynamic>> _myJobs = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
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

  Future<void> _loadDashboardData() async {
    print('Loading dashboard data...'); // Debug log
    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      print('Dashboard loading for user ID: ${auth.user?['id']}'); // Debug log
      print('Dashboard loading for user email: ${auth.user?['email']}'); // Debug log
      if (auth.token != null) {
        // Load employer's jobs and applications
        await _loadMyJobs();
        await _loadApplications();
        await _loadStats();
        print('Dashboard data loaded successfully'); // Debug log
      }
    } catch (e) {
      print('Error loading dashboard data: $e'); // Debug log
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải dữ liệu dashboard: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMyJobs() async {
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final jobs = await _employerService.getMyJobs(auth.token!);
        setState(() {
          _myJobs = jobs;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải việc làm: $e');
      }
    }
  }

  Future<void> _loadApplications() async {
    print('Loading applications data...'); // Debug log
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final applications = await _employerService.getRecentApplications(auth.token!);
        print('Applications loaded successfully: ${applications.length} applications'); // Debug log
        setState(() {
          _applications = applications;
        });
      }
    } catch (e) {
      print('Error loading applications: $e'); // Debug log
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải ứng tuyển: $e');
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final stats = await _employerService.getDashboardStats(auth.token!);
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải thống kê: $e');
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
            _buildStatsSection(),
            _buildQuickActions(),
            _buildRecentApplications(),
            _buildMyJobs(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          print('Navigating to PostJobScreen from FAB...'); // Debug log
          await Navigator.pushNamed(context, '/post_job');
          print('Returned from PostJobScreen - Auto reloading dashboard...'); // Debug log
          // Luôn load lại dashboard khi quay lại từ Đăng tin tuyển dụng
          _loadDashboardData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Đăng tin tuyển dụng'),
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
      automaticallyImplyLeading: false, // Loại bỏ nút back
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/employer_profile_edit');
          },
          icon: const Icon(Icons.edit, color: Colors.white),
          tooltip: 'Chỉnh sửa thông tin công ty',
        ),
        IconButton(
          onPressed: () async {
            await context.read<SimpleAuthProvider>().logout();
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          },
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Đăng xuất',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Dashboard Nhà Tuyển Dụng',
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
    );
  }

  Widget _buildStatsSection() {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thống kê tổng quan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Tổng việc làm',
                          _stats['jobs']?['total_jobs']?.toString() ?? '0',
                          Icons.work_outline,
                          AppColors.primary,
                        ),
                        _buildStatCard(
                          'Đang hoạt động',
                          _stats['jobs']?['active_jobs']?.toString() ?? '0',
                          Icons.trending_up,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Ứng tuyển',
                          _stats['applications']?['total_applications']?.toString() ?? '0',
                          Icons.people_outline,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Chờ xem xét',
                          _stats['applications']?['pending_applications']?.toString() ?? '0',
                          Icons.schedule,
                          Colors.blue,
                        ),
                      ],
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 0),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 7,
              color: color.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Đăng tin mới',
                            Icons.add_circle_outline,
                            () async {
                              print('Navigating to PostJobScreen...'); // Debug log
                              await Navigator.pushNamed(context, '/post_job');
                              print('Returned from PostJobScreen - Auto reloading dashboard...'); // Debug log
                              // Luôn load lại dashboard khi quay lại từ Đăng tin tuyển dụng
                              _loadDashboardData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Quản lý ứng viên',
                            Icons.people,
                            () async {
                              print('Navigating to ManageCandidatesScreen...'); // Debug log
                              await Navigator.pushNamed(context, '/manage_candidates');
                              print('Returned from ManageCandidatesScreen - Auto reloading dashboard...'); // Debug log
                              // Luôn load lại dashboard khi quay lại từ Quản lý ứng viên
                              _loadDashboardData();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Việc làm của tôi',
                            Icons.work,
                            () async {
                              print('Navigating to MyJobsScreen...'); // Debug log
                              await Navigator.pushNamed(context, '/my_jobs');
                              print('Returned from MyJobsScreen - Auto reloading dashboard...'); // Debug log
                              // Luôn load lại dashboard khi quay lại từ MyJobsScreen
                              _loadDashboardData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'Thống kê',
                            Icons.analytics,
                            () => Navigator.pushNamed(context, '/employer_analytics'),
                          ),
                        ),
                      ],
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

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentApplications() {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Ứng tuyển gần đây',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            print('Navigating to ManageCandidatesScreen from "Xem tất cả"...'); // Debug log
                            await Navigator.pushNamed(context, '/manage_candidates');
                            print('Returned from ManageCandidatesScreen - Auto reloading dashboard...'); // Debug log
                            // Luôn load lại dashboard khi quay lại từ Quản lý ứng viên
                            _loadDashboardData();
                          },
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _applications.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Chưa có ứng tuyển nào',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _applications.take(3).length,
                                itemBuilder: (context, index) {
                                  final application = _applications[index];
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
    final status = application['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getApplicationStatusText(status);

    return InkWell(
      onTap: () => _showApplicationDetail(application),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (application['candidate_name'] ?? 'N/A')[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    application['job_title'] ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  Text(
                    'Kinh nghiệm: ${application['experience'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
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
      ),
    );
  }

  void _showApplicationDetail(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getApplicationStatusText(status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                    'Chi tiết ứng tuyển',
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            (application['candidate_name'] ?? 'N/A')[0].toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
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
                                ),
                              ),
                              Text(
                                application['job_title'] ?? 'N/A',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Ngày ứng tuyển', _formatDate(application['applied_at'])),
                    _buildDetailRow('Kinh nghiệm', application['experience'] ?? 'N/A'),
                    if (application['cover_letter'] != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Thư ứng tuyển',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        application['cover_letter'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/manage_candidates');
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('Xem tất cả ứng viên'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobs() {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Việc làm của tôi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                TextButton(
                  onPressed: () async {
                    print('Navigating to MyJobsScreen from "Xem tất cả"...'); // Debug log
                    await Navigator.pushNamed(context, '/my_jobs');
                    print('Returned from MyJobsScreen - Auto reloading dashboard...'); // Debug log
                    // Luôn load lại dashboard khi quay lại từ MyJobsScreen
                    _loadDashboardData();
                  },
                  child: const Text('Xem tất cả'),
                ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _myJobs.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Chưa có việc làm nào',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _myJobs.take(3).length,
                                itemBuilder: (context, index) {
                                  final job = _myJobs[index];
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
    return InkWell(
      onTap: () => _showJobDetail(job),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    job['company_name'] ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  Text(
                    'Đăng ngày ${_formatDate(job['created_at'])}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(job['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(job['status']).withOpacity(0.3),
                ),
              ),
              child: Text(
                _getStatusLabel(job['status']),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: _getStatusColor(job['status']),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) {
      return Colors.amber; // Mặc định là pending nếu null
    }
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      case 'pending':
        return Colors.amber; // Màu vàng cho pending
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
        return Colors.amber; // Mặc định là pending thay vì grey
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null || status.isEmpty) {
      return 'Chờ xét duyệt'; // Mặc định là pending nếu null
    }
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'paused':
        return 'Tạm dừng';
      case 'closed':
        return 'Đã đóng';
      case 'draft':
        return 'Bản nháp';
      case 'pending':
        return 'Chờ xét duyệt';
      default:
        return 'Chờ xét duyệt'; // Mặc định là pending thay vì "Không xác định"
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) {
      return 'Chờ xét duyệt'; // Mặc định là pending nếu null
    }
    switch (status) {
      case 'pending':
        return 'Chờ xét duyệt';
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
        return 'Chờ xét duyệt'; // Mặc định là pending thay vì "Không xác định"
    }
  }

  String _getApplicationStatusText(String? status) {
    if (status == null || status.isEmpty) {
      return 'Chờ xem xét'; // Mặc định là pending nếu null
    }
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
        return 'Chờ xem xét'; // Mặc định là pending thay vì "Không xác định"
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

  String _formatSalary(int? min, int? max) {
    if (min == null && max == null) return 'Không xác định';
    if (min == null) return 'Từ $max';
    if (max == null) return 'Từ $min';
    return 'Từ $min - $max';
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
                    _buildDetailRow('Tiêu đề', job['title'] ?? 'N/A'),
                    _buildDetailRow('Công ty', job['company_name'] ?? 'N/A'),
                    _buildDetailRow('Địa điểm', job['location'] ?? 'N/A'),
                    _buildDetailRow('Mức lương', _formatSalary(job['salary_min'], job['salary_max'])),
                    _buildDetailRow('Loại hình', job['employment_type'] ?? 'N/A'),
                    _buildDetailRow('Kinh nghiệm', job['experience_level'] ?? 'N/A'),
                    _buildDetailRow('Trạng thái', _getStatusText(job['status'])),
                    const SizedBox(height: 20),
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
                    ],
                  ],
                ),
              ),
            ),
          ],
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
}