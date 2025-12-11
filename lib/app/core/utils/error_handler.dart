// Error handling utility for consistent error management
import '../exceptions/app_exception.dart';

class ErrorHandler {
  /// Handle different types of errors and return user-friendly messages
  static String handle(dynamic error) {
    if (error is AppException) {
      return _handleAppException(error);
    } else if (error is String) {
      return _handleStringError(error);
    } else if (error is Exception) {
      return _handleException(error);
    } else {
      return _handleUnknownError(error);
    }
  }

  /// Handle AppException instances
  static String _handleAppException(AppException exception) {
    switch (exception) {
      case NetworkException():
        return _getNetworkErrorMessage(exception);
      case AuthException():
        return _getAuthErrorMessage(exception);
      case BiometricException():
        return _getBiometricErrorMessage(exception);
      case ValidationException():
        return exception.message;
      case ServerException():
        return _getServerErrorMessage(exception);
      case CacheException():
        return 'Data storage error. Please try again.';
      case PermissionException():
        return 'Permission denied. Please check app permissions.';
      case TimeoutException():
        return 'Request timed out. Please check your connection and try again.';
      default:
        return exception.message;
    }
  }

  /// Handle string errors
  static String _handleStringError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socket')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorLower.contains('unauthorized') ||
        errorLower.contains('401')) {
      return 'Authentication failed. Please login again.';
    } else if (errorLower.contains('forbidden') || errorLower.contains('403')) {
      return 'Access denied. You don\'t have permission to perform this action.';
    } else if (errorLower.contains('not found') || errorLower.contains('404')) {
      return 'The requested resource was not found.';
    } else if (errorLower.contains('server error') ||
        errorLower.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorLower.contains('validation') ||
        errorLower.contains('invalid')) {
      return error;
    } else {
      return error;
    }
  }

  /// Handle Exception instances
  static String _handleException(Exception exception) {
    return _handleStringError(exception.toString());
  }

  /// Handle unknown error types
  static String _handleUnknownError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('null') || errorString.contains('nullpointer')) {
      return 'An unexpected error occurred. Please try again.';
    } else if (errorString.contains('format') ||
        errorString.contains('parse')) {
      return 'Data format error. Please check your input.';
    } else if (errorString.contains('permission') ||
        errorString.contains('denied')) {
      return 'Permission denied. Please check app permissions.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get specific network error messages
  static String _getNetworkErrorMessage(NetworkException exception) {
    if (exception.message.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (exception.message.contains('dns')) {
      return 'Cannot connect to server. Please check your internet connection.';
    } else if (exception.message.contains('ssl') ||
        exception.message.contains('certificate')) {
      return 'Security error. Please check your internet connection.';
    } else {
      return 'Network error. Please check your internet connection and try again.';
    }
  }

  /// Get specific authentication error messages
  static String _getAuthErrorMessage(AuthException exception) {
    if (exception.message.contains('invalid credentials') ||
        exception.message.contains('wrong password') ||
        exception.message.contains('incorrect password')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (exception.message.contains('user not found') ||
        exception.message.contains('email not found')) {
      return 'User not found. Please check your email address.';
    } else if (exception.message.contains('token') ||
        exception.message.contains('expired')) {
      return 'Session expired. Please login again.';
    } else if (exception.message.contains('disabled') ||
        exception.message.contains('inactive')) {
      return 'Account is disabled. Please contact support.';
    } else if (exception.message.contains('locked') ||
        exception.message.contains('suspended')) {
      return 'Account is locked. Please contact support.';
    } else {
      return exception.message;
    }
  }

  /// Get specific biometric error messages
  static String _getBiometricErrorMessage(BiometricException exception) {
    if (exception.message.contains('not available') ||
        exception.message.contains('not supported')) {
      return 'Biometric authentication is not available on this device.';
    } else if (exception.message.contains('not enrolled') ||
        exception.message.contains('no biometric data')) {
      return 'No biometric data found. Please set up fingerprint or face ID first.';
    } else if (exception.message.contains('locked out') ||
        exception.message.contains('too many attempts')) {
      return 'Biometric authentication is temporarily locked. Please try again later.';
    } else if (exception.message.contains('user cancel') ||
        exception.message.contains('cancelled')) {
      return 'Biometric authentication was cancelled.';
    } else if (exception.message.contains('not enabled')) {
      return 'Biometric login is not enabled. Please enable it in settings.';
    } else {
      return exception.message;
    }
  }

  /// Get specific server error messages
  static String _getServerErrorMessage(ServerException exception) {
    switch (exception.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return exception.message;
    }
  }

  /// Get error code from exception
  static String? getErrorCode(dynamic error) {
    if (error is AppException) {
      return error.code;
    }
    return null;
  }

  /// Check if error is recoverable (user can retry)
  static bool isRecoverableError(dynamic error) {
    if (error is AppException) {
      switch (error) {
        case NetworkException():
        case TimeoutException():
        case ServerException():
          return true;
        default:
          return false;
      }
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  /// Get retry delay for recoverable errors
  static Duration getRetryDelay(dynamic error) {
    if (error is NetworkException && error.message.contains('timeout')) {
      return const Duration(seconds: 2);
    } else if (error is TimeoutException) {
      return const Duration(seconds: 3);
    } else if (error is ServerException) {
      switch (error.statusCode) {
        case 429: // Too many requests
          return const Duration(seconds: 5);
        case 500:
        case 502:
        case 503:
        case 504:
          return const Duration(seconds: 2);
        default:
          return const Duration(seconds: 1);
      }
    }
    return const Duration(seconds: 1);
  }
}
