import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../data/services/version_service.dart';

class VersionController extends GetxController {
  final VersionService _versionService = VersionService();
  final Logger _logger = Logger();

  final RxBool isUpdateAvailable = false.obs;
  final RxBool isCheckingForUpdate = false.obs;
  final RxString updateMessage = ''.obs;
  final RxString storeUrl = ''.obs;
  final RxString apkUrl = ''.obs;
  final RxString currentVersion = ''.obs;

  /// Check if update is required
  Future<void> checkForUpdate() async {
    _logger.i('VersionController: Checking for app updates');
    isCheckingForUpdate.value = true;

    try {
      // Get current version from environment
      final version = await _versionService.getCurrentVersion();
      currentVersion.value = version;
      _logger.i('VersionController: Current version: $version');

      // Check for updates
      final result = await _versionService.checkForUpdate(
        platform: 'android',
        currentVersion: version,
      );

      if (result['success'] == true) {
        isUpdateAvailable.value = result['requiredUpdate'] ?? false;
        updateMessage.value = result['message'] ?? '';
        storeUrl.value = result['storeUrl'] ?? '';
        apkUrl.value = result['apkUrl'] ?? '';

        _logger.i(
          'VersionController: Update check completed - Available: ${isUpdateAvailable.value}',
        );
        _logger.i('VersionController: Update message: ${updateMessage.value}');
      } else {
        _logger.w('VersionController: Failed to check for updates');
        isUpdateAvailable.value = false;
        updateMessage.value =
            result['message'] ?? 'Failed to check for updates';
      }
    } catch (e) {
      _logger.e('VersionController: Error checking for updates: $e');
      isUpdateAvailable.value = false;
      updateMessage.value = 'Error checking for updates: ${e.toString()}';
    } finally {
      isCheckingForUpdate.value = false;
    }
  }

  /// Reset update status
  void resetUpdateStatus() {
    isUpdateAvailable.value = false;
    updateMessage.value = '';
    storeUrl.value = '';
    apkUrl.value = '';
    isCheckingForUpdate.value = false;
  }

  /// Check if update is available and user hasn't dismissed it
  Future<bool> shouldShowUpdateDialog() async {
    await checkForUpdate();
    return isUpdateAvailable.value;
  }

  /// Parse current version
  Map<String, String> getCurrentVersionInfo() {
    return VersionService.parseVersion(currentVersion.value);
  }

  /// Compare with other version
  int compareWithVersion(String otherVersion) {
    return VersionService.compareVersions(currentVersion.value, otherVersion);
  }

  /// Check if current version is newer than provided version
  bool isNewerThan(String otherVersion) {
    return compareWithVersion(otherVersion) > 0;
  }

  /// Check if current version is older than provided version
  bool isOlderThan(String otherVersion) {
    return compareWithVersion(otherVersion) < 0;
  }

  /// Check if current version is same as provided version
  bool isSameAs(String otherVersion) {
    return compareWithVersion(otherVersion) == 0;
  }

  /// Format version for display
  String formatVersionForDisplay() {
    final versionInfo = getCurrentVersionInfo();
    return 'v${versionInfo['versionName']} (Build ${versionInfo['buildNumber']})';
  }

  @override
  void onInit() {
    super.onInit();
    _logger.d('VersionController: Initializing');
    // Optionally check for updates on app start
    // checkForUpdate();
  }

  @override
  void onClose() {
    super.onClose();
    _logger.d('VersionController: Closing');
  }
}
