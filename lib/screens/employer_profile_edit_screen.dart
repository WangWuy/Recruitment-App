import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../providers/simple_auth_provider.dart';
import '../services/employer_profile_service.dart';
import '../widgets/error_dialog.dart';
import '../widgets/success_dialog.dart';

class EmployerProfileEditScreen extends StatefulWidget {
  const EmployerProfileEditScreen({super.key});

  @override
  State<EmployerProfileEditScreen> createState() =>
      _EmployerProfileEditScreenState();
}

class _EmployerProfileEditScreenState extends State<EmployerProfileEditScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _employerProfileService = EmployerProfileService();

  bool _loading = false;
  bool _uploading = false;
  String? _logoUrl;
  File? _selectedLogoFile;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _industryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _foundedYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfile();
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final profile = await _employerProfileService.getProfile(auth.token!);

        if (mounted) {
          setState(() {
            _nameController.text = profile['name'] ?? '';
            _descriptionController.text = profile['description'] ?? '';
            _websiteController.text = profile['website'] ?? '';
            _addressController.text = profile['address'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _emailController.text = profile['email'] ?? '';
            _industryController.text = profile['industry'] ?? '';
            _sizeController.text = profile['size'] ?? '';
            _foundedYearController.text = profile['founded_year']?.toString() ?? '';
            _logoUrl = profile['logo_url'];
          });
        }
      }
    } catch (e) {
      print('Error loading employer profile: $e');
      // Don't show error dialog, just allow user to fill in the form
      // The profile might not exist yet
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickLogo() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Chọn nguồn ảnh',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text(
                    'Chụp ảnh',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text(
                    'Chọn từ thư viện',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick image from selected source
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedLogoFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể chọn ảnh: $e');
      }
    }
  }

  Future<void> _uploadLogo() async {
    if (_selectedLogoFile == null) return;

    setState(() => _uploading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final result = await _employerProfileService.uploadLogo(
          auth.token!,
          _selectedLogoFile!.path,
        );

        setState(() {
          _logoUrl = result['logo_url'];
          _selectedLogoFile = null;
        });

        if (mounted) {
          SuccessDialog.show(context, 'Logo đã được cập nhật thành công!');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tải logo lên: $e');
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final auth = context.read<SimpleAuthProvider>();
      if (auth.token != null) {
        final profileData = <String, dynamic>{
          'name': _nameController.text,
          'description': _descriptionController.text,
          'website': _websiteController.text,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'industry': _industryController.text,
          'size': _sizeController.text,
        };

        if (_foundedYearController.text.isNotEmpty) {
          profileData['founded_year'] = int.tryParse(_foundedYearController.text);
        }

        await _employerProfileService.updateProfile(auth.token!, profileData);

        if (mounted) {
          SuccessDialog.show(
            context,
            'Thông tin công ty đã được cập nhật thành công!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể cập nhật thông tin: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    _foundedYearController.dispose();
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
          'Chỉnh sửa thông tin công ty',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
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

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 20),
                    _buildFormSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
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
        children: [
          const Text(
            'Logo công ty',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _selectedLogoFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedLogoFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _logoUrl != null && _logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedLogoFile != null)
            ElevatedButton.icon(
              onPressed: _uploading ? null : _uploadLogo,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(_uploading ? 'Đang tải lên...' : 'Tải lên logo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Chọn logo mới'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.business,
          size: 50,
          color: AppColors.primary,
        ),
        SizedBox(height: 8),
        Text(
          'Nhấn để chọn logo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin công ty',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Tên công ty *',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên công ty';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả',
              icon: Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              icon: Icons.language,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Địa chỉ',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email liên hệ',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _industryController,
              label: 'Ngành nghề',
              icon: Icons.work,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _sizeController,
              label: 'Quy mô (vd: 50-100 nhân viên)',
              icon: Icons.people,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _foundedYearController,
              label: 'Năm thành lập',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _saveProfile,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Đang lưu...' : 'Lưu thay đổi',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
