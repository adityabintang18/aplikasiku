/// Custom exception classes for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// API-related exceptions
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? responseData;

  const ApiException(
    super.message, {
    this.statusCode,
    this.responseData,
    super.code,
    super.originalError,
  });
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// General application exceptions
class AppExceptionUnknown extends AppException {
  const AppExceptionUnknown(super.message, {super.code, super.originalError});
}
