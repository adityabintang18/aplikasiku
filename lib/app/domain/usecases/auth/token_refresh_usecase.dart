// Token Refresh use case - handles token expiry and automatic refresh
import 'package:logger/logger.dart';

import '../../../core/interfaces/auth_repository.dart';
// import '../../../core/entities/auth_result.dart';
import '../../../core/entities/tokens_entity.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/exceptions/app_exception.dart';

import '../base_usecase.dart';

/// Result of token refresh operation
class TokenRefreshResult {
  final bool success;
  final UserEntity? user;
  final String message;
  final String? errorCode;
  final bool isTokenExpired;

  const TokenRefreshResult({
    required this.success,
    this.user,
    required this.message,
    this.errorCode,
    this.isTokenExpired = false,
  });

  bool get isSuccess => success;
  String? get errorMessage => success ? null : message;
}

/// Token refresh use case implementation
class TokenRefreshUseCase implements UseCase<TokenRefreshResult, void> {
  final AuthRepository _authRepository;
  final Logger _logger;

  TokenRefreshUseCase({required AuthRepository authRepository, Logger? logger})
    : _authRepository = authRepository,
      _logger = logger ?? Logger();

  @override
  Future<TokenRefreshResult> execute(void params) async {
    _logger.i('TokenRefreshUseCase: Starting token refresh process');

    try {
      // First check if we have valid tokens
      final tokens = await _authRepository.getCurrentTokens();
      if (tokens == null) {
        _logger.w('TokenRefreshUseCase: No tokens available for refresh');
        return TokenRefreshResult(
          success: false,
          message: 'No valid session found. Please login again.',
          isTokenExpired: true,
        );
      }

      // Check if tokens are expired
      if (tokens.isExpired) {
        _logger.w('TokenRefreshUseCase: Tokens are expired, clearing session');
        await _authRepository.clearSession();
        return TokenRefreshResult(
          success: false,
          message: 'Your session has expired. Please login again.',
          isTokenExpired: true,
        );
      }

      // Check if tokens need refresh (expiring within 5 minutes)
      if (!tokens.needsRefresh) {
        _logger.d(
          'TokenRefreshUseCase: Tokens are still valid, no refresh needed',
        );
        final currentUser = await _authRepository.getCurrentUser();
        return TokenRefreshResult(
          success: true,
          user: currentUser,
          message: 'Tokens are still valid',
        );
      }

      _logger.i('TokenRefreshUseCase: Tokens need refresh, attempting refresh');

      // Attempt to refresh tokens
      final refreshResult = await _authRepository.refreshToken();

      if (refreshResult.success && refreshResult.user != null) {
        _logger.i('TokenRefreshUseCase: Token refresh successful');
        return TokenRefreshResult(
          success: true,
          user: refreshResult.user,
          message: 'Token refreshed successfully',
        );
      } else {
        _logger.w(
          'TokenRefreshUseCase: Token refresh failed - ${refreshResult.message}',
        );

        // If refresh fails due to expired refresh token, clear session
        if (refreshResult.message.contains('expired') ||
            refreshResult.message.contains('invalid')) {
          _logger.w(
            'TokenRefreshUseCase: Refresh token expired, clearing session',
          );
          await _authRepository.clearSession();

          return TokenRefreshResult(
            success: false,
            message: 'Your session has expired. Please login again.',
            isTokenExpired: true,
            errorCode: refreshResult.errorCode,
          );
        }

        return TokenRefreshResult(
          success: false,
          message: 'Failed to refresh token. Please login again.',
          errorCode: refreshResult.errorCode,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'TokenRefreshUseCase: Unexpected error during token refresh',
        error: e,
        stackTrace: stackTrace,
      );

      // Handle different types of exceptions
      if (e is NetworkException) {
        return TokenRefreshResult(
          success: false,
          message: 'Network error. Please check your connection and try again.',
        );
      } else if (e is AuthException) {
        return TokenRefreshResult(
          success: false,
          message: 'Authentication error. Please login again.',
        );
      } else {
        return TokenRefreshResult(
          success: false,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  /// Check if current tokens are expired or need refresh
  Future<TokenRefreshResult> checkTokenStatus() async {
    _logger.d('TokenRefreshUseCase: Checking token status');

    try {
      final tokens = await _authRepository.getCurrentTokens();
      if (tokens == null) {
        return TokenRefreshResult(
          success: false,
          message: 'No tokens available',
          isTokenExpired: true,
        );
      }

      if (tokens.isExpired) {
        _logger.w('TokenRefreshUseCase: Tokens are expired');
        return TokenRefreshResult(
          success: false,
          message: 'Session expired',
          isTokenExpired: true,
        );
      }

      if (tokens.needsRefresh) {
        _logger.i('TokenRefreshUseCase: Tokens need refresh');
        return TokenRefreshResult(
          success: true,
          message: 'Tokens need refresh',
        );
      }

      _logger.d('TokenRefreshUseCase: Tokens are valid');
      return TokenRefreshResult(success: true, message: 'Tokens are valid');
    } catch (e, stackTrace) {
      _logger.e(
        'TokenRefreshUseCase: Error checking token status',
        error: e,
        stackTrace: stackTrace,
      );
      return TokenRefreshResult(
        success: false,
        message: 'Error checking token status',
      );
    }
  }

  /// Force token refresh regardless of expiry status
  Future<TokenRefreshResult> forceRefresh() async {
    _logger.i('TokenRefreshUseCase: Force refreshing tokens');

    try {
      final refreshResult = await _authRepository.refreshToken();

      if (refreshResult.success && refreshResult.user != null) {
        return TokenRefreshResult(
          success: true,
          user: refreshResult.user,
          message: 'Token refreshed successfully',
        );
      } else {
        return TokenRefreshResult(
          success: false,
          message: refreshResult.message,
          errorCode: refreshResult.errorCode,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'TokenRefreshUseCase: Force refresh failed',
        error: e,
        stackTrace: stackTrace,
      );
      return TokenRefreshResult(
        success: false,
        message: 'Force refresh failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<TokenRefreshResult> call() => execute(null);
}

/// Extension to add token refresh capability to AuthRepository
extension AuthRepositoryTokenRefresh on AuthRepository {
  /// Get current tokens (helper method)
  Future<TokensEntity?> getCurrentTokens() async {
    try {
      // This would need to be added to the AuthRepository interface
      // For now, we'll use the existing methods
      return null; // Placeholder
    } catch (e) {
      return null;
    }
  }
}
