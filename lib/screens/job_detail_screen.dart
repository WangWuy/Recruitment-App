import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../widgets/persistent_bottom_nav.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/application_provider.dart';
import '../services/job_service.dart';
import '../widgets/success_dialog.dart';
import '../widgets/error_dialog.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;

  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _contentScaleAnimation;

  bool _isSaved = false;
  bool _isApplied = false;
  int? _applicationId;
  final _jobService = JobService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkApplicationStatus();
    _checkSavedStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token != null && auth.user?['role'] == 'candidate') {
      final applicationProvider = ApplicationProvider();
      final check = await applicationProvider.applicationService
          .checkApplied(auth.token!, widget.job['id']);
      final hasApplied = check['has_applied'] == true;
      if (mounted) {
        setState(() {
          _isApplied = hasApplied;
          _applicationId = check['application_id'] as int?;
        });
      }
    }
  }

  Future<void> _checkSavedStatus() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token != null && auth.user?['role'] == 'candidate') {
      try {
        final savedJobs = await _jobService.getSavedJobs(auth.token!);
        final isSaved = savedJobs.any((job) => job['id'] == widget.job['id']);
        if (mounted) {
          setState(() {
            _isSaved = isSaved;
          });
        }
      } catch (e) {
        print('Error checking saved status: $e');
      }
    }
  }

  Future<void> _applyForJob() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token == null || auth.user?['role'] != 'candidate') {
      ErrorDialog.show(context, 'Chỉ ứng viên mới có thể ứng tuyển');
      return;
    }

    // Show cover letter dialog
    final coverLetter = await _showCoverLetterDialog();
    if (coverLetter == null) return;

    final applicationProvider = ApplicationProvider();
    final success = await applicationProvider.applyForJob(
        auth.token!, widget.job['id'], coverLetter);

    if (mounted) {
      if (success) {
        await SuccessDialog.show(context, 'Ứng tuyển thành công!');
        setState(() {
          _isApplied = true;
        });
      } else {
        ErrorDialog.show(context,
            applicationProvider.error ?? 'Có lỗi xảy ra khi ứng tuyển');
      }
    }
  }

  Future<void> _cancelApplication() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy ứng tuyển'),
        content: const Text(
            'Bạn có chắc chắn muốn hủy ứng tuyển cho công việc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final applicationProvider = ApplicationProvider();
    // Nếu chưa có applicationId, kiểm tra lại
    if (_applicationId == null) {
      final check = await applicationProvider.applicationService
          .checkApplied(auth.token!, widget.job['id']);
      _applicationId = check['application_id'] as int?;
    }
    if (_applicationId == null) {
      if (mounted)
        ErrorDialog.show(context, 'Không tìm thấy đơn ứng tuyển để hủy');
      return;
    }
    final success = await applicationProvider.cancelApplication(
        auth.token!, _applicationId!);

    if (mounted) {
      if (success) {
        await SuccessDialog.show(context, 'Đã hủy ứng tuyển thành công!');
        setState(() {
          _isApplied = false;
          _applicationId = null;
        });
      } else {
        ErrorDialog.show(context,
            applicationProvider.error ?? 'Có lỗi xảy ra khi hủy ứng tuyển');
      }
    }
  }

  Future<String?> _showCoverLetterDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thư xin việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Hãy viết một vài dòng về bản thân và lý do bạn muốn ứng tuyển:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Viết thư xin việc của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _setupAnimations() {
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _contentScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.elasticOut,
    ));

    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _contentAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildJobHeader(),
              _buildJobContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PersistentBottomNav(
        currentIndex: 0, // Home tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/saved_jobs');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: AnimatedBuilder(
        animation: _heroFadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _heroFadeAnimation.value,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          );
        },
      ),
      actions: [
        AnimatedBuilder(
          animation: _heroFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _heroFadeAnimation.value,
              child: IconButton(
                onPressed: _shareJob,
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobHeader() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _heroAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _heroFadeAnimation,
            child: SlideTransition(
              position: _heroSlideAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company logo and info
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.job['company'] ??
                                          widget.job['company_name'] ??
                                          'Công ty',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Icon lưu bên phải cạnh tên
                                  IconButton(
                                    onPressed: _toggleSave,
                                    icon: Icon(
                                      _isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: _isSaved
                                          ? Colors.yellow
                                          : Colors.white,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.job['location'] ?? 'Địa điểm',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Job title
                    Text(
                      widget.job['title'] ?? 'Tiêu đề việc làm',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Job type and salary
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.work_outline,
                          widget.job['type'] ?? 'Full-time',
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.attach_money,
                          widget.job['salary'] ?? 'Thương lượng',
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobContent() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _contentAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _contentScaleAnimation.value,
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
                  _buildSectionTitle('Mô tả công việc'),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Yêu cầu'),
                  const SizedBox(height: 16),
                  _buildRequirements(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quyền lợi'),
                  const SizedBox(height: 16),
                  _buildBenefits(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.job['description'] ??
          'Mô tả chi tiết về công việc sẽ được cập nhật...',
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: AppColors.textGray,
        height: 1.6,
      ),
    );
  }

  Widget _buildRequirements() {
    final requirements = [
      'Kinh nghiệm 2-3 năm trong lĩnh vực tương tự',
      'Thành thạo các công nghệ liên quan',
      'Kỹ năng giao tiếp tốt',
      'Có khả năng làm việc nhóm',
    ];

    return Column(
      children: requirements.map((req) => _buildListItem(req)).toList(),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      'Lương cạnh tranh',
      'Bảo hiểm đầy đủ',
      'Môi trường làm việc năng động',
      'Cơ hội thăng tiến',
    ];

    return Column(
      children: benefits.map((benefit) => _buildListItem(benefit)).toList(),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textGray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Flexible(
          child: OutlinedButton(
            onPressed: _toggleSave,
            style: OutlinedButton.styleFrom(
              side:
                  BorderSide(color: _isSaved ? Colors.red : AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? Colors.red : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  // đảm bảo text có thể co và hiển thị ellipsis nếu quá dài
                  child: Text(
                    _isSaved ? 'Đã lưu' : 'Lưu việc làm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: _isSaved ? Colors.red : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isApplied ? _cancelApplication : _applyForJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isApplied ? Colors.red : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isApplied ? Icons.cancel : Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isApplied ? 'Hủy ứng tuyển' : 'Ứng tuyển ngay',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSave() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token == null || auth.user?['role'] != 'candidate') {
      ErrorDialog.show(context, 'Chỉ ứng viên mới có thể lưu việc làm');
      return;
    }

    try {
      final result =
          await _jobService.toggleSaveJob(auth.token!, widget.job['id']);
      if (mounted) {
        setState(() {
          _isSaved = result['saved'] ?? false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'Đã lưu việc làm' : 'Đã bỏ lưu việc làm'),
            backgroundColor: _isSaved ? AppColors.primary : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể lưu việc làm: $e');
      }
    }
  }

  void _applyJob() {
    setState(() {
      _isApplied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi đơn ứng tuyển thành công!'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _shareJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng chia sẻ sẽ được phát triển'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
