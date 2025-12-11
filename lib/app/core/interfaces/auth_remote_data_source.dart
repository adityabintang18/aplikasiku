// Remote data source interface for authentication API calls
import '../entities/login_params.dart';
import '../entities/register_params.dart';
import '../entities/update_profile_params.dart';
import '../entities/change_password_params.dart';
import '../entities/reset_password_params.dart';

/// Remote data source interface for authentication operations
abstract class AuthRemoteDataSource {
  /// Login with email and password
  Future<Map<String, dynamic>> login(LoginParams params);

  /// Login with biometric authentication
  Future<Map<String, dynamic>> loginWithBiometric(String refreshToken);

  /// Register new user
  Future<Map<String, dynamic>> register(RegisterParams params);

  /// Logout user
  Future<Map<String, dynamic>> logout(String accessToken);

  /// Refresh access token
  Future<Map<String, dynamic>> refreshToken(String refreshToken);

  /// Get current user information
  Future<Map<String, dynamic>> getCurrentUser(String accessToken);

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(
    String accessToken,
    UpdateProfileParams params,
  );

  /// Change password
  Future<Map<String, dynamic>> changePassword(
    String accessToken,
    ChangePasswordParams params,
  );

  /// Request password reset
  Future<Map<String, dynamic>> forgotPassword(String email);

  /// Reset password with token
  Future<Map<String, dynamic>> resetPassword(ResetPasswordParams params);

  /// Check server connectivity
  Future<bool> checkConnectivity();

  /// Get API base URL
  String get baseUrl;

  /// Get default headers for requests (async to support dynamic version)
  Future<Map<String, String>> get defaultHeaders;
}
