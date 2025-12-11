// Login use case
import 'package:logger/logger.dart';

import '../../../core/interfaces/auth_repository.dart';
import '../../../core/entities/login_params.dart';
import '../../../core/entities/auth_result.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/utils/error_handler.dart';

/// Use case for user login
class LoginUseCase {
  final AuthRepository _authRepository;
  final Logger _logger;

  LoginUseCase({required AuthRepository authRepository, Logger? logger})
    : _authRepository = authRepository,
      _logger = logger ?? Logger();

  /// Execute login with given parameters
  Future<AuthResult> execute(LoginParams params) async {
    _logger.i('Login use case execution started');

    try {
      // Validate parameters first
      if (!params.isValid) {
        final validationMessage = params.validationErrors.join(', ');
        _logger.w('Login failed due to invalid parameters: $validationMessage');
        return AuthResult.failure(message: 'Invalid input: $validationMessage');
      }

      // Perform login through repository
      _logger.i('Attempting login for email: ${params.email}');
      final result = await _authRepository.login(params);

      if (result.success) {
        _logger.i('Login successful for user: ${result.user?.email}');
      } else {
        _logger.w('Login failed: ${result.message}');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e(
        'Login use case execution failed',
        error: e,
        stackTrace: stackTrace,
      );

      // Handle different types of exceptions
      if (e is NetworkException) {
        return AuthResult.failure(
          message: 'Network error: ${e.message}',
          errorCode: e.code,
        );
      } else if (e is ValidationException) {
        return AuthResult.failure(
          message: 'Validation error: ${e.message}',
          errorCode: e.code,
        );
      } else if (e is AuthException) {
        return AuthResult.failure(
          message: 'Authentication error: ${e.message}',
          errorCode: e.code,
        );
      } else {
        // Generic error handling
        return AuthResult.failure(message: ErrorHandler.handle(e));
      }
    }
  }
}
