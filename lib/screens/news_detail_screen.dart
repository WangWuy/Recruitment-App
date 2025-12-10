import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../providers/simple_auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/error_dialog.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _loading = true;
  NewsArticle? _article;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    setState(() => _loading = true);
    try {
      // Increment view count
      await ApiService.incrementNewsViews(widget.article.id);

      // Reload article to get updated view count
      final updatedArticle = await ApiService.getNewsArticle(widget.article.id);

      if (mounted) {
        setState(() {
          _article = updatedArticle;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _article = widget.article;
          _loading = false;
        });
      }
    }
  }

  Future<void> _shareArticle() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chia sẻ đang phát triển')),
    );
  }

  Future<void> _editArticle() async {
    final result = await Navigator.pushNamed(
      context,
      '/news_editor',
      arguments: _article,
    );

    if (result == true && mounted) {
      // Reload article after editing
      _loadArticle();
    }
  }

  Future<void> _deleteArticle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final auth = context.read<SimpleAuthProvider>();
      final token = auth.token;
      if (token == null) {
        if (mounted) {
          ErrorDialog.show(context, 'Bạn cần đăng nhập để thực hiện thao tác này.');
        }
        return;
      }

      await ApiService.deleteNewsArticle(_article!.id, token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài viết đã được xóa')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Lỗi: ${e.toString()}');
      }
    }
  }

  bool _canEdit() {
    final auth = context.read<SimpleAuthProvider>();
    final user = auth.user;
    final role = user?['role'];
    return role == 'admin' || (_article != null && user?['id'] == _article!.authorId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_article == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Không tìm thấy bài viết'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArticle,
            tooltip: 'Chia sẻ',
          ),
          if (_canEdit())
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editArticle();
                } else if (value == 'delete') {
                  _deleteArticle();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (_article!.thumbnail != null)
              Image.network(
                _article!.thumbnail!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (_article!.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        NewsCategory.getDisplayName(_article!.category!),
                        style: const TextStyle(
                          color: Color(0xFF667eea),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _article!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Metadata row
                  Row(
                    children: [
                      // Author
                      if (_article!.authorName != null) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF667eea),
                          child: Text(
                            _article!.authorName![0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _article!.authorName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Date
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _article!.getFormattedDate(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Views
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_article!.views} lượt xem',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Reading time
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_article!.getReadingTimeMinutes()} phút đọc',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Divider(color: Colors.grey[300]),

                  const SizedBox(height: 20),

                  // HTML Content
                  Html(
                    data: _article!.content,
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                        color: const Color(0xFF2D3748),
                      ),
                      'h1': Style(
                        fontSize: FontSize(28),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 20, bottom: 10),
                        color: const Color(0xFF2D3748),
                      ),
                      'h2': Style(
                        fontSize: FontSize(24),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 18, bottom: 8),
                        color: const Color(0xFF2D3748),
                      ),
                      'h3': Style(
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 16, bottom: 8),
                        color: const Color(0xFF2D3748),
                      ),
                      'p': Style(
                        fontSize: FontSize(16),
                        lineHeight: const LineHeight(1.6),
                        margin: Margins.only(bottom: 12),
                      ),
                      'a': Style(
                        color: const Color(0xFF667eea),
                        textDecoration: TextDecoration.underline,
                      ),
                      'img': Style(
                        width: Width(double.infinity),
                        margin: Margins.symmetric(vertical: 12),
                      ),
                      'blockquote': Style(
                        border: const Border(
                          left: BorderSide(
                            color: Color(0xFF667eea),
                            width: 4,
                          ),
                        ),
                        padding: HtmlPaddings.only(left: 16),
                        margin: Margins.symmetric(vertical: 12),
                        backgroundColor: Colors.grey[100],
                      ),
                      'code': Style(
                        backgroundColor: Colors.grey[200],
                        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                        fontFamily: 'monospace',
                      ),
                      'pre': Style(
                        backgroundColor: Colors.grey[200],
                        padding: HtmlPaddings.all(12),
                        margin: Margins.symmetric(vertical: 12),
                        fontFamily: 'monospace',
                      ),
                      'ul': Style(
                        margin: Margins.only(bottom: 12),
                        padding: HtmlPaddings.only(left: 20),
                      ),
                      'ol': Style(
                        margin: Margins.only(bottom: 12),
                        padding: HtmlPaddings.only(left: 20),
                      ),
                      'li': Style(
                        margin: Margins.only(bottom: 6),
                      ),
                    },
                    onLinkTap: (url, attributes, element) async {
                      if (url != null) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
