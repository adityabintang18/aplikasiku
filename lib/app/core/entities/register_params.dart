// Register parameters entity
import 'dart:convert';

/// Parameters for user registration
class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String? phone;
  final Map<String, dynamic>? metadata;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
    this.metadata,
  });

  /// Validate registration parameters
  bool get isValid {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        password.isNotEmpty &&
        password.length >= 6 &&
        password == passwordConfirmation;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Name is required');
    } else if (name.length < 2) {
      errors.add('Name must be at least 2 characters');
    }

    if (email.isEmpty) {
      errors.add('Email is required');
    } else if (!email.contains('@')) {
      errors.add('Email must be valid');
    }

    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    if (passwordConfirmation.isEmpty) {
      errors.add('Password confirmation is required');
    } else if (password != passwordConfirmation) {
      errors.add('Passwords do not match');
    }

    return errors;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'phone': phone,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory RegisterParams.fromJson(Map<String, dynamic> json) {
    return RegisterParams(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      passwordConfirmation: json['password_confirmation'] as String,
      phone: json['phone'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Create copy with updated fields
  RegisterParams copyWith({
    String? name,
    String? email,
    String? password,
    String? passwordConfirmation,
    String? phone,
    Map<String, dynamic>? metadata,
  }) {
    return RegisterParams(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirmation: passwordConfirmation ?? this.passwordConfirmation,
      phone: phone ?? this.phone,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'RegisterParams(name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterParams &&
        other.name == name &&
        other.email == email;
  }

  @override
  int get hashCode {
    return name.hashCode ^ email.hashCode;
  }
}
