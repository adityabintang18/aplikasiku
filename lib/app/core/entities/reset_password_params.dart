// Reset password parameters entity
import 'dart:convert';

/// Parameters for resetting password with token
class ResetPasswordParams {
  final String email;
  final String token;
  final String newPassword;
  final String newPasswordConfirmation;

  const ResetPasswordParams({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  /// Validate reset password parameters
  bool get isValid {
    return email.isNotEmpty &&
        email.contains('@') &&
        token.isNotEmpty &&
        newPassword.isNotEmpty &&
        newPassword.length >= 6 &&
        newPassword == newPasswordConfirmation;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (email.isEmpty) {
      errors.add('Email is required');
    } else if (!email.contains('@')) {
      errors.add('Email must be valid');
    }

    if (token.isEmpty) {
      errors.add('Reset token is required');
    }

    if (newPassword.isEmpty) {
      errors.add('New password is required');
    } else if (newPassword.length < 6) {
      errors.add('New password must be at least 6 characters');
    }

    if (newPasswordConfirmation.isEmpty) {
      errors.add('Password confirmation is required');
    } else if (newPassword != newPasswordConfirmation) {
      errors.add('Passwords do not match');
    }

    return errors;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'token': token,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    };
  }

  /// Create from JSON
  factory ResetPasswordParams.fromJson(Map<String, dynamic> json) {
    return ResetPasswordParams(
      email: json['email'] as String,
      token: json['token'] as String,
      newPassword: json['new_password'] as String,
      newPasswordConfirmation: json['new_password_confirmation'] as String,
    );
  }

  /// Create copy with updated fields
  ResetPasswordParams copyWith({
    String? email,
    String? token,
    String? newPassword,
    String? newPasswordConfirmation,
  }) {
    return ResetPasswordParams(
      email: email ?? this.email,
      token: token ?? this.token,
      newPassword: newPassword ?? this.newPassword,
      newPasswordConfirmation:
          newPasswordConfirmation ?? this.newPasswordConfirmation,
    );
  }

  @override
  String toString() {
    return 'ResetPasswordParams(email: $email, token: ${token.isNotEmpty ? '***' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResetPasswordParams &&
        other.email == email &&
        other.token == token &&
        other.newPassword == newPassword;
  }

  @override
  int get hashCode {
    return email.hashCode ^ token.hashCode ^ newPassword.hashCode;
  }
}
