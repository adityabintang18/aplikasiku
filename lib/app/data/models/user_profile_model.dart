/// User profile model for handling user data
class UserProfile {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photoUrl: json['photo_url'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  factory UserProfile.demoUser() {
    return UserProfile(
      name: 'Demo User',
      email: 'demo@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo_url': photoUrl,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
