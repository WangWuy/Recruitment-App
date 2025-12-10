import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../providers/simple_auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/error_dialog.dart';
import '../widgets/success_dialog.dart';
import 'dart:io';

class NewsEditorScreen extends StatefulWidget {
  final NewsArticle? article; // null for new article, non-null for editing

  const NewsEditorScreen({super.key, this.article});

  @override
  State<NewsEditorScreen> createState() => _NewsEditorScreenState();
}

class _NewsEditorScreenState extends State<NewsEditorScreen> {
  final HtmlEditorController _editorController = HtmlEditorController();
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  File? _thumbnailFile;
  String? _existingThumbnail;
  bool _isPublished = true;
  bool _isFeatured = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  void _initializeEditor() {
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _excerptController.text = widget.article!.excerpt ?? '';
      _selectedCategory = widget.article!.category;
      _existingThumbnail = widget.article!.thumbnail;
      _isPublished = widget.article!.isPublished;
      _isFeatured = widget.article!.isFeatured;

      // Set HTML content after editor is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editorController.setText(widget.article!.content);
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _thumbnailFile = File(image.path);
      });
    }
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<SimpleAuthProvider>();
    final token = auth.token;
    if (token == null) {
      if (mounted) {
        ErrorDialog.show(context, 'Bạn cần đăng nhập để thực hiện thao tác này.');
      }
      return;
    }

    setState(() => _loading = true);

    try {
      // Get HTML content from editor
      final htmlContent = await _editorController.getText();
      if (htmlContent.isEmpty) {
        if (mounted) {
          ErrorDialog.show(context, 'Nội dung bài viết không được để trống.');
        }
        setState(() => _loading = false);
        return;
      }

      // Prepare article data
      final articleData = {
        'title': _titleController.text.trim(),
        'content': htmlContent,
        'excerpt': _excerptController.text.trim(),
        'category': _selectedCategory,
        'is_published': _isPublished ? 1 : 0,
        'is_featured': _isFeatured ? 1 : 0,
      };

      String? thumbnailUrl;

      // Upload thumbnail if selected
      if (_thumbnailFile != null) {
        thumbnailUrl = await ApiService.uploadImage(_thumbnailFile!, token);
        articleData['thumbnail'] = thumbnailUrl;
      } else if (_existingThumbnail != null) {
        articleData['thumbnail'] = _existingThumbnail;
      }

      // Create or update article
      if (widget.article == null) {
        // Create new article
        await ApiService.createNewsArticle(articleData, token);
        if (mounted) {
          await SuccessDialog.show(
            context,
            'Bài viết đã được tạo thành công!',
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        // Update existing article
        await ApiService.updateNewsArticle(widget.article!.id, articleData, token);
        if (mounted) {
          await SuccessDialog.show(
            context,
            'Bài viết đã được cập nhật thành công!',
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article == null ? 'Tạo tin tức mới' : 'Chỉnh sửa tin tức'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveArticle,
              tooltip: 'Lưu bài viết',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài viết *',
                        hintText: 'Nhập tiêu đề hấp dẫn',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        if (value.trim().length < 10) {
                          return 'Tiêu đề phải có ít nhất 10 ký tự';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: NewsCategory.getAllCategories().map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn danh mục';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Excerpt
                    TextFormField(
                      controller: _excerptController,
                      decoration: const InputDecoration(
                        labelText: 'Tóm tắt (tùy chọn)',
                        hintText: 'Mô tả ngắn gọn về bài viết',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.short_text),
                      ),
                      maxLines: 3,
                      maxLength: 300,
                    ),

                    const SizedBox(height: 16),

                    // Thumbnail
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image, color: Color(0xFF667eea)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ảnh đại diện',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _pickThumbnail,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Chọn ảnh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667eea),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_thumbnailFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _thumbnailFile!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (_existingThumbnail != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingThumbnail!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 50),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[400]!),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined,
                                          size: 50, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Chưa có ảnh đại diện',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // HTML Editor
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.edit_document,
                                    color: Color(0xFF667eea)),
                                SizedBox(width: 8),
                                Text(
                                  'Nội dung bài viết *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 500,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: HtmlEditor(
                                controller: _editorController,
                                htmlEditorOptions: const HtmlEditorOptions(
                                  hint: 'Nhập nội dung bài viết tại đây...',
                                  shouldEnsureVisible: true,
                                  autoAdjustHeight: false,
                                ),
                                htmlToolbarOptions: const HtmlToolbarOptions(
                                  toolbarPosition: ToolbarPosition.aboveEditor,
                                  toolbarType: ToolbarType.nativeScrollable,
                                  defaultToolbarButtons: [
                                    StyleButtons(),
                                    FontSettingButtons(),
                                    FontButtons(),
                                    ColorButtons(),
                                    ListButtons(),
                                    ParagraphButtons(),
                                    InsertButtons(
                                      otherFile: false,
                                      video: false,
                                      audio: false,
                                    ),
                                    OtherButtons(
                                      fullscreen: false,
                                      codeview: true,
                                      help: false,
                                      copy: true,
                                      paste: true,
                                    ),
                                  ],
                                ),
                                otherOptions: const OtherOptions(
                                  height: 450,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Publishing options
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.settings, color: Color(0xFF667eea)),
                                SizedBox(width: 8),
                                Text(
                                  'Tùy chọn xuất bản',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Xuất bản ngay'),
                              subtitle: const Text(
                                  'Bài viết sẽ hiển thị công khai sau khi lưu'),
                              value: _isPublished,
                              activeColor: const Color(0xFF667eea),
                              onChanged: (value) {
                                setState(() => _isPublished = value);
                              },
                            ),
                            SwitchListTile(
                              title: const Text('Bài viết nổi bật'),
                              subtitle: const Text(
                                  'Hiển thị ở vị trí ưu tiên trên trang chủ'),
                              value: _isFeatured,
                              activeColor: const Color(0xFF667eea),
                              onChanged: (value) {
                                setState(() => _isFeatured = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _saveArticle,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.article == null
                            ? 'Tạo bài viết'
                            : 'Cập nhật bài viết',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
