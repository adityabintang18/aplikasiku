import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../../ui/widgets/update_required_dialog.dart';
import '../../utils/exceptions.dart';

/// Service to handle app update requirements across the entire app
class UpdateHandlerService {
  static final Logger _logger = Logger();
  static bool _isDialogShowing = false;
  static String? _currentUpdateUrl;
  static String? _currentApkUrl;

  /// Handle 426 Upgrade Required response from API
  static void handleUpdateRequired({
    DioException? dioException,
    AppUpdateRequiredException? appException,
    String? customMessage,
    String? updateUrl,
    String? apkUrl, // Direct APK download URL
  }) {
    _logger.w('UpdateHandlerService: Handling update required');

    if (_isDialogShowing) {
      _logger.d(
          'UpdateHandlerService: Update dialog already showing, ignoring duplicate request');
      return;
    }

    // Store the URLs for later use
    if (updateUrl != null) {
      _currentUpdateUrl = updateUrl;
    }
    if (apkUrl != null) {
      _currentApkUrl = apkUrl;
    }

    // Extract message and URLs from exception if available
    String? message = customMessage;
    String? url = updateUrl;
    String? apk = apkUrl;

    if (appException != null) {
      message ??= appException.message;
    }

    // Extract from API response (supports both formats)
    if (dioException?.response?.data != null) {
      final responseData = dioException!.response!.data;

      // Support new API format
      if (responseData is Map<String, dynamic>) {
        message ??= responseData['message'] ??
            'A new version of the app is available. Please update to continue.';
        url ??= responseData['storeUrl'] ??
            responseData['update_url'] ??
            responseData['apkUrl'];
        apk ??= responseData['apkUrl']; // Prefer apkUrl for direct download

        _logger.i(
            'UpdateHandlerService: Extracted from API - message: $message, url: $url, apkUrl: $apk');
      }
    }

    _logger.i(
        'UpdateHandlerService: Final prepared - message: $message, url: $url, apkUrl: $apk');
    _showUpdateDialog(message: message, updateUrl: url, apkUrl: apk);
  }

  /// Show update dialog with proper error handling
  static void _showUpdateDialog({
    String? message,
    String? updateUrl,
    String? apkUrl,
  }) {
    _logger.i('UpdateHandlerService: Entering _showUpdateDialog');

    _isDialogShowing = true;

    // Try multiple approaches to show the dialog
    _tryShowDialog1(message: message, updateUrl: updateUrl, apkUrl: apkUrl);
  }

  /// Method 1: Try GetX dialog with context check
  static void _tryShowDialog1({
    String? message,
    String? updateUrl,
    String? apkUrl,
  }) {
    _logger.i('UpdateHandlerService: Attempting Method 1: GetX dialog');

    try {
      if (Get.context != null) {
        _logger
            .i('UpdateHandlerService: Get.context available, showing dialog');
        Get.dialog(
          UpdateRequiredDialog(
            customMessage: message,
            updateUrl: updateUrl ?? _currentUpdateUrl,
            apkUrl: apkUrl ?? _currentApkUrl,
            onDismissed: () {
              _logger.i('UpdateHandlerService: User dismissed update dialog');
              _isDialogShowing = false;
              _currentUpdateUrl = null;
              _currentApkUrl = null;
            },
          ),
          barrierDismissible: false,
          name: 'update-required-dialog',
        );
        _logger.i('UpdateHandlerService: Method 1 successful');
      } else {
        _logger.w('UpdateHandlerService: Get.context is null, trying Method 2');
        _tryShowDialog2(message: message, updateUrl: updateUrl, apkUrl: apkUrl);
      }
    } catch (e, stackTrace) {
      _logger.e('UpdateHandlerService: Method 1 failed: $e');
      _logger.e('UpdateHandlerService: Stack trace: $stackTrace');
      _tryShowDialog2(message: message, updateUrl: updateUrl, apkUrl: apkUrl);
    }
  }

  /// Method 2: Try WidgetsBinding with delayed execution
  static void _tryShowDialog2({
    String? message,
    String? updateUrl,
    String? apkUrl,
  }) {
    _logger.i(
        'UpdateHandlerService: Attempting Method 2: WidgetsBinding with delay');

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logger.i('UpdateHandlerService: Post-frame callback executing');

        // Check if we have a valid context
        BuildContext? context = Get.context;

        // If Get.context is null, try to find an alternative way
        if (context == null) {
          // Try using the navigator key approach
          try {
            final navigatorState = navigatorKey.currentState;
            if (navigatorState != null && navigatorState.context != null) {
              context = navigatorState.context;
              _logger
                  .i('UpdateHandlerService: Found context via navigator key');
            }
          } catch (e) {
            _logger.w(
                'UpdateHandlerService: Could not get context via navigator key: $e');
          }
        }

        if (context != null) {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => UpdateRequiredDialog(
                customMessage: message,
                updateUrl: updateUrl ?? _currentUpdateUrl,
                apkUrl: apkUrl ?? _currentApkUrl,
                onDismissed: () {
                  _logger.i(
                      'UpdateHandlerService: User dismissed update dialog (Method 2)');
                  _isDialogShowing = false;
                  _currentUpdateUrl = null;
                  _currentApkUrl = null;
                },
              ),
            );
            _logger.i('UpdateHandlerService: Method 2 successful');
          } catch (e) {
            _logger
                .e('UpdateHandlerService: Method 2 dialog creation failed: $e');
            _tryShowDialog3(
                message: message, updateUrl: updateUrl, apkUrl: apkUrl);
          }
        } else {
          _logger.w('UpdateHandlerService: No context available in Method 2');
          _tryShowDialog3(
              message: message, updateUrl: updateUrl, apkUrl: apkUrl);
        }
      });
    } catch (e) {
      _logger.e('UpdateHandlerService: Method 2 setup failed: $e');
      _tryShowDialog3(message: message, updateUrl: updateUrl, apkUrl: apkUrl);
    }
  }

  /// Method 3: Emergency fallback - queue for later
  static void _tryShowDialog3({
    String? message,
    String? updateUrl,
    String? apkUrl,
  }) {
    _logger.i(
        'UpdateHandlerService: Attempting Method 3: Queue for later execution');

    try {
      // Store the update info and try again after a delay
      _currentUpdateUrl = updateUrl;
      _currentApkUrl = apkUrl;

      Future.delayed(const Duration(milliseconds: 500), () {
        _logger.i('UpdateHandlerService: Retrying dialog after delay');
        if (!_isDialogShowing) {
          _tryShowDialog1(
              message: message, updateUrl: updateUrl, apkUrl: apkUrl);
        }
      });

      _logger.i('UpdateHandlerService: Method 3 queued for retry');
    } catch (e) {
      _logger.e('UpdateHandlerService: All methods failed: $e');
      _isDialogShowing = false;
      _currentUpdateUrl = null;
      _currentApkUrl = null;
    }
  }

  static bool get isDialogShowing => _isDialogShowing;

  static void reset() {
    _isDialogShowing = false;
    _currentUpdateUrl = null;
    _currentApkUrl = null;
    _logger.d('UpdateHandlerService: Reset dialog state');
  }

  static String? get currentUpdateUrl => _currentUpdateUrl;
  static String? get currentApkUrl => _currentApkUrl;
}

/// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Helper function to get current context from navigator key
BuildContext? getCurrentContext() {
  return navigatorKey.currentContext;
}
