/// Authentication result model for handling API responses
class AuthResult {
  final bool success;
  final String message;
  final String? resetToken;
  final Map<String, dynamic>? userData;

  AuthResult._({
    required this.success,
    required this.message,
    this.resetToken,
    this.userData,
  });

  factory AuthResult.success(String message,
      {String? resetToken, Map<String, dynamic>? userData}) {
    return AuthResult._(
      success: true,
      message: message,
      resetToken: resetToken,
      userData: userData,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      success: false,
      message: message,
    );
  }

  /// Convert to legacy Map format for backward compatibility
  Map<String, dynamic> toLegacyMap() {
    return {
      'success': success,
      'message': message,
      if (resetToken != null) 'reset_token': resetToken,
      if (userData != null) ...userData!,
    };
  }
}
