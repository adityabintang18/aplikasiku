// Concrete implementation of authentication repository

import 'package:logger/logger.dart';
import '../../core/interfaces/auth_repository.dart';
import '../../core/interfaces/auth_remote_data_source.dart';
import '../../core/interfaces/auth_local_data_source.dart';
import '../../core/interfaces/network_info.dart';
import '../../core/entities/auth_result.dart';
import '../../core/entities/login_params.dart';
import '../../core/entities/register_params.dart';
import '../../core/entities/user_entity.dart';
import '../../core/entities/tokens_entity.dart';
import '../../core/entities/update_profile_params.dart';
import '../../core/entities/change_password_params.dart';
import '../../core/entities/reset_password_params.dart';
import '../../core/utils/error_handler.dart';

/// Concrete implementation of authentication repository
/// Coordinates between remote and local data sources
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final Logger _logger;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    Logger? logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo,
       _logger = logger ?? Logger();

  /// Check if operation can be performed (network available and user logged in)
  Future<bool> _canPerformOperation({bool requiresAuth = false}) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      _logger.w('Cannot perform operation: no network connection');
      return false;
    }

    if (requiresAuth) {
      final isLoggedInValue = await isLoggedIn();
      if (!isLoggedInValue) {
        _logger.w('Cannot perform operation: user not logged in');
        return false;
      }
    }

    return true;
  }

  /// Transform API response to AuthResult
  AuthResult _transformApiResponse(Map<String, dynamic> response) {
    try {
      final success = response['success'] as bool? ?? false;
      final message = response['message'] as String? ?? '';

      if (success) {
        // Extract user data if available
        UserEntity? user;
        if (response.containsKey('user') && response['user'] != null) {
          final userData = response['user'] as Map<String, dynamic>;
          user = UserEntity.fromApiResponse(userData);
        }

        // Extract tokens if available
        TokensEntity? tokens;
        if (response.containsKey('tokens') && response['tokens'] != null) {
          final tokensData = response['tokens'] as Map<String, dynamic>;
          tokens = TokensEntity.fromApiResponse(tokensData);
        }

        return AuthResult.success(message: message, user: user, tokens: tokens);
      } else {
        return AuthResult.failure(
          message: message,
          errorCode: response['error_code'] as String?,
        );
      }
    } catch (e) {
      _logger.e('Error transforming API response: $e');
      return AuthResult.failure(message: 'Invalid response format');
    }
  }

  /// Handle exceptions and convert to user-friendly messages
  String _handleException(dynamic error) {
    return ErrorHandler.handle(error);
  }

  @override
  Future<AuthResult> login(LoginParams params) async {
    _logger.i('Repository login attempt for: ${params.email}');

    try {
      // Validate network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        return AuthResult.failure(message: 'Invalid input: $errors');
      }

      // Perform remote login
      final response = await _remoteDataSource.login(params);
      final result = _transformApiResponse(response);

      // If successful, save session data
      if (result.success && result.tokens != null && result.user != null) {
        await _localDataSource.saveSession(
          tokens: result.tokens!,
          user: result.user!,
        );
        _logger.i('Repository login successful, session saved');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e('Repository login failed', error: e, stackTrace: stackTrace);
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<AuthResult> loginWithBiometric() async {
    _logger.i('Repository biometric login attempt');

    try {
      // Check if biometric is enabled locally
      if (!await _localDataSource.isBiometricEnabled()) {
        return AuthResult.failure(
          message:
              'Biometric login is not enabled. Please enable it in settings.',
        );
      }

      // Get stored refresh token
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure(
          message: 'No valid session found. Please login first.',
        );
      }

      // Check network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Perform remote biometric login
      final response = await _remoteDataSource.loginWithBiometric(refreshToken);
      final result = _transformApiResponse(response);

      // If successful, update session data
      if (result.success && result.tokens != null && result.user != null) {
        await _localDataSource.saveSession(
          tokens: result.tokens!,
          user: result.user!,
        );
        _logger.i('Repository biometric login successful, session updated');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository biometric login failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<AuthResult> register(RegisterParams params) async {
    _logger.i('Repository register attempt for: ${params.email}');

    try {
      // Validate network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        return AuthResult.failure(message: 'Invalid input: $errors');
      }

      // Perform remote registration
      final response = await _remoteDataSource.register(params);
      final result = _transformApiResponse(response);

      // If successful, save session data
      if (result.success && result.tokens != null && result.user != null) {
        await _localDataSource.saveSession(
          tokens: result.tokens!,
          user: result.user!,
        );
        _logger.i('Repository registration successful, session saved');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository registration failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<void> logout() async {
    _logger.i('Repository logout attempt');

    try {
      final accessToken = await _localDataSource.getAccessToken();

      // Try to logout from remote if we have a token and network is available
      if (accessToken != null && await _networkInfo.isConnected) {
        try {
          await _remoteDataSource.logout(accessToken);
          _logger.i('Remote logout successful');
        } catch (e) {
          _logger.w('Remote logout failed, continuing with local cleanup: $e');
        }
      }

      // Clear local session regardless of remote result
      await _localDataSource.clearSession();
      _logger.i('Repository logout successful, local session cleared');
    } catch (e, stackTrace) {
      _logger.e('Repository logout failed', error: e, stackTrace: stackTrace);
      // Don't rethrow as logout should always succeed locally
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      // Check local session validity
      final isSessionValid = await _localDataSource.isSessionValid();

      if (!isSessionValid) {
        return false;
      }

      // Check if we need to refresh the token
      final tokens = await _localDataSource.getTokens();
      if (tokens != null &&
          tokens.needsRefresh &&
          await _networkInfo.isConnected) {
        _logger.i('Token needs refresh, attempting to refresh');
        final refreshResult = await refreshToken();
        return refreshResult.success;
      }

      return true;
    } catch (e) {
      _logger.e('Error checking login status: $e');
      return false;
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    _logger.i('Repository token refresh attempt');

    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure(message: 'No refresh token available');
      }

      // Check network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Perform remote token refresh
      final response = await _remoteDataSource.refreshToken(refreshToken);
      final result = _transformApiResponse(response);

      // If successful, update stored tokens
      if (result.success && result.tokens != null) {
        final currentUser = await _localDataSource.getUserInfo();
        if (currentUser != null) {
          await _localDataSource.saveSession(
            tokens: result.tokens!,
            user: currentUser,
          );
        } else {
          await _localDataSource.saveTokens(result.tokens!);
        }
        _logger.i('Repository token refresh successful, tokens updated');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository token refresh failed',
        error: e,
        stackTrace: stackTrace,
      );

      // If refresh fails, clear local session
      await _localDataSource.clearSession();

      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      // Try to get from local storage first
      final localUser = await _localDataSource.getUserInfo();
      if (localUser != null) {
        return localUser;
      }

      // If not available locally, try to get from remote
      if (!await _canPerformOperation(requiresAuth: true)) {
        return null;
      }

      final accessToken = await _localDataSource.getAccessToken();
      if (accessToken == null) {
        return null;
      }

      final response = await _remoteDataSource.getCurrentUser(accessToken);
      final result = _transformApiResponse(response);

      if (result.success && result.user != null) {
        // Save user info locally for future use
        await _localDataSource.saveUserInfo(result.user!);
        return result.user!;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<AuthResult> updateProfile(UpdateProfileParams params) async {
    _logger.i('Repository update profile attempt');

    try {
      // Check if we can perform the operation
      if (!await _canPerformOperation(requiresAuth: true)) {
        return AuthResult.failure(
          message: 'No internet connection or not logged in.',
        );
      }

      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        return AuthResult.failure(message: 'Invalid input: $errors');
      }

      final accessToken = await _localDataSource.getAccessToken();
      if (accessToken == null) {
        return AuthResult.failure(
          message: 'No valid access token. Please login again.',
        );
      }

      // Perform remote profile update
      final response = await _remoteDataSource.updateProfile(
        accessToken,
        params,
      );
      final result = _transformApiResponse(response);

      // If successful, update local user data
      if (result.success && result.user != null) {
        await _localDataSource.saveUserInfo(result.user!);
        _logger.i('Repository profile update successful, local data updated');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository profile update failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<AuthResult> changePassword(ChangePasswordParams params) async {
    _logger.i('Repository change password attempt');

    try {
      // Check if we can perform the operation
      if (!await _canPerformOperation(requiresAuth: true)) {
        return AuthResult.failure(
          message: 'No internet connection or not logged in.',
        );
      }

      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        return AuthResult.failure(message: 'Invalid input: $errors');
      }

      final accessToken = await _localDataSource.getAccessToken();
      if (accessToken == null) {
        return AuthResult.failure(
          message: 'No valid access token. Please login again.',
        );
      }

      // Perform remote password change
      final response = await _remoteDataSource.changePassword(
        accessToken,
        params,
      );
      final result = _transformApiResponse(response);

      // Note: Don't clear session on password change, just return result
      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository password change failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    _logger.i('Repository forgot password attempt for: $email');

    try {
      // Check network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Validate email
      if (email.isEmpty || !email.contains('@')) {
        return AuthResult.failure(
          message: 'Please enter a valid email address.',
        );
      }

      // Perform remote forgot password request
      final response = await _remoteDataSource.forgotPassword(email);
      final result = _transformApiResponse(response);

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository forgot password failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<AuthResult> resetPassword(ResetPasswordParams params) async {
    _logger.i('Repository reset password attempt for: ${params.email}');

    try {
      // Check network connectivity
      if (!await _canPerformOperation()) {
        return AuthResult.failure(
          message:
              'No internet connection. Please check your network settings.',
        );
      }

      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        return AuthResult.failure(message: 'Invalid input: $errors');
      }

      // Perform remote password reset
      final response = await _remoteDataSource.resetPassword(params);
      final result = _transformApiResponse(response);

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Repository password reset failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AuthResult.failure(message: _handleException(e));
    }
  }

  @override
  Future<void> saveSession(AuthResult authResult) async {
    try {
      if (authResult.success &&
          authResult.tokens != null &&
          authResult.user != null) {
        await _localDataSource.saveSession(
          tokens: authResult.tokens!,
          user: authResult.user!,
        );
        _logger.i('Repository session saved locally');
      }
    } catch (e) {
      _logger.e('Error saving session: $e');
      // Don't rethrow as this is a local operation
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _localDataSource.clearSession();
      _logger.i('Repository session cleared locally');
    } catch (e) {
      _logger.e('Error clearing session: $e');
      // Don't rethrow as this is a local operation
    }
  }

  @override
  Future<bool> isSessionValid() async {
    try {
      return await _localDataSource.isSessionValid();
    } catch (e) {
      _logger.e('Error checking session validity: $e');
      return false;
    }
  }

  @override
  Future<TokensEntity?> getCurrentTokens() async {
    try {
      final tokens = await _localDataSource.getTokens();
      if (tokens != null) {
        // Check if tokens are expired
        if (tokens.isExpired) {
          _logger.w('Current tokens are expired, clearing session');
          await _localDataSource.clearSession();
          return null;
        }
      }
      return tokens;
    } catch (e) {
      _logger.e('Error getting current tokens: $e');
      return null;
    }
  }
}
