class Application {
  final int id;
  final int jobId;
  final int userId;
  final String status;
  final String? note;
  final DateTime createdAt;
  final String? candidateName;
  final String? jobTitle;

  const Application({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.status,
    this.note,
    required this.createdAt,
    this.candidateName,
    this.jobTitle,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      jobId: json['job_id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      candidateName: json['candidate_name'] as String?,
      jobTitle: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'user_id': userId,
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'candidate_name': candidateName,
      'title': jobTitle,
    };
  }

  Application copyWith({
    int? id,
    int? jobId,
    int? userId,
    String? status,
    String? note,
    DateTime? createdAt,
    String? candidateName,
    String? jobTitle,
  }) {
    return Application(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      candidateName: candidateName ?? this.candidateName,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}
