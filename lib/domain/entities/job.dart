class Job {
  final int id;
  final int companyId;
  final String title;
  final String? description;
  final String? requirements;
  final String? location;
  final int salaryMin;
  final int salaryMax;
  final int? categoryId;
  final String status;
  final int? createdBy;
  final DateTime createdAt;
  final String? companyName;

  const Job({
    required this.id,
    required this.companyId,
    required this.title,
    this.description,
    this.requirements,
    this.location,
    required this.salaryMin,
    required this.salaryMax,
    this.categoryId,
    required this.status,
    this.createdBy,
    required this.createdAt,
    this.companyName,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      requirements: json['requirements'] as String?,
      location: json['location'] as String?,
      salaryMin: json['salary_min'] as int,
      salaryMax: json['salary_max'] as int,
      categoryId: json['category_id'] as int?,
      status: json['status'] as String,
      createdBy: json['created_by'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      companyName: json['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'title': title,
      'description': description,
      'requirements': requirements,
      'location': location,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'category_id': categoryId,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'company_name': companyName,
    };
  }

  Job copyWith({
    int? id,
    int? companyId,
    String? title,
    String? description,
    String? requirements,
    String? location,
    int? salaryMin,
    int? salaryMax,
    int? categoryId,
    String? status,
    int? createdBy,
    DateTime? createdAt,
    String? companyName,
  }) {
    return Job(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      location: location ?? this.location,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      companyName: companyName ?? this.companyName,
    );
  }
}
