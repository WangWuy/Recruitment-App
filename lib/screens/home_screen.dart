import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/job_service.dart';
import '../core/constants.dart';
import '../widgets/error_dialog.dart';
import '../widgets/persistent_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _searchAnimationController;

  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _searchOpacityAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';
  int _currentNavIndex = 0;
  final _jobService = JobService();

  // Track saved jobs
  final Set<int> _savedJobIds = {};
  // Build absolute URLs for company avatars/logo
  late final String _baseUrl = AppConstants.apiBaseUrl.endsWith('/')
      ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 1)
      : AppConstants.apiBaseUrl;
  
  final List<String> _categories = [
    'Tất cả',
    'Công nghệ',
    'Kinh doanh',
    'Marketing',
    'Design',
    'Kế toán',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Load jobs after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  void _setupAnimations() {
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _searchOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    ));

    // Start animations with delays
    _heroAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _searchAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _cardAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _resolveLogoUrl(dynamic rawUrl) {
    if (rawUrl == null) return null;
    final url = rawUrl.toString().trim();
    if (url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final normalized = url.startsWith('/') ? url.substring(1) : url;
    return '$_baseUrl/$normalized';
  }

  Future<void> _loadJobs() async {
    try {
      await context.read<JobProvider>().fetch();
      await _loadSavedJobs();
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải danh sách việc làm: $e');
      }
    }
  }

  Future<void> _loadSavedJobs() async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token == null || auth.user?['role'] != 'candidate') {
      return;
    }

    try {
      final savedJobs = await _jobService.getSavedJobs(auth.token!);
      setState(() {
        _savedJobIds.clear();
        for (var job in savedJobs) {
          _savedJobIds.add(job['id'] as int);
        }
      });
    } catch (e) {
      // Silently fail - not critical
      print('Failed to load saved jobs: $e');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    
    switch (index) {
      case 0:
        // Trang chủ - đã ở đây rồi
        break;
      case 1:
        // Đã lưu
        Navigator.pushNamed(context, '/saved_jobs');
        break;
      case 2:
        // Hồ sơ
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _selectedCategory = 'Tất cả';
    });
    
    // Gọi API search
    context.read<JobProvider>().fetch(keyword: query.trim());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang tìm kiếm: "$query"'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category;
    });
    
    // Clear search when filtering by category
    _searchController.clear();
    
    // Gọi API với category filter
    if (category == 'Tất cả') {
      context.read<JobProvider>().fetch();
    } else {
      // Map category names to IDs (có thể cần cập nhật sau)
      int? categoryId;
      switch (category) {
        case 'Công nghệ':
          categoryId = 1;
          break;
        case 'Kinh doanh':
          categoryId = 2;
          break;
        case 'Marketing':
          categoryId = 3;
          break;
        case 'Design':
          categoryId = 4;
          break;
        case 'Kế toán':
          categoryId = 5;
          break;
      }
      
      context.read<JobProvider>().fetch(categoryId: categoryId);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang lọc theo: $category'),
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _scrollToJobs() {
    // Scroll to jobs section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tải danh sách việc làm...'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showFilterDialog() {
    // Filter state
    String? selectedLocation;
    String? selectedEmploymentType;
    String? selectedExperienceLevel;
    int? minSalary;
    int? maxSalary;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Bộ lọc nâng cao',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location filter
                const Text('Địa điểm', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Chọn địa điểm'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 'Hà Nội', child: Text('Hà Nội')),
                    DropdownMenuItem(value: 'TP.HCM', child: Text('TP.HCM')),
                    DropdownMenuItem(value: 'Đà Nẵng', child: Text('Đà Nẵng')),
                    DropdownMenuItem(value: 'Hải Phòng', child: Text('Hải Phòng')),
                    DropdownMenuItem(value: 'Cần Thơ', child: Text('Cần Thơ')),
                  ],
                  onChanged: (value) => setState(() => selectedLocation = value),
                ),
                const SizedBox(height: 16),

                // Employment type filter
                const Text('Loại hình công việc', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Chọn loại hình'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 'full-time', child: Text('Toàn thời gian')),
                    DropdownMenuItem(value: 'part-time', child: Text('Bán thời gian')),
                    DropdownMenuItem(value: 'contract', child: Text('Hợp đồng')),
                    DropdownMenuItem(value: 'internship', child: Text('Thực tập')),
                  ],
                  onChanged: (value) => setState(() => selectedEmploymentType = value),
                ),
                const SizedBox(height: 16),

                // Experience level filter
                const Text('Kinh nghiệm', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Chọn kinh nghiệm'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 'internship', child: Text('Thực tập sinh')),
                    DropdownMenuItem(value: 'entry', child: Text('Mới đi làm')),
                    DropdownMenuItem(value: 'junior', child: Text('Junior (1-3 năm)')),
                    DropdownMenuItem(value: 'middle', child: Text('Middle (3-5 năm)')),
                    DropdownMenuItem(value: 'senior', child: Text('Senior (5+ năm)')),
                  ],
                  onChanged: (value) => setState(() => selectedExperienceLevel = value),
                ),
                const SizedBox(height: 16),

                // Salary range filter
                const Text('Mức lương (triệu VNĐ)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Từ',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() => minSalary = int.tryParse(value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Đến',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() => maxSalary = int.tryParse(value));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters(
                            location: selectedLocation,
                            employmentType: selectedEmploymentType,
                            experienceLevel: selectedExperienceLevel,
                            minSalary: minSalary,
                            maxSalary: maxSalary,
                          );
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilters({
    String? location,
    String? employmentType,
    String? experienceLevel,
    int? minSalary,
    int? maxSalary,
  }) {
    // Clear search and category when applying filters
    _searchController.clear();
    setState(() {
      _selectedCategory = 'Tất cả';
    });

    // Call API with filter parameters
    context.read<JobProvider>().fetch(
      location: location,
      employmentType: employmentType,
      experienceLevel: experienceLevel,
      minSalary: minSalary,
      maxSalary: maxSalary,
    );

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã áp dụng bộ lọc'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSaveJob(int jobId) async {
    final auth = context.read<SimpleAuthProvider>();
    if (auth.token == null || auth.user?['role'] != 'candidate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ ứng viên mới có thể lưu việc làm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final result = await _jobService.toggleSaveJob(auth.token!, jobId);

      // Update saved jobs set
      setState(() {
        if (result['saved'] == true) {
          _savedJobIds.add(jobId);
        } else {
          _savedJobIds.remove(jobId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['saved'] ? 'Đã lưu việc làm' : 'Đã bỏ lưu việc làm'),
            backgroundColor: result['saved'] ? AppColors.primary : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu việc làm: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SimpleAuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Modern App Bar
              _buildModernAppBar(auth),
              
              // Hero Section
              _buildHeroSection(),
              
              // Search Section
              _buildSearchSection(),
              
              // Categories
              _buildCategoriesSection(),
              
              // Features Section
              _buildFeaturesSection(),
              
              // Jobs Section
              _buildJobsSection(jobProvider),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PersistentBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildModernAppBar(SimpleAuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo/Brand
            AnimatedBuilder(
              animation: _heroFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _heroFadeAnimation.value,
                  child: const Text(
                    'DT - TOP CV',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            
            // User Actions
            Row(
              children: [
                _buildAnimatedIconButton(
                  icon: Icons.newspaper_outlined,
                  onPressed: () => Navigator.pushNamed(context, '/news'),
                ),
                const SizedBox(width: 8),
                _buildAnimatedIconButton(
                  icon: Icons.history,
                  onPressed: () => Navigator.pushNamed(context, '/application_history'),
                ),
                const SizedBox(width: 8),
                _buildAnimatedIconButton(
                  icon: Icons.logout,
                  onPressed: () async {
                    await auth.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        iconSize: 20,
      ),
    );
  }

  Widget _buildHeroSection() {
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
                    const SizedBox(height: 20),
                    const Text(
                      'Tìm việc làm mơ ước',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Khám phá hàng nghìn cơ hội việc làm từ các công ty hàng đầu',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: _buildCTAButton()),
                        const SizedBox(width: 12),
                        _buildAIChatButton(),
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

  Widget _buildAIChatButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/ai_chatbot');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Icon(Icons.smart_toy, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text(
                  'AI Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _scrollToJobs();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Khám phá ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _searchAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _searchOpacityAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm việc làm, công ty, kỹ năng...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.textGray),
                    onPressed: _showFilterDialog,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (value) {
                  _handleSearch(value);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardScaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh mục',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected 
                                ? AppColors.accentGradient 
                                : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _handleCategoryFilter(category);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.work_outline,
        'title': 'Việc làm chất lượng',
        'description': 'Từ các công ty hàng đầu',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.speed,
        'title': 'Ứng tuyển nhanh',
        'description': 'Chỉ với vài cú click',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.trending_up,
        'title': 'Cơ hội thăng tiến',
        'description': 'Phát triển sự nghiệp',
        'color': AppColors.accent,
      },
    ];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardScaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tại sao chọn chúng tôi?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: features.map((feature) {
                      return Expanded(
                        child: _buildFeatureCard(feature),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (feature['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: feature['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  feature['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobsSection(JobProvider jobProvider) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _cardAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardScaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Việc làm nổi bật',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (jobProvider.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (jobProvider.jobs.isEmpty)
                    _buildEmptyState()
                  else
                    ...jobProvider.jobs.take(3).map((job) => _buildJobCard(job)),
                  
                  const SizedBox(height: 20),
                  _buildViewAllButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: AppColors.textGray,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có việc làm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy quay lại sau để xem các cơ hội mới',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
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
              onTap: () {
                Navigator.pushNamed(context, '/job_detail', arguments: job);
              },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCompanyAvatar(job['company_logo']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'Không có tiêu đề',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['company'] ?? job['company_name'] ?? 'Không có công ty',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textGray,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job['location'] ?? 'Không có địa điểm',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGray,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job['type'] ?? job['employment_type'] ?? 'Full-time',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Save button
                Flexible(
                  child: IconButton(
                    onPressed: () => _toggleSaveJob(job['id']),
                    icon: Icon(
                      _savedJobIds.contains(job['id'])
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: _savedJobIds.contains(job['id'])
                          ? Colors.red
                          : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyAvatar(dynamic logoUrl) {
    final resolvedUrl = _resolveLogoUrl(logoUrl);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: resolvedUrl == null ? AppColors.primaryGradient : null,
        color: resolvedUrl != null ? Colors.grey.shade200 : null,
      ),
      child: resolvedUrl == null
          ? const Icon(Icons.business, color: Colors.white, size: 24)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.business, color: AppColors.primary),
                ),
              ),
            ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/all_jobs');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả việc làm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
