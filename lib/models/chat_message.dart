class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final String? error;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.error,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'error': error,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  error,
}

// Predefined quick responses for common queries
class QuickResponse {
  final String id;
  final String label;
  final String prompt;
  final String icon;

  const QuickResponse({
    required this.id,
    required this.label,
    required this.prompt,
    required this.icon,
  });

  static List<QuickResponse> getQuickResponses() {
    return [
      const QuickResponse(
        id: 'find_job',
        label: 'Tìm việc phù hợp',
        prompt: 'Giúp tôi tìm công việc phù hợp với kỹ năng và kinh nghiệm của tôi',
        icon: '💼',
      ),
      const QuickResponse(
        id: 'cv_tips',
        label: 'Mẹo viết CV',
        prompt: 'Cho tôi một số mẹo để viết CV thu hút nhà tuyển dụng',
        icon: '📝',
      ),
      const QuickResponse(
        id: 'interview_prep',
        label: 'Chuẩn bị phỏng vấn',
        prompt: 'Làm sao để chuẩn bị tốt cho buổi phỏng vấn xin việc?',
        icon: '🎯',
      ),
      const QuickResponse(
        id: 'salary_nego',
        label: 'Thương lượng lương',
        prompt: 'Hướng dẫn cách thương lượng mức lương khi nhận offer',
        icon: '💰',
      ),
      const QuickResponse(
        id: 'career_switch',
        label: 'Chuyển đổi nghề nghiệp',
        prompt: 'Tôi muốn chuyển sang nghề nghiệp mới, cần làm gì?',
        icon: '🔄',
      ),
      const QuickResponse(
        id: 'skills_improve',
        label: 'Nâng cao kỹ năng',
        prompt: 'Kỹ năng nào tôi nên học để tăng cơ hội việc làm?',
        icon: '📚',
      ),
    ];
  }
}
