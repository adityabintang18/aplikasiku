// Get Current User use case - business logic for retrieving current user
import 'package:logger/logger.dart';

import '../../../core/interfaces/auth_repository.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/exceptions/app_exception.dart';

import '../base_usecase.dart';

/// Result of get current user use case
class GetCurrentUserResult {
  final bool success;
  final UserEntity? user;
  final String message;
  final String? errorCode;

  const GetCurrentUserResult({
    required this.success,
    this.user,
    required this.message,
    this.errorCode,
  });

  bool get isSuccess => success;
  String? get errorMessage => success ? null : message;

  /// Check if user is authenticated
  bool get isAuthenticated => success && user != null;
}

/// Get Current User use case implementation
class GetCurrentUserUseCase implements UseCase<GetCurrentUserResult, void> {
  final AuthRepository _authRepository;
  final Logger _logger;

  GetCurrentUserUseCase({
    required AuthRepository authRepository,
    Logger? logger,
  }) : _authRepository = authRepository,
       _logger = logger ?? Logger();

  @override
  Future<GetCurrentUserResult> execute(void params) async {
    _logger.i('GetCurrentUserUseCase: Starting to get current user');

    try {
      // Check if user is logged in first
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (!isLoggedIn) {
        _logger.w('GetCurrentUserUseCase: User not logged in');
        return GetCurrentUserResult(
          success: false,
          message: 'User not logged in. Please login to continue.',
        );
      }

      // Get current user from repository
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _logger.i(
          'GetCurrentUserUseCase: Successfully retrieved current user: ${user.name}',
        );
        return GetCurrentUserResult(
          success: true,
          user: user,
          message: 'User information retrieved successfully',
        );
      } else {
        _logger.w('GetCurrentUserUseCase: Failed to retrieve user information');
        return GetCurrentUserResult(
          success: false,
          message: 'Failed to retrieve user information. Please try again.',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'GetCurrentUserUseCase: Unexpected error getting current user',
        error: e,
        stackTrace: stackTrace,
      );

      // Handle different types of exceptions
      if (e is NetworkException) {
        return GetCurrentUserResult(
          success: false,
          message: 'Network error. Please check your connection and try again.',
        );
      } else if (e is AuthException) {
        return GetCurrentUserResult(
          success: false,
          message: 'Authentication error. Please login again.',
        );
      } else {
        return GetCurrentUserResult(
          success: false,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  @override
  Future<GetCurrentUserResult> call() => execute(null);
}

/// Get Login Status use case - simplified version to check if user is logged in
class GetLoginStatusUseCase implements UseCase<bool, void> {
  final AuthRepository _authRepository;
  final Logger _logger;

  GetLoginStatusUseCase({
    required AuthRepository authRepository,
    Logger? logger,
  }) : _authRepository = authRepository,
       _logger = logger ?? Logger();

  @override
  Future<bool> execute(void params) async {
    _logger.d('GetLoginStatusUseCase: Checking login status');

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      _logger.d('GetLoginStatusUseCase: Login status: $isLoggedIn');
      return isLoggedIn;
    } catch (e, stackTrace) {
      _logger.e(
        'GetLoginStatusUseCase: Error checking login status',
        error: e,
        stackTrace: stackTrace,
      );
      return false; // Return false on any error
    }
  }

  @override
  Future<bool> call() => execute(null);
}
