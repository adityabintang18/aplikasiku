// Update profile parameters entity
import 'dart:convert';

/// Parameters for updating user profile
class UpdateProfileParams {
  final String? name;
  final String? phone;
  final String? photoUrl;
  final Map<String, dynamic>? metadata;

  const UpdateProfileParams({
    this.name,
    this.phone,
    this.photoUrl,
    this.metadata,
  });

  /// Check if any field needs updating
  bool get hasChanges =>
      name != null || phone != null || photoUrl != null || metadata != null;

  /// Validate parameters
  bool get isValid {
    if (!hasChanges) return false;

    if (name != null && (name!.isEmpty || name!.length < 2)) {
      return false;
    }

    if (phone != null && phone!.isNotEmpty && phone!.length < 10) {
      return false;
    }

    return true;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (name != null) {
      if (name!.isEmpty) {
        errors.add('Name cannot be empty');
      } else if (name!.length < 2) {
        errors.add('Name must be at least 2 characters');
      }
    }

    if (phone != null && phone!.isNotEmpty && phone!.length < 10) {
      errors.add('Phone number must be at least 10 digits');
    }

    if (!hasChanges) {
      errors.add('At least one field must be provided for update');
    }

    return errors;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create from JSON
  factory UpdateProfileParams.fromJson(Map<String, dynamic> json) {
    return UpdateProfileParams(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create copy with updated fields
  UpdateProfileParams copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return UpdateProfileParams(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UpdateProfileParams(name: $name, phone: $phone, photoUrl: $photoUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateProfileParams &&
        other.name == name &&
        other.phone == phone &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return name.hashCode ^ phone.hashCode ^ photoUrl.hashCode;
  }
}
