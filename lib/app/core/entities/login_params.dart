// Login parameters entity
import 'base_params.dart';

/// Parameters for login operation
class LoginParams extends BaseParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  /// Create LoginParams from JSON
  factory LoginParams.fromJson(Map<String, dynamic> json) {
    return LoginParams(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  /// Convert LoginParams to JSON
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  /// Create a copy with updated values
  LoginParams copyWith({String? email, String? password}) {
    return LoginParams(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];

    // Email validation
    if (email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(email)) {
      errors.add('Please enter a valid email address');
    }

    // Password validation
    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    return errors;
  }

  /// Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  bool get isValid => validationErrors.isEmpty;

  @override
  String toString() {
    return 'LoginParams(email: $email, password: ${password.isNotEmpty ? '***' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginParams &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;
}
