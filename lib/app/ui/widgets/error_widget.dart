import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';

/// A reusable error widget that can display different types of errors
/// with appropriate messaging and recovery actions
class AppErrorWidget extends StatelessWidget {
  final AppException error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? customMessage;
  final Widget? customAction;

  const AppErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.customMessage,
    this.customAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getErrorIcon(), color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _getErrorTitle(),
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            customMessage ?? _getErrorMessage(),
            style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (error is ValidationException &&
              (error as ValidationException).fieldErrors != null) ...[
            const SizedBox(height: 12),
            _buildValidationErrors((error as ValidationException).fieldErrors!),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onRetry != null) ...[
                ShadButton.outline(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
              ],
              if (customAction != null) customAction!,
              if (onDismiss != null) ...[
                const SizedBox(width: 12),
                ShadButton.ghost(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationErrors(Map<String, List<String>> fieldErrors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fieldErrors.entries.expand((entry) {
          return [
            Text(
              '${entry.key}:',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            ...entry.value.map(
              (error) => Text(
                '• $error',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ];
        }).toList(),
      ),
    );
  }

  IconData _getErrorIcon() {
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

  String _getErrorTitle() {
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
        return 'Something went wrong';
    }
  }

  String _getErrorMessage() {
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
}

/// Network error widget specifically for network connectivity issues
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({Key? key, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      error: NetworkException('No internet connection'),
      onRetry: onRetry,
      customMessage: 'Please check your internet connection and try again.',
    );
  }
}

/// API error widget for server-side errors
class ApiErrorWidget extends StatelessWidget {
  final ApiException error;
  final VoidCallback? onRetry;

  const ApiErrorWidget({Key? key, required this.error, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(error: error, onRetry: onRetry);
  }
}

/// Empty state widget for when there's no data to display
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.withOpacity(0.6)),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
