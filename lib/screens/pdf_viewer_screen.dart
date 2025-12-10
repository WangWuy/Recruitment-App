import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';

String _normalizeUrl(String url) {
  // Nếu URL đã có scheme (http:// hoặc https://) thì return luôn
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Nếu là đường dẫn tương đối, thêm base URL
  final baseUrl = AppConstants.apiBaseUrl;

  // Xóa /api nếu có trong base URL vì uploads không nằm trong /api
  String cleanBaseUrl = baseUrl;
  if (cleanBaseUrl.endsWith('/api')) {
    cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 4);
  }

  // Đảm bảo không có double slash
  if (url.startsWith('/')) {
    return '$cleanBaseUrl$url';
  } else {
    return '$cleanBaseUrl/$url';
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title = 'Xem CV',
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int totalPages = 0;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    print('=== PDF VIEWER INIT ===');
    print('PDF URL (original): ${widget.pdfUrl}');
    _downloadAndOpenPdf();
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      print('=== DOWNLOADING PDF ===');
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Normalize URL
      final normalizedUrl = _normalizeUrl(widget.pdfUrl);
      print('Original URL: ${widget.pdfUrl}');
      print('Normalized URL: $normalizedUrl');

      print('Parsing URL: $normalizedUrl');
      final uri = Uri.parse(normalizedUrl);
      print('Parsed URI: $uri');
      print('URI scheme: ${uri.scheme}');
      print('URI host: ${uri.host}');
      print('URI path: ${uri.path}');

      // Download PDF file
      print('Sending HTTP GET request...');
      final response = await http.get(uri);
      print('Response status code: ${response.statusCode}');
      print('Response content length: ${response.bodyBytes.length}');
      print('Response content type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        // Get temporary directory
        print('Getting temporary directory...');
        final dir = await getTemporaryDirectory();
        print('Temp directory: ${dir.path}');

        final file = File('${dir.path}/temp_cv.pdf');
        print('Saving to file: ${file.path}');

        // Write PDF to file
        await file.writeAsBytes(response.bodyBytes);
        print('File saved successfully');
        print('File size: ${await file.length()} bytes');
        print('File exists: ${await file.exists()}');

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
        print('PDF loaded successfully: $localPath');
      } else {
        print('ERROR: HTTP ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          errorMessage = 'Không thể tải file PDF. Mã lỗi: ${response.statusCode}\nURL: ${widget.pdfUrl}';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('ERROR downloading PDF: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        errorMessage = 'Lỗi khi tải file PDF: $e\nURL: ${widget.pdfUrl}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${currentPage + 1}/$totalPages',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải file PDF...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _downloadAndOpenPdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : localPath != null
                  ? PDFView(
                      filePath: localPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      onRender: (pages) {
                        setState(() {
                          totalPages = pages ?? 0;
                        });
                      },
                      onPageChanged: (page, total) {
                        setState(() {
                          currentPage = page ?? 0;
                        });
                      },
                      onError: (error) {
                        setState(() {
                          errorMessage = 'Lỗi khi hiển thị PDF: $error';
                        });
                      },
                    )
                  : const Center(
                      child: Text(
                        'Không có file PDF để hiển thị',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: AppColors.textGray,
                        ),
                      ),
                    ),
    );
  }
}
