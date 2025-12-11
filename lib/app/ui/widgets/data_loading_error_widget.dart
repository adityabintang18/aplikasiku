import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:aplikasiku/app/controllers/statistic_controller.dart';
import 'package:aplikasiku/app/controllers/home_controller.dart';

class DataLoadingErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final bool showDiagnosticButton;

  const DataLoadingErrorWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.showDiagnosticButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Data Loading Failed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onRetry != null) ...[
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (showDiagnosticButton)
                OutlinedButton.icon(
                  onPressed: () => _showDiagnosticInfo(context),
                  icon: const Icon(Icons.dashboard, size: 16),
                  label: const Text('Diagnostic'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDiagnosticInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Data Loading Diagnostic'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Common Issues & Solutions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '1. 🔐 Authentication Issue',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              Text('• Your session may have expired'),
              Text('• Solution: Log out and log back in'),
              SizedBox(height: 12),
              Text(
                '2. 🌐 Network Connection',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              Text('• Check your internet connection'),
              Text('• Try accessing other apps to verify connectivity'),
              SizedBox(height: 12),
              Text(
                '3. 🖥️ Backend Server',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              Text('• The server might be temporarily down'),
              Text('• Try again in a few minutes'),
              SizedBox(height: 12),
              Text(
                '4. 📱 App Version',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              Text('• You might need to update the app'),
              Text('• Check for updates in your app store'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DataLoadingStateHandler extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const DataLoadingStateHandler({
    super.key,
    required this.child,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return DataLoadingErrorWidget(
        errorMessage: errorMessage!,
        onRetry: onRetry,
      );
    }

    return child;
  }
}
