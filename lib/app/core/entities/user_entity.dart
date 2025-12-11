// User entity
import 'dart:convert';

/// User entity representing a user in the system
class UserEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a UserEntity with required fields only
  factory UserEntity.withRequiredFields({
    required int id,
    required String name,
    required String email,
  }) {
    final now = DateTime.now();
    return UserEntity(
      id: id,
      name: name,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create UserEntity from JSON
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      profilePicture: json['profile_picture'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Create UserEntity from API response
  factory UserEntity.fromApiResponse(Map<String, dynamic> response) {
    return UserEntity.fromJson(response);
  }

  /// Convert UserEntity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode;
}
