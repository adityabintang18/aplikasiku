import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

/// Global update required dialog that works across all pages - FORCED UPDATE VERSION
class UpdateRequiredDialog extends StatelessWidget {
  final String? customMessage;
  final String? updateUrl;
  final String? apkUrl; // Direct APK download URL
  final VoidCallback? onDismissed;
  final bool isForced; // Whether this is a forced update

  const UpdateRequiredDialog({
    super.key,
    this.customMessage,
    this.updateUrl,
    this.apkUrl,
    this.onDismissed,
    this.isForced = true, // Default to forced update
  });

  @override
  Widget build(BuildContext context) {
    final Logger _logger = Logger();

    // Determine which URL to use - prefer APK URL for direct download
    final String downloadUrl = apkUrl ??
        updateUrl ??
        'https://github.com/adityabintang18/Aplikasiku/releases';

    final String storeUrl =
        updateUrl ?? 'https://github.com/adityabintang18/Aplikasiku/releases';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isForced ? 'Update Required' : 'Update Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customMessage ??
                (isForced
                    ? 'A new version of the app is required to continue using the app. Please update now.'
                    : 'A new version of the app is available. Please update to continue using the app.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isForced
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isForced ? Icons.warning : Icons.info_outline,
                  color: isForced
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isForced
                        ? 'Update is mandatory to continue using the app.'
                        : 'This update includes important improvements and bug fixes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isForced
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Show download info
          if (apkUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.download,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct APK download will start (recommended)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Show fallback info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If download fails, releases page will open',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Remove "Later" button for forced updates
        if (!isForced)
          TextButton(
            onPressed: () {
              _logger.i('UpdateRequiredDialog: User dismissed update dialog');
              Navigator.of(context).pop();
              onDismissed?.call();
            },
            child: const Text('Later'),
          ),
        ElevatedButton(
          onPressed: () async {
            _logger.i('UpdateRequiredDialog: User clicked update button');

            try {
              // First try to open APK URL directly for download
              if (apkUrl != null) {
                _logger.i(
                    'UpdateRequiredDialog: Attempting to open APK download: $apkUrl');
                await _openApkDownload(
                    context, apkUrl!); // Use ! to assert non-null
              } else {
                // Fallback to store page
                _logger.i(
                    'UpdateRequiredDialog: No APK URL, opening releases page: $storeUrl');
                await _openStorePage(context, storeUrl);
              }
            } catch (e) {
              _logger
                  .e('UpdateRequiredDialog: Error during update process: $e');

              // Fallback to store page on error
              _logger.i('UpdateRequiredDialog: Falling back to store page');
              await _openStorePage(context, storeUrl);
            }
          },
          child: const Text('Update Now'),
        ),
      ],
    );
  }

  Future<void> _openApkDownload(BuildContext context, String apkUrl) async {
    try {
      // Try to launch the APK URL directly
      if (await canLaunchUrl(Uri.parse(apkUrl))) {
        await launchUrl(
          Uri.parse(apkUrl),
          mode: LaunchMode.externalApplication,
        );
        Logger().i(
            'UpdateRequiredDialog: Successfully opened APK download: $apkUrl');

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('APK download started! Check your downloads folder.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Cannot open APK URL');
      }
    } catch (e) {
      Logger().e('UpdateRequiredDialog: Error opening APK download: $e');

      // Show error and fallback to store
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e. Opening releases page...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Fallback to store page
      final storeUrl =
          updateUrl ?? 'https://github.com/adityabintang18/Aplikasiku/releases';
      await _openStorePage(context, storeUrl);
    }
  }

  Future<void> _openStorePage(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        Logger().i('UpdateRequiredDialog: Successfully opened store URL: $url');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opened releases page! Download the latest APK.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Cannot open store URL');
      }
    } catch (e) {
      Logger().e('UpdateRequiredDialog: Error launching store URL: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open update link. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Helper function to show update required dialog globally using GetX - FORCED VERSION
Future<void> showUpdateRequiredDialog({
  String? message,
  String? updateUrl,
  String? apkUrl,
  VoidCallback? onDismissed,
  bool isForced = true, // Default to forced update
}) async {
  await Get.dialog(
    UpdateRequiredDialog(
      customMessage: message,
      updateUrl: updateUrl,
      apkUrl: apkUrl,
      onDismissed: onDismissed,
      isForced: isForced,
    ),
    barrierDismissible: false, // Prevent dismissal by tapping outside
    name: 'update-required-dialog',
  );
}
