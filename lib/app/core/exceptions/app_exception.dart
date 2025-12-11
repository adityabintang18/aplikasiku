// Application exceptions

/// Base exception class for application errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppException(this.message, [this.code, this.statusCode]);

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code, super.statusCode]);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(super.message, [super.code, super.statusCode]);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code, super.statusCode]);
}

/// Server error exceptions
class ServerException extends AppException {
  const ServerException(super.message, [super.code, super.statusCode]);
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException(super.message, [super.code, super.statusCode]);
}

/// Parse error exceptions
class ParseException extends AppException {
  const ParseException(super.message, [super.code, super.statusCode]);
}

/// Permission denied exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, [super.code, super.statusCode]);
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.code, super.statusCode]);
}

/// Conflict exceptions (e.g., duplicate resources)
class ConflictException extends AppException {
  const ConflictException(super.message, [super.code, super.statusCode]);
}

/// Biometric-related exceptions
class BiometricException extends AppException {
  const BiometricException(super.message, [super.code, super.statusCode]);
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message, [super.code, super.statusCode]);
}

/// Unknown/Generic exceptions
class UnknownException extends AppException {
  const UnknownException(super.message, [super.code, super.statusCode]);
}

/// Parse error response and return appropriate exception
AppException parseException(Map<String, dynamic> errorResponse) {
  final message =
      errorResponse['message'] as String? ?? 'Unknown error occurred';
  final code = errorResponse['code'] as String?;
  final statusCode = errorResponse['status_code'] as int?;

  // Map common HTTP status codes to exception types
  if (statusCode != null) {
    switch (statusCode) {
      case 400:
        return ValidationException(message, code, statusCode);
      case 401:
      case 403:
        return AuthException(message, code, statusCode);
      case 404:
        return NotFoundException(message, code, statusCode);
      case 409:
        return ConflictException(message, code, statusCode);
      case 408:
        return TimeoutException(message, code, statusCode);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(message, code, statusCode);
    }
  }

  // Default to generic AppException
  return UnknownException(message, code, statusCode);
}

/// Check if exception is network-related
bool isNetworkException(dynamic exception) {
  return exception is NetworkException ||
      exception.toString().contains('SocketException') ||
      exception.toString().contains('TimeoutException');
}

/// Check if exception is authentication-related
bool isAuthException(dynamic exception) {
  return exception is AuthException ||
      exception.toString().contains('401') ||
      exception.toString().contains('403');
}

/// Check if exception is validation-related
bool isValidationException(dynamic exception) {
  return exception is ValidationException ||
      exception.toString().contains('400');
}

/// Check if exception is server-related
bool isServerException(dynamic exception) {
  return exception is ServerException || exception.toString().contains('500');
}

/// Create appropriate exception from HTTP status code
AppException createExceptionFromStatus(
  int statusCode,
  String message, [
  String? code,
]) {
  switch (statusCode) {
    case 400:
      return ValidationException(message, code, statusCode);
    case 401:
    case 403:
      return AuthException(message, code, statusCode);
    case 404:
      return NotFoundException(message, code, statusCode);
    case 409:
      return ConflictException(message, code, statusCode);
    case 408:
      return TimeoutException(message, code, statusCode);
    case 500:
    case 502:
    case 503:
    case 504:
      return ServerException(message, code, statusCode);
    default:
      return UnknownException(message, code, statusCode);
  }
}

/// Handle different types of exceptions and return user-friendly messages
String handleException(dynamic exception) {
  if (exception is NetworkException) {
    return 'Network error: ${exception.message}. Please check your internet connection.';
  } else if (exception is AuthException) {
    return 'Authentication error: ${exception.message}. Please try logging in again.';
  } else if (exception is ValidationException) {
    return 'Validation error: ${exception.message}';
  } else if (exception is ServerException) {
    return 'Server error: ${exception.message}. Please try again later.';
  } else if (exception is TimeoutException) {
    return 'Request timeout: ${exception.message}. Please check your connection.';
  } else if (exception is NotFoundException) {
    return 'Not found: ${exception.message}';
  } else if (exception is ConflictException) {
    return 'Conflict: ${exception.message}';
  } else if (exception is PermissionException) {
    return 'Permission denied: ${exception.message}';
  } else if (exception is BiometricException) {
    return 'Biometric error: ${exception.message}';
  } else if (exception is CacheException) {
    return 'Cache error: ${exception.message}';
  } else if (exception is ParseException) {
    return 'Data parsing error: ${exception.message}';
  } else {
    return 'An unexpected error occurred: ${exception.toString()}';
  }
}
