import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/simple_auth_provider.dart';
import '../services/job_service.dart';
import '../core/constants.dart';
import '../widgets/error_dialog.dart';
import 'job_detail_screen.dart';

class AllJobsScreen extends StatefulWidget {
  const AllJobsScreen({super.key});

  @override
  State<AllJobsScreen> createState() => _AllJobsScreenState();
}

class _AllJobsScreenState extends State<AllJobsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchKeyword = '';
  int? _selectedCategoryId;
  String? _selectedLocation;
  String? _selectedEmploymentType;
  String? _selectedExperienceLevel;
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final _jobService = JobService();

  // Track saved jobs
  final Set<int> _savedJobIds = {};

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Công nghệ thông tin'},
    {'id': 2, 'name': 'Kinh doanh & Bán hàng'},
    {'id': 3, 'name': 'Marketing'},
    {'id': 4, 'name': 'Design'},
    {'id': 5, 'name': 'Kế toán'},
  ];

  final List<Map<String, dynamic>> _employmentTypes = [
    {'value': 'full_time', 'label': 'Toàn thời gian'},
    {'value': 'part_time', 'label': 'Bán thời gian'},
    {'value': 'contract', 'label': 'Hợp đồng'},
    {'value': 'internship', 'label': 'Thực tập'},
    {'value': 'freelance', 'label': 'Freelance'},
  ];

  final List<Map<String, dynamic>> _experienceLevels = [
    {'value': 'entry', 'label': 'Mới tốt nghiệp'},
    {'value': 'junior', 'label': 'Junior (0-2 năm)'},
    {'value': 'mid', 'label': 'Mid-level (2-5 năm)'},
    {'value': 'senior', 'label': 'Senior (5+ năm)'},
    {'value': 'lead', 'label': 'Lead/Manager'},
    {'value': 'executive', 'label': 'Executive'},
  ];

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadSavedJobs();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    try {
      final jobProvider = context.read<JobProvider>();
      await jobProvider.fetch(
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        categoryId: _selectedCategoryId,
        location: _selectedLocation,
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        page: _currentPage,
        limit: 10,
      );
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải danh sách việc làm: $e');
      }
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final jobProvider = context.read<JobProvider>();
      final currentJobsCount = jobProvider.jobs.length;

      // Fetch more jobs và append vào danh sách hiện tại
      await jobProvider.fetchMore(
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        categoryId: _selectedCategoryId,
        location: _selectedLocation,
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        page: _currentPage,
        limit: 10,
      );

      // Kiểm tra xem có thêm data không
      if (jobProvider.jobs.length <= currentJobsCount) {
        _hasMoreData = false;
      }
    } catch (e) {
      _currentPage--; // Rollback page
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải thêm việc làm: $e');
      }
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged() {
    _searchKeyword = _searchController.text;
    _loadJobs(refresh: true);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Bộ lọc',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Filter
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả danh mục'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem<int?>(
                          value: category['id'],
                          child: Text(category['name']),
                        )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 16),

                // Employment Type Filter
                DropdownButtonFormField<String?>(
                  value: _selectedEmploymentType,
                  decoration: const InputDecoration(
                    labelText: 'Loại hình',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả loại hình'),
                    ),
                    ..._employmentTypes.map((type) => DropdownMenuItem<String?>(
                          value: type['value'],
                          child: Text(type['label']),
                        )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _selectedEmploymentType = value);
                  },
                ),
                const SizedBox(height: 16),

                // Experience Level Filter
                DropdownButtonFormField<String?>(
                  value: _selectedExperienceLevel,
                  decoration: const InputDecoration(
                    labelText: 'Kinh nghiệm',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả cấp độ'),
                    ),
                    ..._experienceLevels
                        .map((level) => DropdownMenuItem<String?>(
                              value: level['value'],
                              child: Text(level['label']),
                            )),
                  ],
                  onChanged: (value) {
                    setDialogState(() => _selectedExperienceLevel = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedCategoryId = null;
                  _selectedEmploymentType = null;
                  _selectedExperienceLevel = null;
                });
              },
              child: const Text('Xóa bộ lọc'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadJobs(refresh: true);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tất cả việc làm',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm việc làm...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon:
                            const Icon(Icons.search, color: AppColors.primary),
                        onPressed: () {
                          _onSearchChanged();
                          // Đóng bàn phím
                          FocusScope.of(context).unfocus();
                        },
                        tooltip: 'Tìm kiếm',
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      _onSearchChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _showFilterDialog,
                    icon:
                        const Icon(Icons.filter_list, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Jobs List
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, child) {
                if (jobProvider.loading && jobProvider.jobs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (jobProvider.error != null && jobProvider.jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Có lỗi xảy ra',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          jobProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadJobs(refresh: true),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (jobProvider.jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy việc làm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _loadJobs(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        jobProvider.jobs.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= jobProvider.jobs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                        );
                      }

                      final job = jobProvider.jobs[index];
                      return _buildJobCard(job);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title & Company
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company_name'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Save button
                  IconButton(
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
                  if (job['featured'] == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Nổi bật',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Job Details
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job['location'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatSalary(job['salary_min'], job['salary_max']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getEmploymentTypeLabel(job['employment_type']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category & Experience
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job['category_name'] ?? 'N/A',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getExperienceLevelLabel(job['experience_level']),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  String _formatSalary(dynamic minSalary, dynamic maxSalary) {
    if (minSalary == null && maxSalary == null) return 'Thỏa thuận';
    if (minSalary == null) return '${_formatNumber(maxSalary)}+ VND';
    if (maxSalary == null) return '${_formatNumber(minSalary)}+ VND';
    return '${_formatNumber(minSalary)} - ${_formatNumber(maxSalary)} VND';
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = int.tryParse(number.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  String _getEmploymentTypeLabel(String? type) {
    final employmentType = _employmentTypes.firstWhere(
      (item) => item['value'] == type,
      orElse: () => {'label': 'N/A'},
    );
    return employmentType['label'];
  }

  String _getExperienceLevelLabel(String? level) {
    final experienceLevel = _experienceLevels.firstWhere(
      (item) => item['value'] == level,
      orElse: () => {'label': 'N/A'},
    );
    return experienceLevel['label'];
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
            content: Text(
                result['saved'] ? 'Đã lưu việc làm' : 'Đã bỏ lưu việc làm'),
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
}
