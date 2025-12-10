class NewsArticle {
  final int id;
  final String title;
  final String content; // HTML content
  final String? excerpt;
  final String? thumbnail;
  final String? category;
  final int authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int views;
  final bool isPublished;
  final bool isFeatured;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    this.thumbnail,
    this.category,
    required this.authorId,
    this.authorName,
    required this.createdAt,
    this.updatedAt,
    this.views = 0,
    this.isPublished = true,
    this.isFeatured = false,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      excerpt: json['excerpt'],
      thumbnail: json['thumbnail'],
      category: json['category'],
      authorId: json['author_id'] is int
          ? json['author_id']
          : int.parse(json['author_id'].toString()),
      authorName: json['author_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      views: json['views'] is int ? json['views'] : int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'thumbnail': thumbnail,
      'category': category,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'views': views,
      'is_published': isPublished ? 1 : 0,
      'is_featured': isFeatured ? 1 : 0,
    };
  }

  // Create a copy with updated fields
  NewsArticle copyWith({
    int? id,
    String? title,
    String? content,
    String? excerpt,
    String? thumbnail,
    String? category,
    int? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? views,
    bool? isPublished,
    bool? isFeatured,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      thumbnail: thumbnail ?? this.thumbnail,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // Generate excerpt from HTML content if not provided
  String getExcerpt({int maxLength = 200}) {
    if (excerpt != null && excerpt!.isNotEmpty) {
      return excerpt!;
    }

    // Strip HTML tags for excerpt
    String plainText = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (plainText.length <= maxLength) {
      return plainText;
    }

    return '${plainText.substring(0, maxLength)}...';
  }

  // Format date for display
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Get reading time estimate (based on 200 words per minute)
  int getReadingTimeMinutes() {
    String plainText = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    int wordCount = plainText.split(' ').length;
    int readingTime = (wordCount / 200).ceil();

    return readingTime < 1 ? 1 : readingTime;
  }
}

// News categories
class NewsCategory {
  static const String careerAdvice = 'career_advice';
  static const String industryNews = 'industry_news';
  static const String companySpotlight = 'company_spotlight';
  static const String interviewTips = 'interview_tips';
  static const String salaryInsights = 'salary_insights';
  static const String workLifeBalance = 'work_life_balance';
  static const String skillDevelopment = 'skill_development';
  static const String jobMarketTrends = 'job_market_trends';

  static String getDisplayName(String category) {
    switch (category) {
      case careerAdvice:
        return 'Tư vấn nghề nghiệp';
      case industryNews:
        return 'Tin tức ngành';
      case companySpotlight:
        return 'Điểm tin doanh nghiệp';
      case interviewTips:
        return 'Mẹo phỏng vấn';
      case salaryInsights:
        return 'Thông tin lương';
      case workLifeBalance:
        return 'Cân bằng công việc';
      case skillDevelopment:
        return 'Phát triển kỹ năng';
      case jobMarketTrends:
        return 'Xu hướng thị trường';
      default:
        return 'Tin tức';
    }
  }

  static List<Map<String, String>> getAllCategories() {
    return [
      {'value': careerAdvice, 'label': 'Tư vấn nghề nghiệp'},
      {'value': industryNews, 'label': 'Tin tức ngành'},
      {'value': companySpotlight, 'label': 'Điểm tin doanh nghiệp'},
      {'value': interviewTips, 'label': 'Mẹo phỏng vấn'},
      {'value': salaryInsights, 'label': 'Thông tin lương'},
      {'value': workLifeBalance, 'label': 'Cân bằng công việc'},
      {'value': skillDevelopment, 'label': 'Phát triển kỹ năng'},
      {'value': jobMarketTrends, 'label': 'Xu hướng thị trường'},
    ];
  }
}
