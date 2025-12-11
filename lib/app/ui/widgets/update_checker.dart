import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../controllers/version_controller.dart';
import 'update_dialog.dart';

/// Service untuk melakukan update check secara otomatis
class UpdateChecker {
  static final Logger _logger = Logger();
  static bool _hasCheckedOnStart = false;

  /// Check for updates when app starts (bisa dipanggil dari main.dart)
  static Future<void> checkOnAppStart() async {
    if (_hasCheckedOnStart) {
      _logger.d('UpdateChecker: Already checked for updates on app start');
      return;
    }

    _logger.i('UpdateChecker: Checking for updates on app start');

    try {
      // Initialize version controller if not already
      if (!Get.isRegistered<VersionController>()) {
        Get.put(VersionController());
      }

      final versionController = Get.find<VersionController>();

      // Check for updates
      await versionController.checkForUpdate();

      // Show update dialog if available
      if (versionController.isUpdateAvailable.value) {
        _logger.i('UpdateChecker: Update available, showing dialog');
        // Delay dialog to let app finish loading
        Future.delayed(const Duration(seconds: 2), () {
          showUpdateDialog();
        });
      } else {
        _logger.i('UpdateChecker: No update available');
      }

      _hasCheckedOnStart = true;
    } catch (e) {
      _logger.e('UpdateChecker: Error during app start update check: $e');
    }
  }

  /// Manual check for updates (bisa dipanggil dari settings atau manual trigger)
  static Future<void> checkManually() async {
    _logger.i('UpdateChecker: Manual update check triggered');

    try {
      // Ensure controller is initialized
      if (!Get.isRegistered<VersionController>()) {
        Get.put(VersionController());
      }

      final versionController = Get.find<VersionController>();

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Check for updates
      await versionController.checkForUpdate();

      // Close loading
      Get.back();

      // Show update dialog if available
      if (versionController.isUpdateAvailable.value) {
        showUpdateDialog();
      } else {
        // Show "no update" message
        Get.snackbar(
          'No Update Available',
          versionController.updateMessage.value.isNotEmpty
              ? versionController.updateMessage.value
              : 'Your app is up to date!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      _logger.e('UpdateChecker: Error during manual update check: $e');
      Get.snackbar(
        'Update Check Failed',
        'Could not check for updates. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Check for updates in background (silent check)
  static Future<Map<String, dynamic>> checkInBackground() async {
    _logger.d('UpdateChecker: Background update check');

    try {
      if (!Get.isRegistered<VersionController>()) {
        Get.put(VersionController());
      }

      final versionController = Get.find<VersionController>();
      await versionController.checkForUpdate();

      return {
        'hasUpdate': versionController.isUpdateAvailable.value,
        'currentVersion': versionController.currentVersion.value,
        'message': versionController.updateMessage.value,
      };
    } catch (e) {
      _logger.e('UpdateChecker: Error during background update check: $e');
      return {'hasUpdate': false, 'error': e.toString()};
    }
  }

  /// Reset flag so next app start will check for updates again
  static void resetAppStartCheck() {
    _hasCheckedOnStart = false;
    _logger.d('UpdateChecker: Reset app start check flag');
  }

  /// Check if already checked on app start
  static bool get hasCheckedOnStart => _hasCheckedOnStart;
}

/// Widget untuk update check button (bisa digunakan di settings)
class UpdateCheckButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;

  const UpdateCheckButton({super.key, this.onPressed, this.text});

  @override
  Widget build(BuildContext context) {
    final versionController = Get.find<VersionController>();

    return Obx(
      () => ShadButton.outline(
        onPressed: versionController.isCheckingForUpdate.value
            ? null
            : (onPressed ?? UpdateChecker.checkManually),
        child: versionController.isCheckingForUpdate.value
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Checking...'),
                ],
              )
            : Text(text ?? 'Check for Updates'),
      ),
    );
  }
}

/// Widget untuk display version info
class VersionInfoWidget extends StatelessWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final versionController = Get.find<VersionController>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last Check:'),
                Obx(
                  () => Text(
                    versionController.isCheckingForUpdate.value
                        ? 'Checking...'
                        : 'Recently checked',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
