import 'package:flutter/material.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final _newsService = NewsService();
  
  List<Map<String, dynamic>> _news = [];
  List<String> _categories = ['Tất cả'];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get news => _news;
  List<String> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCategories() async {
    try {
      final categories = await _newsService.getCategories();
      _categories = ['Tất cả', ...categories];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadNews({
    String? category,
    String? keyword,
    int page = 1,
    int limit = 10,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final news = await _newsService.getNews(
        category: category,
        keyword: keyword,
        page: page,
        limit: limit,
      );
      
      _news = news;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getNewsById(int newsId) async {
    try {
      return await _newsService.getNewsById(newsId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
