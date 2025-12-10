import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../widgets/persistent_bottom_nav.dart';
import '../services/job_service.dart';
import '../providers/simple_auth_provider.dart';

class ApplicationHistoryScreen extends StatefulWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  State<ApplicationHistoryScreen> createState() =>
      _ApplicationHistoryScreenState();
}

class _ApplicationHistoryScreenState extends State<ApplicationHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _applications = [];
  bool _loading = false;
  final _jobService = JobService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final applications = await _jobService.getApplications(auth.token!);
        setState(() {
          _applications = applications;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải lịch sử ứng tuyển: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
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
            _buildContent(),
          ],
        ),
      ),
      bottomNavigationBar: PersistentBottomNav(
        currentIndex: 1, // Applications tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Already in applications
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/news');
              break;
          }
        },
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
          'Lịch sử ứng tuyển',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
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

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: const Text(
                          'Lịch sử ứng tuyển',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_applications.isNotEmpty)
                        Flexible(
                          child: Text(
                            '${_applications.length} đơn ứng tuyển',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _applications.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _applications.length,
                              itemBuilder: (context, index) {
                                final application = _applications[index];
                                return _buildApplicationCard(application);
                              },
                            ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có đơn ứng tuyển nào',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy khám phá và ứng tuyển những việc làm phù hợp',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              icon: const Icon(Icons.explore),
              label: const Text('Khám phá việc làm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showApplicationDetail(application),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        image: application['company_logo'] != null
                            ? DecorationImage(
                                image: NetworkImage(
                                    '${AppConstants.apiBaseUrl}/${application['company_logo']}'),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: application['company_logo'] == null
                          ? const Icon(Icons.business,
                              color: AppColors.primary, size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application['job_title'] ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            application['company_name'] ?? 'N/A',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textGray),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        application['job_location'] ?? 'N/A',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.schedule,
                        size: 16, color: AppColors.textGray),
                    const SizedBox(width: 4),
                    Text(
                      'Ứng tuyển ${_formatDate(application['applied_at'])}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
                if (application['interview_date'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Phỏng vấn: ${_formatDate(application['interview_date'])}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplicationDetail(Map<String, dynamic> application) {
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                            image: application['company_logo'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        '${AppConstants.apiBaseUrl}/${application['company_logo']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: application['company_logo'] == null
                              ? const Icon(Icons.business,
                                  color: AppColors.primary, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application['job_title'] ?? 'N/A',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                application['company_name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Trạng thái ứng tuyển',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(application['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(application['status'])
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(application['status']),
                            color: _getStatusColor(application['status']),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(application['status']),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(application['status']),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Ngày ứng tuyển',
                        _formatDate(application['applied_at'])),
                    if (application['interview_date'] != null)
                      _buildDetailRow('Ngày phỏng vấn',
                          _formatDate(application['interview_date'])),
                    if (application['interview_location'] != null)
                      _buildDetailRow('Địa điểm phỏng vấn',
                          application['interview_location']),
                    if (application['cover_letter'] != null &&
                        application['cover_letter'].isNotEmpty) ...[
                      const SizedBox(height: 16),
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
                    ],
                    if (application['interview_notes'] != null &&
                        application['interview_notes'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Ghi chú phỏng vấn',
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
                          application['interview_notes'],
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'reviewed':
        return Icons.visibility;
      case 'shortlisted':
        return Icons.check_circle;
      case 'interview':
        return Icons.event;
      case 'rejected':
        return Icons.cancel;
      case 'hired':
        return Icons.celebration;
      default:
        return Icons.help;
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
