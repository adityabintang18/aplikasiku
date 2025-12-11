// Base parameters class for all use case parameters
import 'dart:convert';

/// Base class for all use case parameters
/// Provides common validation and serialization functionality
abstract class BaseParams {
  const BaseParams();

  /// List of validation errors (empty if valid)
  List<String> get validationErrors;

  /// Whether the parameters are valid
  bool get isValid;

  /// Convert to JSON
  Map<String, dynamic> toJson();

  /// Create from JSON
  factory BaseParams.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Subclasses must implement fromJson');
  }

  @override
  String toString();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

/// Base parameters with string fields
abstract class BaseParamsWithFields extends BaseParams {
  const BaseParamsWithFields();

  /// Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Phone validation helper
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone.trim());
  }

  /// Password validation helper
  bool _isValidPassword(String password, {int minLength = 6}) {
    return password.length >= minLength;
  }
}
