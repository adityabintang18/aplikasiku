import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import 'update_handler_service.dart';
import '../services/error_handler_service.dart';
import '../../utils/exceptions.dart';
import '../../data/services/version_service.dart';

/// Global update checker that forces users to update on all pages
class GlobalUpdateChecker {
  static final Logger _logger = Logger();
  static final ErrorHandlerService _errorHandler = ErrorHandlerService.to;
  static final VersionService _versionService = VersionService();

  static bool _isUpdateInProgress = false;
  static bool _hasCheckedForUpdate = false;
  static DateTime? _lastUpdateCheck;

  /// Check for updates and force user to update if required
  static Future<void> checkForUpdatesAndForceUpdate({
    String? customMessage,
    bool showProgress = true,
  }) async {
    // Prevent multiple simultaneous checks
    if (_isUpdateInProgress) {
      _logger.d('GlobalUpdateChecker: Update check already in progress');
      return;
    }

    _isUpdateInProgress = true;

    try {
      _logger.i('GlobalUpdateChecker: Starting forced update check');

      // Check if we recently checked for updates (avoid too frequent checks)
      if (_lastUpdateCheck != null &&
          DateTime.now().difference(_lastUpdateCheck!).inMinutes < 5) {
        _logger
            .d('GlobalUpdateChecker: Skipping update check (checked recently)');
        return;
      }

      final currentVersion = await _versionService.getVersionName();
      final platform = GetPlatform.isAndroid ? 'android' : 'ios';

      final result = await _errorHandler.handleError(
        () => _versionService.checkForUpdate(
          platform: platform,
          currentVersion: currentVersion,
        ),
        showSnackbar: false,
      );

      _lastUpdateCheck = DateTime.now();
      _hasCheckedForUpdate = true;

      if (result != null && result is Map<String, dynamic>) {
        final requiredUpdate = result['requiredUpdate'] ?? false;

        if (requiredUpdate) {
          _logger.w(
              'GlobalUpdateChecker: Update required - forcing user to update');

          final message = result['message'] ??
              customMessage ??
              'A new version of the app is required to continue. Please update now.';
          final storeUrl =
              result['storeUrl'] ?? result['update_url'] ?? result['apkUrl'];

          UpdateHandlerService.handleUpdateRequired(
            customMessage: message,
            updateUrl: storeUrl,
          );
        } else {
          _logger.i('GlobalUpdateChecker: No update required');
        }
      }
    } catch (e) {
      _logger.e('GlobalUpdateChecker: Error checking for updates', error: e);

      // Don't fail silently - still try to show dialog if it's an update error
      if (e is AppUpdateRequiredException ||
          (e is DioException && e.response?.statusCode == 426)) {
        _logger.w('GlobalUpdateChecker: Update required detected during check');

        final message = customMessage ??
            'A new version of the app is required to continue. Please update now.';

        UpdateHandlerService.handleUpdateRequired(
          appException: e is AppUpdateRequiredException ? e : null,
          dioException: e is DioException ? e : null,
          customMessage: message,
        );
      }
    } finally {
      _isUpdateInProgress = false;
    }
  }

  /// Check for updates on every page entry (can be called from page widgets)
  static Future<void> checkOnPageEnter() async {
    _logger.i('GlobalUpdateChecker: Checking for updates on page enter');
    await checkForUpdatesAndForceUpdate();
  }

  /// Force immediate update check (for critical situations)
  static Future<void> forceImmediateUpdate() async {
    _logger.w('GlobalUpdateChecker: Forcing immediate update check');
    _lastUpdateCheck = null; // Clear last check time
    await checkForUpdatesAndForceUpdate(
      customMessage: 'Update is required to continue using the app.',
    );
  }

  /// Check if update check is currently in progress
  static bool get isUpdateInProgress => _isUpdateInProgress;

  /// Check if we have already checked for updates
  static bool get hasCheckedForUpdate => _hasCheckedForUpdate;

  /// Get last update check time
  static DateTime? get lastUpdateCheck => _lastUpdateCheck;

  /// Reset update check state (for testing)
  static void reset() {
    _isUpdateInProgress = false;
    _hasCheckedForUpdate = false;
    _lastUpdateCheck = null;
    _logger.d('GlobalUpdateChecker: Reset update check state');
  }
}
