// Repository interface for authentication operations
import '../entities/auth_result.dart';
import '../entities/login_params.dart';
import '../entities/register_params.dart';
import '../entities/user_entity.dart';
import '../entities/tokens_entity.dart';
import '../entities/update_profile_params.dart';
import '../entities/change_password_params.dart';
import '../entities/reset_password_params.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Login with email and password
  Future<AuthResult> login(LoginParams params);

  /// Login with biometric authentication
  Future<AuthResult> loginWithBiometric();

  /// Register new user
  Future<AuthResult> register(RegisterParams params);

  /// Logout user
  Future<void> logout();

  /// Check if user is currently logged in
  Future<bool> isLoggedIn();

  /// Refresh access token
  Future<AuthResult> refreshToken();

  /// Get current user information
  Future<UserEntity?> getCurrentUser();

  /// Update user profile
  Future<AuthResult> updateProfile(UpdateProfileParams params);

  /// Change password
  Future<AuthResult> changePassword(ChangePasswordParams params);

  /// Request password reset
  Future<AuthResult> forgotPassword(String email);

  /// Reset password with token
  Future<AuthResult> resetPassword(ResetPasswordParams params);

  /// Save user session
  Future<void> saveSession(AuthResult authResult);

  /// Clear user session
  Future<void> clearSession();

  /// Check if session is valid
  Future<bool> isSessionValid();

  /// Get current tokens
  Future<TokensEntity?> getCurrentTokens();
}
