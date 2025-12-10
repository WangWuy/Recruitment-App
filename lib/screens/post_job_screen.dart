import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../providers/simple_auth_provider.dart';
import '../providers/job_provider.dart';
import '../widgets/error_dialog.dart';
import '../widgets/success_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  String _selectedEmploymentType = 'full_time';
  String _selectedExperienceLevel = 'mid';
  int? _selectedCategoryId = 1;
  int? _selectedCompanyId;
  bool _isRemote = false;
  bool _isUrgent = false;
  bool _isFeatured = false;
  bool _loading = false;
  LatLng? _pickedLatLng;
  String _mapAddress = ''; // Địa chỉ hiển thị trên map

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

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Công nghệ'},
    {'id': 2, 'name': 'Kinh doanh'},
    {'id': 3, 'name': 'Marketing'},
    {'id': 4, 'name': 'Design'},
    {'id': 5, 'name': 'Kế toán'},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

  // Reverse geocoding - Lấy địa chỉ từ tọa độ
  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${latLng.latitude}&lon=${latLng.longitude}&format=json&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'RecruitmentApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Không xác định được địa chỉ';
      }
      return 'Không xác định được địa chỉ';
    } catch (e) {
      print('❌ Error getting address: $e');
      return 'Không xác định được địa chỉ';
    }
  }

  Future<void> _openMapPicker() async {
    LatLng temp = _pickedLatLng ?? const LatLng(21.0278, 105.8342); // Hà Nội mặc định
    String tempAddress = _mapAddress;
    bool loadingAddress = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chọn vị trí trên bản đồ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hiển thị địa chỉ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: loadingAddress
                                ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đang tải địa chỉ...',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    tempAddress.isEmpty
                                        ? 'Nhấn vào bản đồ để chọn vị trí'
                                        : tempAddress,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: tempAddress.isEmpty ? AppColors.textGray : AppColors.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: temp,
                            initialZoom: 12,
                            onTap: (tapPos, latlng) async {
                              setSheetState(() {
                                temp = latlng;
                                loadingAddress = true;
                                tempAddress = '';
                              });

                              // Lấy địa chỉ từ tọa độ
                              final address = await _getAddressFromLatLng(latlng);
                              setSheetState(() {
                                tempAddress = address;
                                loadingAddress = false;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.recruitment_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: temp,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: tempAddress.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _pickedLatLng = temp;
                                        _mapAddress = tempAddress;
                                        _locationController.text = tempAddress;
                                      });
                                      Navigator.pop(context);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Xác nhận vị trí'),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _handlePostJob() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      final jobProvider = context.read<JobProvider>();

      final token = auth.token;
      final role = auth.user?['role'];
      if (token == null) {
        ErrorDialog.show(context, 'Bạn cần đăng nhập để đăng tin tuyển dụng.');
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (role != 'employer') {
        ErrorDialog.show(context, 'Bạn cần đăng nhập bằng tài khoản nhà tuyển dụng.');
        if (mounted) setState(() => _loading = false);
        return;
      }

      final jobData = <String, dynamic>{
        'category_id': _selectedCategoryId ?? 1,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _pickedLatLng?.latitude,
        'longitude': _pickedLatLng?.longitude,
        'salary_min': int.tryParse(_salaryMinController.text.trim()),
        'salary_max': int.tryParse(_salaryMaxController.text.trim()),
        'employment_type': _selectedEmploymentType,
        'experience_level': _selectedExperienceLevel,
        'is_remote': _isRemote,
        'is_urgent': _isUrgent,
        'is_featured': _isFeatured,
      };

      final int jobId = await jobProvider.createJob(token, jobData);

      if (!mounted) return;
      await SuccessDialog.show(
        context,
        jobId > 0
            ? 'Tin đã được gửi và đang chờ quản trị viên xét duyệt.'
            : 'Gửi tin thành công. Đang chờ quản trị viên xét duyệt.',
      );
      await jobProvider.loadJobs();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(context, 'Không thể đăng tin tuyển dụng: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            _buildForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Đăng tin tuyển dụng',
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

  Widget _buildForm() {
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin việc làm',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Tiêu đề công việc
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề công việc *',
                          hintText: 'VD: Flutter Developer',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề công việc';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Địa điểm
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Địa điểm làm việc *',
                          hintText: 'VD: Hà Nội, TP.HCM',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          suffixIcon: IconButton(
                            tooltip: 'Chọn từ bản đồ',
                            icon: const Icon(Icons.map_outlined),
                            onPressed: _openMapPicker,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập địa điểm làm việc';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mức lương
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salaryMinController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Lương tối thiểu (VNĐ)',
                                hintText: 'VD: 10000000',
                                prefixIcon: const Icon(Icons.monetization_on_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryMaxController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Lương tối đa (VNĐ)',
                                hintText: 'VD: 20000000',
                                prefixIcon: const Icon(Icons.monetization_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Loại hình công việc
                      DropdownButtonFormField<String>(
                        value: _selectedEmploymentType,
                        decoration: InputDecoration(
                          labelText: 'Loại hình công việc',
                          prefixIcon: const Icon(Icons.schedule),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _employmentTypes.map<DropdownMenuItem<String>>((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'] as String,
                            child: Text(type['label'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEmploymentType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kinh nghiệm
                      DropdownButtonFormField<String>(
                        value: _selectedExperienceLevel,
                        decoration: InputDecoration(
                          labelText: 'Yêu cầu kinh nghiệm',
                          prefixIcon: const Icon(Icons.trending_up),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _experienceLevels.map<DropdownMenuItem<String>>((level) {
                          return DropdownMenuItem<String>(
                            value: level['value'] as String,
                            child: Text(level['label'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExperienceLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Danh mục
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _categories.map<DropdownMenuItem<int>>((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'] as int,
                            child: Text(category['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mô tả công việc
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Mô tả công việc *',
                          hintText: 'Mô tả chi tiết về công việc, trách nhiệm...',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả công việc';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Yêu cầu
                      TextFormField(
                        controller: _requirementsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Yêu cầu ứng viên',
                          hintText: 'Kỹ năng, kinh nghiệm, bằng cấp...',
                          prefixIcon: const Icon(Icons.checklist),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quyền lợi
                      TextFormField(
                        controller: _benefitsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Quyền lợi',
                          hintText: 'Lương thưởng, bảo hiểm, phúc lợi...',
                          prefixIcon: const Icon(Icons.card_giftcard),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tùy chọn bổ sung
                      const Text(
                        'Tùy chọn bổ sung',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildCheckboxOption(
                        'Làm việc từ xa',
                        _isRemote,
                        (value) => setState(() => _isRemote = value!),
                      ),
                      _buildCheckboxOption(
                        'Tin tuyển dụng khẩn cấp',
                        _isUrgent,
                        (value) => setState(() => _isUrgent = value!),
                      ),
                      _buildCheckboxOption(
                        'Tin nổi bật',
                        _isFeatured,
                        (value) => setState(() => _isFeatured = value!),
                      ),
                      const SizedBox(height: 30),

                      // Nút đăng tin
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _handlePostJob,
                                icon: const Icon(Icons.publish),
                                label: const Text('Đăng tin tuyển dụng'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckboxOption(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}