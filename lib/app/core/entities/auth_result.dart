// Authentication result entity
import 'dart:convert';

import 'user_entity.dart';
import 'tokens_entity.dart';

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String message;
  final String? errorCode;
  final UserEntity? user;
  final TokensEntity? tokens;

  const AuthResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.user,
    this.tokens,
  });

  /// Create successful auth result
  factory AuthResult.success({
    String message = 'Operation successful',
    UserEntity? user,
    TokensEntity? tokens,
  }) {
    return AuthResult(
      success: true,
      message: message,
      user: user,
      tokens: tokens,
    );
  }

  /// Create failed auth result
  factory AuthResult.failure({required String message, String? errorCode}) {
    return AuthResult(success: false, message: message, errorCode: errorCode);
  }

  /// Create AuthResult from JSON
  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorCode: json['error_code'] as String?,
      user: json['user'] != null
          ? UserEntity.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      tokens: json['tokens'] != null
          ? TokensEntity.fromApiResponse(json['tokens'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert AuthResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'error_code': errorCode,
      'user': user?.toJson(),
      'tokens': tokens?.toJson(),
    };
  }

  /// Convenience getter for success status
  bool get isSuccess => success;

  /// Convenience getter for failure status
  bool get isFailure => !success;

  /// Create a copy with updated values
  AuthResult copyWith({
    bool? success,
    String? message,
    String? errorCode,
    UserEntity? user,
    TokensEntity? tokens,
  }) {
    return AuthResult(
      success: success ?? this.success,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      user: user ?? this.user,
      tokens: tokens ?? this.tokens,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, user: ${user?.email})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.message == message &&
        other.errorCode == errorCode &&
        other.user == user &&
        other.tokens == tokens;
  }

  @override
  int get hashCode =>
      success.hashCode ^
      message.hashCode ^
      errorCode.hashCode ^
      user.hashCode ^
      tokens.hashCode;
}
