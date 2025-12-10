import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../services/employer_service.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../widgets/error_dialog.dart';

class EmployerAnalyticsScreen extends StatefulWidget {
  const EmployerAnalyticsScreen({super.key});

  @override
  State<EmployerAnalyticsScreen> createState() => _EmployerAnalyticsScreenState();
}

class _EmployerAnalyticsScreenState extends State<EmployerAnalyticsScreen> {
  final _employerService = EmployerService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Chưa đăng nhập');
      }

      final stats = await _employerService.getDashboardStats(authProvider.token!);
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thống kê chi tiết',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi tải thống kê',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _stats == null
                  ? const Center(
                      child: Text('Không có dữ liệu thống kê'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tổng quan việc làm
                            _buildSection(
                              title: 'Tổng quan việc làm',
                              icon: Icons.work,
                              color: AppColors.primary,
                              children: [
                                _buildStatCard(
                                  title: 'Tổng số việc làm',
                                  value: '${_stats!['jobs']?['total_jobs'] ?? 0}',
                                  icon: Icons.work_outline,
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  title: 'Việc làm đang hoạt động',
                                  value: '${_stats!['jobs']?['active_jobs'] ?? 0}',
                                  icon: Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                _buildStatCard(
                                  title: 'Việc làm tạm dừng',
                                  value: '${_stats!['jobs']?['paused_jobs'] ?? 0}',
                                  icon: Icons.pause_circle_outline,
                                  color: Colors.orange,
                                ),
                                _buildStatCard(
                                  title: 'Việc làm đã đóng',
                                  value: '${_stats!['jobs']?['closed_jobs'] ?? 0}',
                                  icon: Icons.cancel_outlined,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Tổng quan ứng viên
                            _buildSection(
                              title: 'Tổng quan ứng viên',
                              icon: Icons.people,
                              color: AppColors.accent,
                              children: [
                                _buildStatCard(
                                  title: 'Tổng số ứng tuyển',
                                  value: '${_stats!['applications']?['total_applications'] ?? 0}',
                                  icon: Icons.person_add_outlined,
                                  color: Colors.purple,
                                ),
                                _buildStatCard(
                                  title: 'Chờ xem xét',
                                  value: '${_stats!['applications']?['pending_applications'] ?? 0}',
                                  icon: Icons.hourglass_empty,
                                  color: Colors.amber,
                                ),
                                _buildStatCard(
                                  title: 'Đã xem xét',
                                  value: '${_stats!['applications']?['reviewed_applications'] ?? 0}',
                                  icon: Icons.visibility_outlined,
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  title: 'Đã lọt vào vòng trong',
                                  value: '${_stats!['applications']?['shortlisted_applications'] ?? 0}',
                                  icon: Icons.star_outline,
                                  color: Colors.green,
                                ),
                                _buildStatCard(
                                  title: 'Mời phỏng vấn',
                                  value: '${_stats!['applications']?['interview_applications'] ?? 0}',
                                  icon: Icons.event_outlined,
                                  color: Colors.orange,
                                ),
                                _buildStatCard(
                                  title: 'Đã từ chối',
                                  value: '${_stats!['applications']?['rejected_applications'] ?? 0}',
                                  icon: Icons.close_outlined,
                                  color: Colors.red,
                                ),
                                _buildStatCard(
                                  title: 'Đã tuyển dụng',
                                  value: '${_stats!['applications']?['hired_applications'] ?? 0}',
                                  icon: Icons.check_circle,
                                  color: Colors.green[700]!,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Thống kê lượt xem
                            if (_stats!['jobs']?['total_views'] != null)
                              _buildSection(
                                title: 'Thống kê lượt xem',
                                icon: Icons.visibility,
                                color: Colors.indigo,
                                children: [
                                  _buildStatCard(
                                    title: 'Tổng lượt xem',
                                    value: '${_stats!['jobs']?['total_views'] ?? 0}',
                                    icon: Icons.visibility_outlined,
                                    color: Colors.indigo,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
