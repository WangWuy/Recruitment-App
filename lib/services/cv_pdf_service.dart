import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cv_data.dart';

enum CVTemplate {
  modern,
  classic,
  professional,
}

class CVPdfService {
  // Cache fonts
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _mediumFont;

  // Load Vietnamese-compatible fonts
  Future<void> _loadFonts() async {
  if (_regularFont != null) return;

  // Load từ assets
  final regularData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
  final boldData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
  final mediumData = await rootBundle.load('assets/fonts/Poppins-Medium.ttf');

  // Thử ưu tiên cách đơn giản (ByteData) — nhiều phiên bản pdf/widgets chấp nhận ByteData trực tiếp
  try {
    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
    _mediumFont = pw.Font.ttf(mediumData);
    return;
  } catch (_) {
    // ignore and try next
  }

  // Thử truyền Uint8List (một số phiên bản yêu cầu Uint8List)
  try {
    _regularFont = pw.Font.ttf(regularData.buffer.asUint8List() as ByteData);
    _boldFont = pw.Font.ttf(boldData.buffer.asUint8List() as ByteData);
    _mediumFont = pw.Font.ttf(mediumData.buffer.asUint8List() as ByteData);
    return;
  } catch (_) {
    // ignore and try next
  }

  // Thử ByteData.view (dành cho edge-cases)
  try {
    _regularFont = pw.Font.ttf(ByteData.view(regularData.buffer));
    _boldFont = pw.Font.ttf(ByteData.view(boldData.buffer));
    _mediumFont = pw.Font.ttf(ByteData.view(mediumData.buffer));
    return;
  } catch (e) {
    // Nếu tới đây vẫn lỗi, throw với thông tin rõ ràng để debug
    throw Exception('Không thể nạp font. Thử kiểm tra assets/fonts và phiên bản package pdf/widgets. Chi tiết: $e');
  }
}


  // Generate PDF from CV data
  Future<pw.Document> generatePDF(CVData cvData, CVTemplate template) async {
    // Load fonts first
    await _loadFonts();

    final pdf = pw.Document();

    switch (template) {
      case CVTemplate.modern:
        await _buildModernTemplate(pdf, cvData);
        break;
      case CVTemplate.classic:
        await _buildClassicTemplate(pdf, cvData);
        break;
      case CVTemplate.professional:
        await _buildProfessionalTemplate(pdf, cvData);
        break;
    }

    return pdf;
  }

