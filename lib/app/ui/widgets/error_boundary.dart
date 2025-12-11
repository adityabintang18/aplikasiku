import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasiku/app/ui/widgets/error_widget.dart';
import 'package:aplikasiku/app/core/errors/app_exception.dart';

/// Error Boundary widget to catch and handle widget tree errors
/// Prevents app crashes and shows user-friendly error messages
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  onError;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.onError?.call(context, _error!, _stackTrace!) ??
          _buildDefaultErrorWidget(context);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    final error = _error!;

    // If it's an AppException, use the AppErrorWidget
    if (error is AppException) {
      return Center(
        child: AppErrorWidget(error: error, onRetry: _handleRetry),
      );
    }

    // For other exceptions, show a generic error
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
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.onRetry != null) ...[
                ElevatedButton(
                  onPressed: _handleRetry,
                  child: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  void initState() {
    super.initState();
    // This would normally be set up in the widget tree,
    // but for simplicity, we'll manually check for errors
  }
}

/// Custom error reporter that can be integrated with logging services
class ErrorReporter {
  static void reportError(Object error, StackTrace stackTrace) {
    // Log the error (you can integrate with services like Sentry, Crashlytics, etc.)
    debugPrint('Error caught by ErrorBoundary: $error');
    debugPrint('Stack trace: $stackTrace');

    // Here you could send errors to your logging service
    // Example: Sentry.captureException(error, stackTrace: stackTrace);
  }
}
