// Change password parameters entity
import 'dart:convert';

/// Parameters for changing user password
class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });

  /// Validate password change parameters
  bool get isValid {
    return currentPassword.isNotEmpty &&
        newPassword.isNotEmpty &&
        newPassword.length >= 6 &&
        newPassword == newPasswordConfirmation &&
        currentPassword != newPassword;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (currentPassword.isEmpty) {
      errors.add('Current password is required');
    }

    if (newPassword.isEmpty) {
      errors.add('New password is required');
    } else if (newPassword.length < 6) {
      errors.add('New password must be at least 6 characters');
    }

    if (newPasswordConfirmation.isEmpty) {
      errors.add('Password confirmation is required');
    } else if (newPassword != newPasswordConfirmation) {
      errors.add('New passwords do not match');
    }

    if (currentPassword.isNotEmpty && currentPassword == newPassword) {
      errors.add('New password must be different from current password');
    }

    return errors;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    };
  }

  /// Create from JSON
  factory ChangePasswordParams.fromJson(Map<String, dynamic> json) {
    return ChangePasswordParams(
      currentPassword: json['current_password'] as String,
      newPassword: json['new_password'] as String,
      newPasswordConfirmation: json['new_password_confirmation'] as String,
    );
  }

  /// Create copy with updated fields
  ChangePasswordParams copyWith({
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) {
    return ChangePasswordParams(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      newPasswordConfirmation:
          newPasswordConfirmation ?? this.newPasswordConfirmation,
    );
  }

  @override
  String toString() {
    return 'ChangePasswordParams(currentPassword: ${currentPassword.isNotEmpty ? '***' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChangePasswordParams &&
        other.currentPassword == currentPassword &&
        other.newPassword == newPassword;
  }

  @override
  int get hashCode {
    return currentPassword.hashCode ^ newPassword.hashCode;
  }
}
