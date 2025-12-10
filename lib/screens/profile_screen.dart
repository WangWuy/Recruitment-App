import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_auth_provider.dart';
import '../core/constants.dart';
import '../services/profile_service.dart';
import '../services/upload_service.dart';
import '../widgets/error_dialog.dart';
import '../widgets/persistent_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  
  String? _avatarUrl;
  String? _cvUrl;
  bool _loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _profileService = ProfileService();
  final _uploadService = UploadService();

  String _absoluteUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('file://')) return ''; // Skip file URLs
    final base = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 1)
        : AppConstants.apiBaseUrl;
    final path = u.startsWith('/') ? u.substring(1) : u;
    return '$base/$path';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    // Check role and redirect if employer
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoleAndLoad());
  }

  Future<void> _checkRoleAndLoad() async {
    final user = context.read<SimpleAuthProvider>().user;
    final role = user?['role'];

    // If employer, redirect to employer profile edit screen
    if (role == 'employer') {
      Navigator.pushReplacementNamed(context, '/employer_profile_edit');
      return;
    }

    // Otherwise, load candidate profile
    await _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _educationController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final authProvider = context.read<SimpleAuthProvider>();
      final token = authProvider.token;

      print('🔐 Loading profile...');
      print('🔐 Token from provider: ${token == null ? "NULL" : "${token.substring(0, 10)}..."}');
      print('🔐 Is logged in: ${authProvider.isLoggedIn}');
      print('🔐 User: ${authProvider.user}');

      if (token == null) {
        throw Exception('Token is null. Please login again.');
      }

      final profile = await _profileService.getMine(token);
      print('Profile data received: $profile'); // Debug
      if (profile != null) {
        _avatarUrl = _absoluteUrl(profile['avatar_url'] as String?);
        print('Loaded avatar URL: $_avatarUrl'); // Debug
        _headlineController.text = profile['headline'] ?? '';
        _educationController.text = profile['education'] ?? '';
        _experienceController.text = profile['experience'] ?? '';
        _skillsController.text = profile['skills'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _linkedinController.text = profile['linkedin'] ?? '';
        _githubController.text = profile['github'] ?? '';
        _cvUrl = profile['cv_url'] as String?;
        print('Profile loaded successfully'); // Debug
      } else {
        print('No profile data found'); // Debug
      }
      
      // Load tên user từ auth provider
      final user = context.read<SimpleAuthProvider>().user;
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        print('User name loaded: ${user['name']}'); // Debug
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải thông tin hồ sơ: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null) return;

      final token = context.read<SimpleAuthProvider>().token!;
      final file = result.files.first;
      final bytes = file.bytes as Uint8List;
      final name = file.name;

      final upload = await _uploadService.uploadBytes(token, bytes, name);
      final newUrl = _absoluteUrl(upload['url'] as String);
      print('New avatar URL: $newUrl'); // Debug
      
      setState(() { 
        _avatarUrl = newUrl;
      });

      // Lưu ngay avatar mới lên backend để đồng bộ
      await _profileService.upsertMine(token, {
        'avatar_url': newUrl,
      });

      // Force refresh widget
      if (mounted) {
        setState(() {});
        ErrorDialog.showSuccess(context, 'Cập nhật ảnh đại diện thành công!');
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải lên ảnh: $e');
      }
    }
  }

  Future<void> _pickAndUploadCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null) return;

      final token = context.read<SimpleAuthProvider>().token!;
      final file = result.files.first;
      final bytes = file.bytes as Uint8List;
      final name = file.name;

      final upload = await _uploadService.uploadBytes(token, bytes, name);
      setState(() {
        _cvUrl = upload['url'] as String;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải lên CV thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải lên CV: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final token = context.read<SimpleAuthProvider>().token!;
      final profileData = {
        'name': _nameController.text, // Thêm tên user
        'avatar_url': _avatarUrl,
        'headline': _headlineController.text,
        'education': _educationController.text,
        'experience': _experienceController.text,
        'skills': _skillsController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'linkedin': _linkedinController.text,
        'github': _githubController.text,
        'cv_url': _cvUrl,
      };
      print('Saving profile data: $profileData'); // Debug
      await _profileService.upsertMine(token, profileData);
      
      // Cập nhật thông tin user trong auth provider
      if (_nameController.text.isNotEmpty) {
        context.read<SimpleAuthProvider>().updateUserInfo({
          'name': _nameController.text
        });
      }
      
      if (mounted) {
        ErrorDialog.showSuccess(context, 'Lưu hồ sơ thành công!');
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể lưu hồ sơ: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SimpleAuthProvider>().user;
    
    return Scaffold(
      bottomNavigationBar: PersistentBottomNav(
        currentIndex: 2, // Profile tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/saved_jobs');
              break;
            case 2:
              // Already in profile
              break;
          }
        },
      ),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Trang chủ',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<SimpleAuthProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Container(
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
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                        child: RefreshIndicator(
                          onRefresh: _loadProfile,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                            children: [
                              // Header với ảnh đại diện
                              Container(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Ảnh đại diện với hiệu ứng
                                    Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF667eea),
                                                Color(0xFF764ba2),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                              ? ClipOval(
                                                  child: Image.network(
                                                    '${_avatarUrl!.startsWith('http') ? _avatarUrl : ''}${_avatarUrl!.startsWith('http') ? '?t=' + DateTime.now().millisecondsSinceEpoch.toString() : ''}',
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return const SizedBox(
                                                        width: 120,
                                                        height: 120,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      print('Avatar load error: $error');
                                                      print('Avatar URL: $_avatarUrl');
                                                      return const Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: Colors.white,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF667eea),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                            child: IconButton(
                                              onPressed: _pickAndUploadAvatar,
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Tên và email
                                    Text(
                                      user?['name'] ?? 'Chưa cập nhật',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?['email'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // CV Buttons Row
                                    Row(
                                      children: [
                                        // Upload CV button
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                            child: TextButton.icon(
                                              onPressed: _pickAndUploadCV,
                                              icon: const Icon(
                                                Icons.upload_file,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              label: Text(
                                                _cvUrl != null ? 'Cập nhật CV' : 'Tải lên CV',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Create CV button
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: TextButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/cv_builder');
                                              },
                                              icon: const Icon(
                                                Icons.description,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              label: const Text(
                                                'Tạo CV',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Form thông tin
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thông tin cá nhân',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Trường tên
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Họ và tên',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Vui lòng nhập họ và tên';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Tiêu đề nghề nghiệp
                                      TextFormField(
                                        controller: _headlineController,
                                        decoration: InputDecoration(
                                          labelText: 'Tiêu đề nghề nghiệp',
                                          hintText: 'VD: Flutter Developer, UI/UX Designer',
                                          prefixIcon: const Icon(Icons.work_outline),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Vui lòng nhập tiêu đề nghề nghiệp';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // Số điện thoại
                                      TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Số điện thoại',
                                          hintText: 'VD: 0123456789',
                                          prefixIcon: const Icon(Icons.phone_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: 16),
                                      // Địa chỉ
                                      TextFormField(
                                        controller: _addressController,
                                        decoration: InputDecoration(
                                          labelText: 'Địa chỉ',
                                          hintText: 'VD: Hà Nội, Việt Nam',
                                          prefixIcon: const Icon(Icons.location_on_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Học vấn & Kinh nghiệm',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Học vấn
                                      TextFormField(
                                        controller: _educationController,
                                        decoration: InputDecoration(
                                          labelText: 'Học vấn',
                                          hintText: 'VD: Đại học Bách Khoa Hà Nội - Công nghệ thông tin',
                                          prefixIcon: const Icon(Icons.school_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      // Kinh nghiệm
                                      TextFormField(
                                        controller: _experienceController,
                                        decoration: InputDecoration(
                                          labelText: 'Kinh nghiệm làm việc',
                                          hintText: 'Mô tả chi tiết kinh nghiệm của bạn...',
                                          prefixIcon: const Icon(Icons.business_center_outlined),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 16),
                                      // Kỹ năng
                                      TextFormField(
                                        controller: _skillsController,
                                        decoration: InputDecoration(
                                          labelText: 'Kỹ năng',
                                          hintText: 'VD: Flutter, Dart, React, Node.js (cách nhau bằng dấu phẩy)',
                                          prefixIcon: const Icon(Icons.star_outline),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Liên kết xã hội',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // LinkedIn
                                      TextFormField(
                                        controller: _linkedinController,
                                        decoration: InputDecoration(
                                          labelText: 'LinkedIn',
                                          hintText: 'https://linkedin.com/in/yourname',
                                          prefixIcon: const Icon(Icons.link),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        keyboardType: TextInputType.url,
                                      ),
                                      const SizedBox(height: 16),
                                      // GitHub
                                      TextFormField(
                                        controller: _githubController,
                                        decoration: InputDecoration(
                                          labelText: 'GitHub',
                                          hintText: 'https://github.com/yourname',
                                          prefixIcon: const Icon(Icons.code),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        keyboardType: TextInputType.url,
                                      ),
                                      const SizedBox(height: 32),
                                      // Nút lưu
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _saveProfile,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text(
                                                  'Lưu hồ sơ',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (_cvUrl != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'CV đã được tải lên',
                                                  style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
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
        ),
      ),
    );
  }
}