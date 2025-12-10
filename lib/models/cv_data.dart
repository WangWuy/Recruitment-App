class CVData {
  // Personal Info
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? profileImage;
  final String? summary;

  // Education
  final List<Education> education;

  // Experience
  final List<Experience> experience;

  // Skills
  final List<String> skills;

  // Languages
  final List<Language> languages;

  // Certifications
  final List<Certification> certifications;

  // Projects (optional)
  final List<Project> projects;

  // References (optional)
  final List<Reference> references;

  CVData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.profileImage,
    this.summary,
    this.education = const [],
    this.experience = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.projects = const [],
    this.references = const [],
  });

  factory CVData.fromJson(Map<String, dynamic> json) {
    return CVData(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profileImage'],
      summary: json['summary'],
      education: (json['education'] as List?)
          ?.map((e) => Education.fromJson(e))
          .toList() ?? [],
      experience: (json['experience'] as List?)
          ?.map((e) => Experience.fromJson(e))
          .toList() ?? [],
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      languages: (json['languages'] as List?)
          ?.map((e) => Language.fromJson(e))
          .toList() ?? [],
      certifications: (json['certifications'] as List?)
          ?.map((e) => Certification.fromJson(e))
          .toList() ?? [],
      projects: (json['projects'] as List?)
          ?.map((e) => Project.fromJson(e))
          .toList() ?? [],
      references: (json['references'] as List?)
          ?.map((e) => Reference.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
      'summary': summary,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'skills': skills,
      'languages': languages.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
      'projects': projects.map((e) => e.toJson()).toList(),
      'references': references.map((e) => e.toJson()).toList(),
    };
  }
}

class Education {
  final String degree;
  final String institution;
  final String startDate;
  final String endDate;
  final String? description;

  Education({
    required this.degree,
    required this.institution,
    required this.startDate,
    required this.endDate,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      degree: json['degree'] ?? '',
      institution: json['institution'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }
}

class Experience {
  final String position;
  final String company;
  final String startDate;
  final String endDate;
  final String? description;
  final List<String> achievements;

  Experience({
    required this.position,
    required this.company,
    required this.startDate,
    required this.endDate,
    this.description,
    this.achievements = const [],
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      position: json['position'] ?? '',
      company: json['company'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'],
      achievements: (json['achievements'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'achievements': achievements,
    };
  }
}

class Language {
  final String name;
  final String proficiency; // Native, Fluent, Intermediate, Basic

  Language({
    required this.name,
    required this.proficiency,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: json['name'] ?? '',
      proficiency: json['proficiency'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'proficiency': proficiency,
    };
  }
}

class Certification {
  final String name;
  final String issuer;
  final String date;
  final String? credentialId;

  Certification({
    required this.name,
    required this.issuer,
    required this.date,
    this.credentialId,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'] ?? '',
      date: json['date'] ?? '',
      credentialId: json['credentialId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'date': date,
      'credentialId': credentialId,
    };
  }
}

class Project {
  final String name;
  final String description;
  final String? link;
  final List<String> technologies;

  Project({
    required this.name,
    required this.description,
    this.link,
    this.technologies = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      link: json['link'],
      technologies: (json['technologies'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'link': link,
      'technologies': technologies,
    };
  }
}

class Reference {
  final String name;
  final String position;
  final String company;
  final String phone;
  final String email;

  Reference({
    required this.name,
    required this.position,
    required this.company,
    required this.phone,
    required this.email,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      company: json['company'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': position,
      'company': company,
      'phone': phone,
      'email': email,
    };
  }
}
