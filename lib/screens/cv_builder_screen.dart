import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/cv_data.dart';
import '../services/cv_pdf_service.dart';
import '../providers/simple_auth_provider.dart';
import '../widgets/success_dialog.dart';
import '../widgets/error_dialog.dart';

class CVBuilderScreen extends StatefulWidget {
  const CVBuilderScreen({super.key});

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen> {
  final _cvPdfService = CVPdfService();
  CVTemplate _selectedTemplate = CVTemplate.modern;
  bool _isGenerating = false;

  late CVData _cvData;

  @override
  void initState() {
    super.initState();
    _loadCVData();
  }

  void _loadCVData() {
    // Load từ user profile hoặc dùng sample data
    final auth = context.read<SimpleAuthProvider>();
    final user = auth.user;

    _cvData = CVData(
      fullName: user?['name'] ?? 'Nguyễn Văn A',
      email: user?['email'] ?? 'nguyenvana@email.com',
      phone: user?['phone'] ?? '0123456789',
      address: 'Hà Nội, Việt Nam',
      summary: 'Lập trình viên Full-stack với 3+ năm kinh nghiệm phát triển ứng dụng web và mobile. Thành thạo Flutter, React, Node.js và các công nghệ hiện đại. Đam mê học hỏi công nghệ mới và giải quyết vấn đề phức tạp.',
      education: [
        Education(
          degree: 'Cử nhân Công nghệ Thông tin',
          institution: 'Đại học Bách Khoa Hà Nội',
          startDate: '2018',
          endDate: '2022',
          description: 'GPA: 3.5/4.0 - Chuyên ngành: Kỹ thuật phần mềm',
        ),
      ],
      experience: [
        Experience(
          position: 'Senior Flutter Developer',
          company: 'Tech Company ABC',
          startDate: '01/2022',
          endDate: 'Hiện tại',
          description: 'Phát triển và maintain ứng dụng mobile cho 100K+ người dùng',
          achievements: [
            'Xây dựng app từ đầu với Flutter và Firebase',
            'Tối ưu performance tăng 40%',
            'Mentor cho 3 junior developers',
          ],
        ),
        Experience(
          position: 'Junior Developer',
          company: 'Startup XYZ',
          startDate: '06/2021',
          endDate: '12/2021',
          description: 'Thực tập và phát triển web app với React',
          achievements: [
            'Phát triển 5+ features mới',
            'Tham gia code review và testing',
          ],
        ),
      ],
      skills: [
        'Flutter & Dart',
        'React & JavaScript',
        'Node.js & Express',
        'Firebase',
        'MySQL & MongoDB',
        'Git & GitHub',
        'Agile/Scrum',
      ],
      languages: [
        Language(name: 'Tiếng Việt', proficiency: 'Bản ngữ'),
        Language(name: 'Tiếng Anh', proficiency: 'TOEIC 850'),
      ],
      certifications: [
        Certification(
          name: 'Flutter Certified Developer',
          issuer: 'Google',
          date: '2023',
          credentialId: 'FLUTTER-2023-001',
        ),
      ],
      projects: [
        Project(
          name: 'E-commerce Mobile App',
          description: 'Ứng dụng mua sắm trực tuyến với 50K+ downloads',
          technologies: ['Flutter', 'Firebase', 'Stripe Payment'],
        ),
        Project(
          name: 'Task Management System',
          description: 'Hệ thống quản lý công việc cho doanh nghiệp',
          technologies: ['React', 'Node.js', 'MongoDB'],
        ),
      ],
    );
  }

  Future<void> _generateAndPreviewPDF() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _cvPdfService.generatePDF(_cvData, _selectedTemplate);
      await _cvPdfService.previewPDF(pdf);
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể tạo PDF: $e');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadPDF() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _cvPdfService.generatePDF(_cvData, _selectedTemplate);
      final filename = 'CV_${_cvData.fullName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = await _cvPdfService.savePDF(pdf, filename);

      if (mounted) {
        // Show success message with download location
        String message;
        if (Platform.isAndroid) {
          message = 'CV đã được lưu vào thư mục Downloads!\n\nFile: $filename';
        } else {
          message = 'CV đã được lưu!\n\nĐường dẫn: ${file.path}';
        }

        await SuccessDialog.show(context, message);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể lưu PDF: $e');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _sharePDF() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = await _cvPdfService.generatePDF(_cvData, _selectedTemplate);
      final filename = 'CV_${_cvData.fullName.replaceAll(' ', '_')}.pdf';
      await _cvPdfService.sharePDF(pdf, filename);
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Không thể chia sẻ PDF: $e');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTemplateSelection(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Tạo CV của bạn',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Chọn mẫu CV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTemplateOption(
                CVTemplate.modern,
                'Modern',
                'Hiện đại, màu sắc',
                Icons.auto_awesome,
              ),
              const SizedBox(width: 12),
              _buildTemplateOption(
                CVTemplate.classic,
                'Classic',
                'Truyền thống, trang nhã',
                Icons.description,
              ),
              const SizedBox(width: 12),
              _buildTemplateOption(
                CVTemplate.professional,
                'Professional',
                'Chuyên nghiệp, 2 cột',
                Icons.business_center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(
    CVTemplate template,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedTemplate == template;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTemplate = template),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667eea).withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? const Color(0xFF667eea) : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF667eea) : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Thông tin CV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Họ tên', _cvData.fullName),
          _buildInfoRow(Icons.email, 'Email', _cvData.email),
          _buildInfoRow(Icons.phone, 'Điện thoại', _cvData.phone),
          _buildInfoRow(Icons.location_on, 'Địa chỉ', _cvData.address),
          const Divider(height: 24),
          _buildInfoRow(Icons.school, 'Học vấn', '${_cvData.education.length} mục'),
          _buildInfoRow(Icons.work, 'Kinh nghiệm', '${_cvData.experience.length} mục'),
          _buildInfoRow(Icons.stars, 'Kỹ năng', '${_cvData.skills.length} kỹ năng'),
          _buildInfoRow(Icons.language, 'Ngôn ngữ', '${_cvData.languages.length} ngôn ngữ'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đây là dữ liệu mẫu. Bạn có thể chỉnh sửa trong phần Hồ sơ.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thao tác',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Preview button
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateAndPreviewPDF,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.visibility),
            label: Text(_isGenerating ? 'Đang xử lý...' : 'Xem trước CV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Download button
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _downloadPDF,
            icon: const Icon(Icons.download),
            label: const Text('Tải xuống PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Share button
          OutlinedButton.icon(
            onPressed: _isGenerating ? null : _sharePDF,
            icon: const Icon(Icons.share),
            label: const Text('Chia sẻ CV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667eea),
              side: const BorderSide(color: Color(0xFF667eea), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
