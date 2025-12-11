// Concrete implementation of local data source for authentication
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
// Note: SharedPreferences should be initialized properly in app
import '../../core/interfaces/auth_local_data_source.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tokens_entity.dart';

/// Concrete implementation of local data source for authentication
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  static const String _userInfoKey = 'user_info';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricDeviceIdKey = 'biometric_device_id';
  static const String _preferencesKey = 'app_preferences';
  // static const String _lastLoginTimeKey = 'last_login_time';

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  AuthLocalDataSourceImpl({
    required FlutterSecureStorage secureStorage,
    Logger? logger,
  }) : _secureStorage = secureStorage,
       _logger = logger ?? Logger();

  // Token storage methods
  @override
  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(key: _accessTokenKey, value: token);
      _logger.d('Access token saved locally');
    } catch (e) {
      _logger.e('Failed to save access token: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
      _logger.d('Refresh token saved locally');
    } catch (e) {
      _logger.e('Failed to save refresh token: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTokens(TokensEntity tokens) async {
    try {
      await saveAccessToken(tokens.accessToken);
      await saveRefreshToken(tokens.refreshToken);

      // Store expiry times
      await _secureStorage.write(
        key: _accessTokenExpiryKey,
        value: tokens.expiresAt.toIso8601String(),
      );
      await _secureStorage.write(
        key: _refreshTokenExpiryKey,
        value: tokens.expiresAt.toIso8601String(),
      );

      _logger.d('Tokens saved locally: expires at ${tokens.expiresAt}');
    } catch (e) {
      _logger.e('Failed to save tokens: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      _logger.e('Failed to read access token: $e');
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      _logger.e('Failed to read refresh token: $e');
      return null;
    }
  }

  @override
  Future<TokensEntity?> getTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final expiryStr = await _secureStorage.read(key: _accessTokenExpiryKey);

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      DateTime? expiresAt;
      if (expiryStr != null) {
        expiresAt = DateTime.tryParse(expiryStr);
      }

      return TokensEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
      );
    } catch (e) {
      _logger.e('Failed to get tokens: $e');
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _accessTokenExpiryKey);
      await _secureStorage.delete(key: _refreshTokenExpiryKey);
      _logger.d('Tokens cleared from local storage');
    } catch (e) {
      _logger.e('Failed to clear tokens: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> hasTokens() async {
    final hasAccess = await hasAccessToken();
    final hasRefresh = await hasRefreshToken();
    return hasAccess && hasRefresh;
  }

  @override
  Future<bool> isAccessTokenExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: _accessTokenExpiryKey);
      if (expiryStr == null) {
        // Assume expired if no expiry date stored
        return true;
      }

      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null) {
        return true;
      }

      return DateTime.now().isAfter(expiry);
    } catch (e) {
      _logger.e('Failed to check access token expiry: $e');
      return true; // Assume expired on error
    }
  }

  @override
  Future<bool> isRefreshTokenExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: _refreshTokenExpiryKey);
      if (expiryStr == null) {
        // Assume expired if no expiry date stored
        return true;
      }

      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null) {
        return true;
      }

      return DateTime.now().isAfter(expiry);
    } catch (e) {
      _logger.e('Failed to check refresh token expiry: $e');
      return true; // Assume expired on error
    }
  }

  @override
  Future<bool> isAccessTokenValid() async {
    final hasToken = await hasAccessToken();
    final isExpired = await isAccessTokenExpired();
    return hasToken && !isExpired;
  }

  @override
  Future<bool> isRefreshTokenValid() async {
    final hasToken = await hasRefreshToken();
    final isExpired = await isRefreshTokenExpired();
    return hasToken && !isExpired;
  }

  // User data storage methods
  @override
  Future<void> saveUserInfo(UserEntity user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userInfoKey, value: userJson);
      _logger.d('User info saved locally: ${user.name}');
    } catch (e) {
      _logger.e('Failed to save user info: $e');
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getUserInfo() async {
    try {
      final userJson = await _secureStorage.read(key: _userInfoKey);
      if (userJson == null) {
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserEntity.fromApiResponse(userMap);
    } catch (e) {
      _logger.e('Failed to get user info: $e');
      return null;
    }
  }

  @override
  Future<void> clearUserInfo() async {
    try {
      await _secureStorage.delete(key: _userInfoKey);
      _logger.d('User info cleared from local storage');
    } catch (e) {
      _logger.e('Failed to clear user info: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasUserInfo() async {
    final userInfo = await getUserInfo();
    return userInfo != null;
  }

  // Session management
  @override
  Future<void> saveSession({
    required TokensEntity tokens,
    required UserEntity user,
  }) async {
    try {
      await saveTokens(tokens);
      await saveUserInfo(user);
      _logger.d('Session saved locally');
    } catch (e) {
      _logger.e('Failed to save session: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await clearTokens();
      await clearUserInfo();
      _logger.d('Session cleared from local storage');
    } catch (e) {
      _logger.e('Failed to clear session: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasSession() async {
    final hasTokensValue = await hasTokens();
    final hasUserValue = await hasUserInfo();
    return hasTokensValue && hasUserValue;
  }

  @override
  Future<bool> isSessionValid() async {
    final hasSessionValue = await hasSession();
    final isAccessValid = await isAccessTokenValid();
    final isRefreshValid = await isRefreshTokenValid();
    return hasSessionValue && isAccessValid && isRefreshValid;
  }

  // Biometric authentication
  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      // Note: This would need SharedPreferences, for now using secure storage
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      _logger.d('Biometric enabled: $enabled');
    } catch (e) {
      _logger.e('Failed to set biometric enabled: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      _logger.e('Failed to get biometric enabled: $e');
      return false;
    }
  }

  @override
  Future<void> clearBiometricState() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await clearBiometricDeviceId();
      _logger.d('Biometric state cleared');
    } catch (e) {
      _logger.e('Failed to clear biometric state: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveBiometricDeviceId(String deviceId) async {
    try {
      await _secureStorage.write(key: _biometricDeviceIdKey, value: deviceId);
      _logger.d('Biometric device ID saved');
    } catch (e) {
      _logger.e('Failed to save biometric device ID: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getBiometricDeviceId() async {
    try {
      return await _secureStorage.read(key: _biometricDeviceIdKey);
    } catch (e) {
      _logger.e('Failed to get biometric device ID: $e');
      return null;
    }
  }

  @override
  Future<void> clearBiometricDeviceId() async {
    try {
      await _secureStorage.delete(key: _biometricDeviceIdKey);
      _logger.d('Biometric device ID cleared');
    } catch (e) {
      _logger.e('Failed to clear biometric device ID: $e');
      rethrow;
    }
  }

  // App preferences (using secure storage for now)
  @override
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesJson = jsonEncode(preferences);
      await _secureStorage.write(key: _preferencesKey, value: preferencesJson);
      _logger.d('Preferences saved locally');
    } catch (e) {
      _logger.e('Failed to save preferences: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final preferencesJson = await _secureStorage.read(key: _preferencesKey);
      if (preferencesJson == null) {
        return {};
      }

      return jsonDecode(preferencesJson) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to get preferences: $e');
      return {};
    }
  }

  @override
  Future<T?> getPreference<T>(String key, {T? defaultValue}) async {
    try {
      final preferences = await getPreferences();
      return preferences[key] as T? ?? defaultValue;
    } catch (e) {
      _logger.e('Failed to get preference $key: $e');
      return defaultValue;
    }
  }

  @override
  Future<void> savePreference<T>(String key, T value) async {
    try {
      final preferences = await getPreferences();
      preferences[key] = value;
      await savePreferences(preferences);
      _logger.d('Preference $key saved: $value');
    } catch (e) {
      _logger.e('Failed to save preference $key: $e');
      rethrow;
    }
  }

  @override
  Future<void> removePreference(String key) async {
    try {
      final preferences = await getPreferences();
      preferences.remove(key);
      await savePreferences(preferences);
      _logger.d('Preference $key removed');
    } catch (e) {
      _logger.e('Failed to remove preference $key: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearPreferences() async {
    try {
      await _secureStorage.delete(key: _preferencesKey);
      _logger.d('All preferences cleared');
    } catch (e) {
      _logger.e('Failed to clear preferences: $e');
      rethrow;
    }
  }

  // Cache management
  @override
  Future<void> clearAllCache() async {
    try {
      await clearSession();
      await clearPreferences();
      await clearBiometricState();
      _logger.d('All cache cleared from local storage');
    } catch (e) {
      _logger.e('Failed to clear all cache: $e');
      rethrow;
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      // This is a simplified calculation
      // In a real implementation, you might want to calculate actual storage usage
      final hasTokensValue = await hasTokens();
      final hasUserValue = await hasUserInfo();
      final hasPrefs = (await getPreferences()).isNotEmpty;

      int estimatedSize = 0;
      if (hasTokensValue) estimatedSize += 1024; // ~1KB for tokens
      if (hasUserValue) estimatedSize += 2048; // ~2KB for user info
      if (hasPrefs) estimatedSize += 512; // ~512B for preferences

      return estimatedSize;
    } catch (e) {
      _logger.e('Failed to get cache size: $e');
      return 0;
    }
  }

  @override
  Future<void> cleanExpiredCache() async {
    try {
      final isAccessExpired = await isAccessTokenExpired();
      final isRefreshExpired = await isRefreshTokenExpired();

      if (isAccessExpired) {
        await _secureStorage.delete(key: _accessTokenKey);
        await _secureStorage.delete(key: _accessTokenExpiryKey);
      }

      if (isRefreshExpired) {
        await _secureStorage.delete(key: _refreshTokenKey);
        await _secureStorage.delete(key: _refreshTokenExpiryKey);
      }

      _logger.d('Expired cache entries cleaned');
    } catch (e) {
      _logger.e('Failed to clean expired cache: $e');
      // Don't rethrow as this is a cleanup operation
    }
  }
}