  // Save PDF to device Downloads folder
  Future<File> savePDF(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();

    // Request storage permission for Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try manageExternalStorage for Android 11+
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          throw Exception('Cần cấp quyền truy cập bộ nhớ để lưu file');
        }
      }
    }

    // Get Downloads directory
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir!.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Preview PDF
  Future<void> previewPDF(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Share PDF
  Future<void> sharePDF(pw.Document pdf, String filename) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: filename,
    );
  }

  // Print PDF
  Future<void> printPDF(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Helper method to create TextStyle with Vietnamese font
  pw.TextStyle _textStyle({
    double? fontSize,
    PdfColor? color,
    bool bold = false,
    double? lineSpacing,
  }) {
    return pw.TextStyle(
      font: bold ? _boldFont : _regularFont,
      fontSize: fontSize,
      color: color,
      lineSpacing: lineSpacing,
    );
  }

  // ===== MODERN TEMPLATE =====
  Future<void> _buildModernTemplate(pw.Document pdf, CVData cvData) async {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) => [
          // Header with name and contact
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [PdfColors.blue700, PdfColors.blue400],
              ),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cvData.fullName,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    _buildContactItem('📧', cvData.email),
                    pw.SizedBox(width: 20),
                    _buildContactItem('📱', cvData.phone),
                  ],
                ),
                pw.SizedBox(height: 4),
                _buildContactItem('📍', cvData.address),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary
          if (cvData.summary != null && cvData.summary!.isNotEmpty) ...[
            _buildSectionTitle('Mục tiêu nghề nghiệp', PdfColors.blue700),
            pw.SizedBox(height: 8),
            pw.Text(
              cvData.summary!,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
            pw.SizedBox(height: 20),
          ],

          // Experience
          if (cvData.experience.isNotEmpty) ...[
            _buildSectionTitle('Kinh nghiệm làm việc', PdfColors.blue700),
            pw.SizedBox(height: 12),
            ...cvData.experience.map((exp) => _buildExperienceItem(exp)),
          ],

          // Education
          if (cvData.education.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Học vấn', PdfColors.blue700),
            pw.SizedBox(height: 12),
            ...cvData.education.map((edu) => _buildEducationItem(edu)),
          ],

          // Skills
          if (cvData.skills.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Kỹ năng', PdfColors.blue700),
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cvData.skills
                  .map((skill) => _buildSkillChip(skill, PdfColors.blue700))
                  .toList(),
            ),
          ],

          // Languages
          if (cvData.languages.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Ngôn ngữ', PdfColors.blue700),
            pw.SizedBox(height: 12),
            ...cvData.languages.map((lang) => _buildLanguageItem(lang)),
          ],

          // Certifications
          if (cvData.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Chứng chỉ', PdfColors.blue700),
            pw.SizedBox(height: 12),
            ...cvData.certifications
                .map((cert) => _buildCertificationItem(cert)),
          ],

          // Projects
          if (cvData.projects.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Dự án', PdfColors.blue700),
            pw.SizedBox(height: 12),
            ...cvData.projects.map((project) => _buildProjectItem(project)),
          ],
        ],
      ),
    );
  }

  // ===== CLASSIC TEMPLATE =====
  Future<void> _buildClassicTemplate(pw.Document pdf, CVData cvData) async {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) => [
          // Header - Classic Style
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  cvData.fullName,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${cvData.email} • ${cvData.phone}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  cvData.address,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Summary
          if (cvData.summary != null && cvData.summary!.isNotEmpty) ...[
            _buildSectionTitle('MỤC TIÊU NGHỀ NGHIỆP', PdfColors.black),
            pw.SizedBox(height: 8),
            pw.Text(
              cvData.summary!,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 16),
          ],

          // Experience
          if (cvData.experience.isNotEmpty) ...[
            _buildSectionTitle('KINH NGHIỆM LÀM VIỆC', PdfColors.black),
            pw.SizedBox(height: 12),
            ...cvData.experience.map((exp) => _buildExperienceItemClassic(exp)),
          ],

          // Education
          if (cvData.education.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('HỌC VẤN', PdfColors.black),
            pw.SizedBox(height: 12),
            ...cvData.education.map((edu) => _buildEducationItemClassic(edu)),
          ],

          // Skills
          if (cvData.skills.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('KỸ NĂNG', PdfColors.black),
            pw.SizedBox(height: 8),
            pw.Bullet(
              text: cvData.skills.join(' • '),
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],

          // Languages
          if (cvData.languages.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('NGÔN NGỮ', PdfColors.black),
            pw.SizedBox(height: 8),
            ...cvData.languages.map((lang) => pw.Bullet(
                  text: '${lang.name}: ${lang.proficiency}',
                  style: const pw.TextStyle(fontSize: 11),
                )),
          ],

          // Certifications
          if (cvData.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('CHỨNG CHỈ', PdfColors.black),
            pw.SizedBox(height: 12),
            ...cvData.certifications
                .map((cert) => _buildCertificationItemClassic(cert)),
          ],
        ],
      ),
    );
  }

  // ===== PROFESSIONAL TEMPLATE =====
  Future<void> _buildProfessionalTemplate(
      pw.Document pdf, CVData cvData) async {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: _regularFont,
          bold: _boldFont,
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Column (40%)
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  color: PdfColors.grey300,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Contact Info
                      pw.Text(
                        'LIÊN HỆ',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildContactItemProfessional('📧', cvData.email),
                      pw.SizedBox(height: 8),
                      _buildContactItemProfessional('📱', cvData.phone),
                      pw.SizedBox(height: 8),
                      _buildContactItemProfessional('📍', cvData.address),
                      pw.SizedBox(height: 20),

                      // Skills
                      if (cvData.skills.isNotEmpty) ...[
                        pw.Text(
                          'KỸ NĂNG',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        ...cvData.skills.map((skill) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Text(
                                '• $skill',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            )),
                        pw.SizedBox(height: 20),
                      ],

                      // Languages
                      if (cvData.languages.isNotEmpty) ...[
                        pw.Text(
                          'NGÔN NGỮ',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        ...cvData.languages.map((lang) => pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 6),
                              child: pw.Text(
                                '${lang.name}\n${lang.proficiency}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),

              pw.SizedBox(width: 20),

              // Right Column (60%)
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Name
                    pw.Text(
                      cvData.fullName,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: 60,
                      height: 3,
                      color: PdfColors.grey800,
                    ),
                    pw.SizedBox(height: 20),

                    // Summary
                    if (cvData.summary != null &&
                        cvData.summary!.isNotEmpty) ...[
                      pw.Text(
                        cvData.summary!,
                        style:
                            const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 20),
                    ],

                    // Experience
                    if (cvData.experience.isNotEmpty) ...[
                      pw.Text(
                        'KINH NGHIỆM LÀM VIỆC',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...cvData.experience
                          .map((exp) => _buildExperienceItemProfessional(exp)),
                    ],

                    // Education
                    if (cvData.education.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'HỌC VẤN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...cvData.education
                          .map((edu) => _buildEducationItemProfessional(edu)),
                    ],

                    // Certifications
                    if (cvData.certifications.isNotEmpty) ...[
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'CHỨNG CHỈ',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      ...cvData.certifications.map(
                          (cert) => _buildCertificationItemProfessional(cert)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== HELPER METHODS =====

  pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    );
  }

  pw.Widget _buildContactItem(String label, String text) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label, // ví dụ label = 'Email:' thay vì '📧'
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
        ),
        pw.SizedBox(width: 6),
        pw.Text(text,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
      ],
    );
  }

  pw.Widget _buildContactItemProfessional(String symbol, String text) {
    return pw.Row(
      children: [
        pw.Text(
          symbol,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExperienceItem(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                exp.position,
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${exp.startDate} - ${exp.endDate}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            exp.company,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              exp.description!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (exp.achievements.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            ...exp.achievements.map((achievement) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
                  child: pw.Bullet(
                      text: achievement,
                      style: const pw.TextStyle(fontSize: 10)),
                )),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildExperienceItemClassic(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${exp.position} - ${exp.company}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${exp.startDate} - ${exp.endDate}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (exp.description != null && exp.description!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(exp.description!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildExperienceItemProfessional(Experience exp) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            exp.position,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${exp.company} | ${exp.startDate} - ${exp.endDate}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (exp.description != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(exp.description!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducationItem(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                edu.degree,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${edu.startDate} - ${edu.endDate}',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            edu.institution,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          if (edu.description != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(edu.description!, style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEducationItemClassic(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${edu.degree} - ${edu.institution}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${edu.startDate} - ${edu.endDate}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEducationItemProfessional(Education edu) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            edu.degree,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${edu.institution} | ${edu.startDate} - ${edu.endDate}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSkillChip(String skill, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(15),
      ),
      child: pw.Text(
        skill,
        style: pw.TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  pw.Widget _buildLanguageItem(Language lang) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(lang.name, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            lang.proficiency,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationItem(Certification cert) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            cert.name,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${cert.issuer} - ${cert.date}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          if (cert.credentialId != null) ...[
            pw.Text(
              'ID: ${cert.credentialId}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildCertificationItemClassic(Certification cert) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${cert.name} - ${cert.issuer}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            cert.date,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCertificationItemProfessional(Certification cert) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            cert.name,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${cert.issuer} | ${cert.date}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjectItem(Project project) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            project.name,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            project.description,
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (project.technologies.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Technologies: ${project.technologies.join(", ")}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }
}
