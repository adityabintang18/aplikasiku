// Logout use case - business logic for user logout
import 'package:logger/logger.dart';

import '../../../core/interfaces/auth_repository.dart';
import '../../../core/exceptions/app_exception.dart';

import '../base_usecase.dart';

/// Result of logout use case
class LogoutResult {
  final bool success;
  final String message;
  final String? errorCode;

  const LogoutResult({
    required this.success,
    required this.message,
    this.errorCode,
  });

  bool get isSuccess => success;
  String? get errorMessage => success ? null : message;
}

/// Logout use case implementation
class LogoutUseCase implements VoidUseCase<void> {
  final AuthRepository _authRepository;
  final Logger _logger;

  LogoutUseCase({required AuthRepository authRepository, Logger? logger})
    : _authRepository = authRepository,
      _logger = logger ?? Logger();

  @override
  Future<void> execute(void params) async {
    _logger.i('LogoutUseCase: Starting logout process');

    try {
      // Perform logout through repository
      await _authRepository.logout();
      _logger.i('LogoutUseCase: Logout successful');
    } catch (e, stackTrace) {
      _logger.e(
        'LogoutUseCase: Error during logout',
        error: e,
        stackTrace: stackTrace,
      );

      // Don't rethrow logout errors as logout should always succeed locally
      // Just log the error for monitoring
      if (e is NetworkException) {
        _logger.w(
          'LogoutUseCase: Network error during logout, continuing with local cleanup',
        );
      } else if (e is AuthException) {
        _logger.w(
          'LogoutUseCase: Auth error during logout, continuing with local cleanup',
        );
      } else {
        _logger.w(
          'LogoutUseCase: Unexpected error during logout, continuing with local cleanup',
        );
      }
    }
  }

  /// Execute logout and return result
  Future<LogoutResult> executeWithResult() async {
    _logger.i('LogoutUseCase: Starting logout with result');

    try {
      // Perform logout through repository
      await _authRepository.logout();
      _logger.i('LogoutUseCase: Logout successful');

      return LogoutResult(success: true, message: 'Logged out successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'LogoutUseCase: Error during logout',
        error: e,
        stackTrace: stackTrace,
      );

      // Determine error type and message
      String errorMessage = 'Logout completed with warnings';

      if (e is NetworkException) {
        errorMessage =
            'Logged out locally. Network connection unavailable for server logout.';
      } else if (e is AuthException) {
        errorMessage = 'Logged out locally. Server logout failed.';
      } else {
        errorMessage = 'Logged out locally with some warnings.';
      }

      return LogoutResult(
        success: true, // Always return true as logout should succeed locally
        message: errorMessage,
        errorCode: e.toString(),
      );
    }
  }

  @override
  Future<void> call() => execute(null);
}
