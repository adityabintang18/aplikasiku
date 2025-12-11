// Local data source interface for authentication local storage
import '../entities/user_entity.dart';
import '../entities/tokens_entity.dart';

/// Local data source interface for authentication local storage
abstract class AuthLocalDataSource {
  // Token storage methods
  /// Save access token
  Future<void> saveAccessToken(String token);

  /// Save refresh token
  Future<void> saveRefreshToken(String token);

  /// Save both tokens
  Future<void> saveTokens(TokensEntity tokens);

  /// Get access token
  Future<String?> getAccessToken();

  /// Get refresh token
  Future<String?> getRefreshToken();

  /// Get all tokens
  Future<TokensEntity?> getTokens();

  /// Clear all tokens
  Future<void> clearTokens();

  /// Check if access token exists
  Future<bool> hasAccessToken();

  /// Check if refresh token exists
  Future<bool> hasRefreshToken();

  /// Check if tokens exist
  Future<bool> hasTokens();

  /// Check if access token is expired
  Future<bool> isAccessTokenExpired();

  /// Check if refresh token is expired
  Future<bool> isRefreshTokenExpired();

  /// Check if access token is valid (exists and not expired)
  Future<bool> isAccessTokenValid();

  /// Check if refresh token is valid
  Future<bool> isRefreshTokenValid();

  // User data storage methods
  /// Save user information
  Future<void> saveUserInfo(UserEntity user);

  /// Get user information
  Future<UserEntity?> getUserInfo();

  /// Clear user information
  Future<void> clearUserInfo();

  /// Check if user info exists
  Future<bool> hasUserInfo();

  // Session management
  /// Save session data
  Future<void> saveSession({
    required TokensEntity tokens,
    required UserEntity user,
  });

  /// Clear all session data
  Future<void> clearSession();

  /// Check if session exists
  Future<bool> hasSession();

  /// Check if session is valid (has tokens and user info)
  Future<bool> isSessionValid();

  // Biometric authentication
  /// Save biometric authentication enabled state
  Future<void> setBiometricEnabled(bool enabled);

  /// Get biometric authentication enabled state
  Future<bool> isBiometricEnabled();

  /// Clear biometric authentication state
  Future<void> clearBiometricState();

  /// Save biometric device ID
  Future<void> saveBiometricDeviceId(String deviceId);

  /// Get biometric device ID
  Future<String?> getBiometricDeviceId();

  /// Clear biometric device ID
  Future<void> clearBiometricDeviceId();

  // App preferences
  /// Save app preferences
  Future<void> savePreferences(Map<String, dynamic> preferences);

  /// Get app preferences
  Future<Map<String, dynamic>> getPreferences();

  /// Get specific preference value
  Future<T?> getPreference<T>(String key, {T? defaultValue});

  /// Save specific preference value
  Future<void> savePreference<T>(String key, T value);

  /// Remove specific preference
  Future<void> removePreference(String key);

  /// Clear all preferences
  Future<void> clearPreferences();

  // Cache management
  /// Clear all cached data
  Future<void> clearAllCache();

  /// Get cache size in bytes
  Future<int> getCacheSize();

  /// Clean expired cache entries
  Future<void> cleanExpiredCache();
}
