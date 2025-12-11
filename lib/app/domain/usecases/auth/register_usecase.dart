// Register use case - business logic for user registration
import 'package:logger/logger.dart';

import '../../../core/interfaces/auth_repository.dart';
import '../../../core/entities/register_params.dart';
// import '../../../core/entities/auth_result.dart';
import '../../../core/entities/user_entity.dart';
import '../../../core/exceptions/app_exception.dart';

import '../base_usecase.dart';

/// Result of register use case
class RegisterResult {
  final bool success;
  final UserEntity? user;
  final String message;
  final String? errorCode;

  const RegisterResult({
    required this.success,
    this.user,
    required this.message,
    this.errorCode,
  });

  bool get isSuccess => success;
  String? get errorMessage => success ? null : message;
}

/// Register use case implementation
class RegisterUseCase implements UseCase<RegisterResult, RegisterParams> {
  final AuthRepository _authRepository;
  final Logger _logger;

  RegisterUseCase({required AuthRepository authRepository, Logger? logger})
    : _authRepository = authRepository,
      _logger = logger ?? Logger();

  @override
  Future<RegisterResult> execute(RegisterParams params) async {
    _logger.i('RegisterUseCase: Starting registration for ${params.email}');

    try {
      // Validate parameters
      if (!params.isValid) {
        final errors = params.validationErrors.join(', ');
        _logger.w('RegisterUseCase: Invalid parameters: $errors');
        return RegisterResult(
          success: false,
          message: 'Invalid input: $errors',
        );
      }

      // Perform registration through repository
      final authResult = await _authRepository.register(params);

      // Map repository result to use case result
      if (authResult.success && authResult.user != null) {
        _logger.i(
          'RegisterUseCase: Registration successful for ${params.email}',
        );
        return RegisterResult(
          success: true,
          user: authResult.user,
          message: authResult.message,
        );
      } else {
        _logger.w(
          'RegisterUseCase: Registration failed: ${authResult.message}',
        );
        return RegisterResult(
          success: false,
          message: authResult.message,
          errorCode: authResult.errorCode,
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'RegisterUseCase: Unexpected error during registration',
        error: e,
        stackTrace: stackTrace,
      );

      // Handle different types of exceptions
      if (e is NetworkException) {
        return RegisterResult(
          success: false,
          message:
              'No internet connection. Please check your network and try again.',
        );
      } else if (e is AuthException) {
        return RegisterResult(
          success: false,
          message:
              'Registration failed. Please check your information and try again.',
        );
      } else if (e is ValidationException) {
        return RegisterResult(
          success: false,
          message: 'Invalid input data. Please check your information.',
        );
      } else {
        return RegisterResult(
          success: false,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  @override
  Future<RegisterResult> call() {
    // This shouldn't be called without parameters
    return Future.value(
      RegisterResult(
        success: false,
        message: 'Invalid call to register use case without parameters',
      ),
    );
  }
}
