import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';
import 'package:aplikasiku/app/ui/widgets/error_widget.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'update_handler_service.dart';

/// Centralized error handling service for the application
class ErrorHandlerService extends GetxService {
  static ErrorHandlerService get to => Get.find<ErrorHandlerService>();

  final Logger _logger = Logger();

  /// Handle Dio exceptions and convert to appropriate AppException
  AppException handleDioException(DioException error) {
    _logger.e('DioException: ${error.message}', error: error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return AppExceptionUnknown(
          'Request was cancelled.',
          code: 'CANCELLED',
          originalError: error,
        );

      default:
        return AppExceptionUnknown(
          'An unexpected error occurred.',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }

  /// Handle HTTP response errors
  AppException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    switch (statusCode) {
      case 400:
        if (responseData is Map<String, dynamic>) {
          return ValidationException(
            responseData['message'] ?? 'Validation error',
            fieldErrors: _extractFieldErrors(responseData),
            code: 'VALIDATION_ERROR',
            originalError: error,
          );
        }
        return ApiException(
          'Bad request',
          statusCode: statusCode,
          responseData: responseData,
          code: 'BAD_REQUEST',
          originalError: error,
        );

      case 401:
        return AuthenticationException(
          'Your session has expired. Please log in again.',
          code: 'UNAUTHORIZED',
          originalError: error,
        );

      case 403:
        return AuthenticationException(
          'You do not have permission to perform this action.',
          code: 'FORBIDDEN',
          originalError: error,
        );

      case 404:
        return ApiException(
          'The requested resource was not found.',
          statusCode: statusCode,
          responseData: responseData,
          code: 'NOT_FOUND',
          originalError: error,
        );

      case 422:
        if (responseData is Map<String, dynamic>) {
          return ValidationException(
            responseData['message'] ?? 'Validation failed',
            fieldErrors: _extractFieldErrors(responseData),
            code: 'VALIDATION_ERROR',
            originalError: error,
          );
        }
        return ApiException(
          'Validation failed',
          statusCode: statusCode,
          responseData: responseData,
          code: 'VALIDATION_ERROR',
          originalError: error,
        );

      case 426:
        // Handle upgrade required - trigger update dialog
        _logger.w('Received 426 Upgrade Required - triggering update dialog');

        // Extract URLs from response data
        String? updateUrl;
        String? apkUrl;

        if (responseData is Map<String, dynamic>) {
          updateUrl = responseData['storeUrl'] ??
              responseData['update_url'] ??
              responseData['store_url'];
          apkUrl = responseData['apkUrl']; // Direct APK download URL

          _logger.i(
              'ErrorHandlerService: Extracted from API - updateUrl: $updateUrl, apkUrl: $apkUrl');
        }

        UpdateHandlerService.handleUpdateRequired(
          dioException: error,
          customMessage: responseData is Map<String, dynamic>
              ? responseData['message']
              : 'A new version of the app is available. Please update to continue.',
          updateUrl: updateUrl,
          apkUrl: apkUrl,
        );
        return ApiException(
          'App update required',
          statusCode: statusCode,
          responseData: responseData,
          code: 'UPGRADE_REQUIRED',
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ApiException(
          'Server is temporarily unavailable. Please try again later.',
          statusCode: statusCode,
          responseData: responseData,
          code: 'SERVER_ERROR',
          originalError: error,
        );

      default:
        return ApiException(
          'An error occurred while processing your request.',
          statusCode: statusCode,
          responseData: responseData,
          code: 'HTTP_ERROR',
          originalError: error,
        );
    }
  }

  /// Extract field errors from validation response
  Map<String, List<String>> _extractFieldErrors(Map<String, dynamic> response) {
    final fieldErrors = <String, List<String>>{};

    if (response.containsKey('errors') && response['errors'] is Map) {
      final errors = response['errors'] as Map<String, dynamic>;
      for (final entry in errors.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is List) {
          fieldErrors[key] = value.map((e) => e.toString()).toList();
        } else if (value is String) {
          fieldErrors[key] = [value];
        }
      }
    }

    return fieldErrors;
  }

  /// Show error dialog to user
  void showErrorDialog(AppException error, {VoidCallback? onRetry}) {
    Get.dialog(
      ShadDialog(
        title: Text(_getErrorTitle(error)),
        description: Text(_getErrorMessage(error)),
        child: AppErrorWidget(error: error, onRetry: onRetry),
      ),
      barrierDismissible: false,
    );
  }

  /// Show error as snackbar
  void showErrorSnackbar(AppException error) {
    Get.snackbar(
      _getErrorTitle(error),
      _getErrorMessage(error),
      backgroundColor: Colors.red.withOpacity(0.1),
      colorText: Colors.red,
      icon: Icon(_getErrorIcon(error)),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show success message
  void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green.withOpacity(0.1),
      colorText: Colors.green,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// Get error icon based on exception type
  IconData _getErrorIcon(AppException error) {
    switch (error.runtimeType) {
      case NetworkException:
        return Icons.wifi_off;
      case ApiException:
        return Icons.cloud_off;
      case AuthenticationException:
        return Icons.lock;
      case ValidationException:
        return Icons.warning;
      default:
        return Icons.error_outline;
    }
  }

  /// Get error title based on exception type
  String _getErrorTitle(AppException error) {
    switch (error.runtimeType) {
      case NetworkException:
        return 'Connection Error';
      case ApiException:
        return 'Server Error';
      case AuthenticationException:
        return 'Authentication Error';
      case ValidationException:
        return 'Validation Error';
      default:
        return 'Error';
    }
  }

  /// Get error message based on exception type
  String _getErrorMessage(AppException error) {
    if (error.message.isNotEmpty) {
      return error.message;
    }

    switch (error.runtimeType) {
      case NetworkException:
        return 'Please check your internet connection and try again.';
      case ApiException:
        final statusCode = (error as ApiException).statusCode;
        switch (statusCode) {
          case 401:
            return 'Your session has expired. Please log in again.';
          case 403:
            return 'You do not have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 426:
            return 'App update required. Please update to continue.';
          case 500:
            return 'Server is temporarily unavailable. Please try again later.';
          default:
            return 'An error occurred while processing your request.';
        }
      case AuthenticationException:
        return 'Please log in to continue.';
      case ValidationException:
        return 'Please check your input and try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Generic error handler for Future operations
  Future<T> handleError<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool showDialog = false,
    bool showSnackbar = false,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } catch (error) {
      _logger.e('Error in operation', error: error);

      AppException exception;
      if (error is DioException) {
        exception = handleDioException(error);
      } else if (error is AppException) {
        exception = error;
      } else {
        exception = AppExceptionUnknown(error.toString(), originalError: error);
      }

      // SPECIAL HANDLING: Don't catch upgrade required errors
      // Let them propagate so controllers can handle them properly
      if (exception is ApiException && exception.code == 'UPGRADE_REQUIRED') {
        _logger.w(
            'ErrorHandlerService: UPGRADE_REQUIRED exception detected, re-throwing to trigger dialog');
        // Update dialog is already shown by UpdateHandlerService
        // Re-throw the exception so it can be caught by controller if needed
        rethrow;
      }

      if (showDialog) {
        showErrorDialog(exception, onRetry: onRetry);
      } else if (showSnackbar) {
        showErrorSnackbar(exception);
      }

      return fallbackValue ?? (throw exception);
    }
  }
}
