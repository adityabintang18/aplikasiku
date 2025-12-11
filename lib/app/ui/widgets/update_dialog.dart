import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../../controllers/version_controller.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final versionController = Get.find<VersionController>();
    final Logger _logger = Logger();

    return ShadDialog(
      title: const Text('Update Available'),
      description: Obx(() => Text(versionController.updateMessage.value)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Version info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Version:'),
                    Text(
                      versionController.formatVersionForDisplay(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Latest Version:'),
                    Obx(
                      () => Text(
                        'v${versionController.getCurrentVersionInfo()['versionName']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Update buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShadButton.outline(
                onPressed: () {
                  _logger.i('UpdateDialog: User dismissed update');
                  Get.back();
                  // Optionally save dismissal state
                },
                child: const Text('Later'),
              ),
              ShadButton(
                onPressed: () async {
                  try {
                    _logger.i('UpdateDialog: User clicked update button');
                    final storeUrl = versionController.storeUrl.value;
                    final apkUrl = versionController.apkUrl.value;

                    if (apkUrl.isNotEmpty) {
                      // Direct APK download
                      _logger.i('UpdateDialog: Downloading APK from: $apkUrl');
                      if (await canLaunchUrl(Uri.parse(apkUrl))) {
                        await launchUrl(
                          Uri.parse(apkUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _logger.e('UpdateDialog: Cannot launch APK URL');
                        Get.snackbar(
                          'Error',
                          'Cannot open download link',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    } else if (storeUrl.isNotEmpty) {
                      // Open app store/release page
                      _logger.i('UpdateDialog: Opening store page: $storeUrl');
                      if (await canLaunchUrl(Uri.parse(storeUrl))) {
                        await launchUrl(
                          Uri.parse(storeUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        _logger.e('UpdateDialog: Cannot launch store URL');
                        Get.snackbar(
                          'Error',
                          'Cannot open store link',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    } else {
                      _logger.e('UpdateDialog: No valid URL found');
                      Get.snackbar(
                        'Error',
                        'No download link available',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }

                    Get.back();
                  } catch (e) {
                    _logger.e('UpdateDialog: Error launching update: $e');
                    Get.snackbar(
                      'Error',
                      'Failed to open update link',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Update Now'),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Additional info
          const Text(
            'Make sure to download the latest version for new features and improvements.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper function to show update dialog
Future<void> showUpdateDialog() async {
  final versionController = Get.find<VersionController>();

  // Check if update is available first
  await versionController.checkForUpdate();

  if (versionController.isUpdateAvailable.value) {
    Get.dialog(const UpdateDialog());
  }
}

/// Helper function to show update dialog with custom title and message
Future<void> showCustomUpdateDialog({
  required String title,
  required String message,
  required String updateUrl,
}) async {
  await Get.dialog(
    ShadDialog(
      title: Text(title),
      description: Text(message),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShadButton.outline(
                onPressed: () => Get.back(),
                child: const Text('Later'),
              ),
              ShadButton(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(updateUrl))) {
                    await launchUrl(
                      Uri.parse(updateUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  Get.back();
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
