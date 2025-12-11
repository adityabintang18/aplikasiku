import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../data/services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  final RxBool isLoggedIn = false.obs;
  final RxBool isBiometricEnabled = false.obs;

  /// 🔐 Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    _logger.i('AuthController: Attempting login for email: $email');
    final response = await _authService.login(email, password);
    if (response['success'] == true) {
      isLoggedIn.value = true;
      _logger.i('AuthController: Login successful');
      // After successful login, refresh_token is automatically stored
      // Biometric can be enabled later by user choice
    } else {
      _logger.w(
        'AuthController: Login failed - ${response['message'] ?? 'Unknown error'}',
      );
    }
    return response;
  }

  /// 🚪 Logout user
  Future<void> logout() async {
    _logger.i('AuthController: Logging out user');
    await _authService.logout();
    isLoggedIn.value = false;
    _logger.i('AuthController: Logout completed');
  }

  /// 🔎 Cek status login awal
  Future<void> checkLoginStatus() async {
    _logger.d('AuthController: Checking login status');
    isLoggedIn.value = await _authService.isTokenValid();
    _logger.d('AuthController: Login status check result: ${isLoggedIn.value}');
  }

  /// 📝 Register user
  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String password_confirmation,
  ) async {
    _logger.i('AuthController: Attempting registration for email: $email');
    return await _authService.register(
      name,
      email,
      password,
      password_confirmation,
    );
  }

  /// 💾 Enable biometric login (simpan refresh_token khusus untuk biometric)
  Future<void> enableBiometricLogin() async {
    _logger.i('AuthController: Enabling biometric login');
    // Get current refresh token from auth service
    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken != null) {
      // Save refresh token to secure storage for biometric login
      await _storage.write(key: 'biometric_refresh_token', value: refreshToken);
      _logger.i('AuthController: Refresh token saved for biometric login');
    } else {
      _logger.w(
        'AuthController: No refresh token found when enabling biometric login',
      );
    }

    // Save biometric enabled flag
    await _storage.write(key: 'biometric_enabled', value: 'true');
    isBiometricEnabled.value = true;
    _logger.i('AuthController: Biometric login enabled successfully');
  }

  /// 🗑️ Disable biometric login
  Future<void> disableBiometricLogin() async {
    _logger.i('AuthController: Disabling biometric login');
    await _storage.delete(key: 'biometric_enabled');
    await _storage.delete(
      key: 'biometric_refresh_token',
    ); // Clear biometric refresh token
    isBiometricEnabled.value = false;
    _logger.i('AuthController: Biometric login disabled');
  }

  /// 🔍 Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    _logger.d('AuthController: Checking if biometric login is enabled');
    final enabled = await _storage.read(key: 'biometric_enabled');
    final isEnabled = enabled == 'true';
    _logger.d('AuthController: Biometric enabled status: $isEnabled');
    // Sync reactive variable
    if (isBiometricEnabled.value != isEnabled) {
      isBiometricEnabled.value = isEnabled;
    }
    return isEnabled;
  }

  /// 🔐 Login with biometric (secure implementation)
  Future<bool> loginWithBiometric() async {
    _logger.i('AuthController: === BIOMETRIC LOGIN START ===');

    try {
      // Check if biometric is enabled
      _logger.d('AuthController: Step 1 - Checking if biometric is enabled');
      final enabled = await isBiometricLoginEnabled();
      if (!enabled) {
        _logger.w('AuthController: Biometric login not enabled by user');
        return false;
      }

      _logger.d(
        'AuthController: Step 2 - Checking device biometric capabilities',
      );
      final canAuthenticateWithBiometric = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometric || await _localAuth.isDeviceSupported();

      _logger.d(
        'AuthController: Device biometric check - canCheckBiometrics: $canAuthenticateWithBiometric, isDeviceSupported: ${await _localAuth.isDeviceSupported()}',
      );

      if (!canAuthenticate) {
        _logger.e(
          'AuthController: Device does not support biometric authentication',
        );
        return false;
      }

      // Check if there are any enrolled biometrics
      _logger.d('AuthController: Step 3 - Checking available biometrics');
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _logger.i('AuthController: Available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        _logger.e('AuthController: No biometrics enrolled on device');
        return false;
      }

      // Authenticate with biometric
      _logger.i('AuthController: Step 4 - Starting biometric authentication');
      _logger.i(
        'AuthController: Localized reason: Gunakan fingerprint untuk login',
      );

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan fingerprint untuk login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      _logger.i(
        'AuthController: Biometric authentication result: $authenticated',
      );

      if (authenticated) {
        _logger.i(
          'AuthController: Step 5 - Biometric auth successful, getting stored refresh token',
        );

        // Get stored refresh_token
        final refreshToken = await _storage.read(
          key: 'biometric_refresh_token',
        );
        if (refreshToken == null) {
          _logger.e(
            'AuthController: No refresh token found for biometric login',
          );
          _logger.e(
            'AuthController: This might be because user never logged in normally or token was cleared',
          );
          return false;
        }

        _logger.i(
          'AuthController: Step 6 - Found refresh token, attempting server login with token',
        );
        _logger.d(
          'AuthController: Refresh token length: ${refreshToken.length}',
        );

        // Login with token
        final response = await _authService.loginWithToken(refreshToken);
        _logger.i(
          'AuthController: Server login with token response: success=${response['success']}',
        );

        if (response['success'] == true) {
          isLoggedIn.value = true;
          _logger.i('AuthController: === BIOMETRIC LOGIN SUCCESS ===');
          return true;
        } else {
          _logger.e(
            'AuthController: Server login with token failed: ${response['message'] ?? 'Unknown error'}',
          );
          _logger.e(
            'AuthController: Possible issues: token expired, invalid token, or server error',
          );
          return false;
        }
      }

      _logger.w(
        'AuthController: Biometric authentication was cancelled or failed by user',
      );
      _logger.i(
        'AuthController: === BIOMETRIC LOGIN FAILED (User cancelled) ===',
      );
      return false;
    } catch (e, stackTrace) {
      _logger.e('AuthController: === BIOMETRIC LOGIN ERROR ===');
      _logger.e('AuthController: Exception type: ${e.runtimeType}');
      _logger.e('AuthController: Exception message: $e');
      _logger.e('AuthController: Stack trace: $stackTrace');

      // Log specific error types
      if (e.toString().contains('NotAvailable') ||
          e.toString().contains('not available')) {
        _logger.e('AuthController: Error - Biometric not available on device');
      } else if (e.toString().contains('LockedOut') ||
          e.toString().contains('locked')) {
        _logger.e(
          'AuthController: Error - Biometric locked out (too many failed attempts)',
        );
      } else if (e.toString().contains('NotEnrolled') ||
          e.toString().contains('enrolled')) {
        _logger.e('AuthController: Error - No biometric enrolled on device');
      }

      return false;
    }
  }

  /// 🔍 Check if biometric is available (simple check)
  Future<bool> isBiometricAvailable() async {
    _logger.d('AuthController: Checking biometric availability (simple)');
    try {
      final result =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      _logger.d('AuthController: Simple biometric check result: $result');
      return result;
    } catch (e) {
      _logger.e('AuthController: Error in simple biometric check: $e');
      return false;
    }
  }

  /// 🔍 Check if biometric login should be shown (device + setting)
  Future<bool> shouldShowBiometricLogin() async {
    _logger.d('AuthController: === CHECKING BIOMETRIC LOGIN VISIBILITY ===');

    try {
      // Check if biometric is enabled
      final enabled = await isBiometricLoginEnabled();
      _logger.d('AuthController: User enabled biometric: $enabled');
      if (!enabled) {
        _logger.d(
          'AuthController: Biometric not enabled by user - hiding button',
        );
        return false;
      }

      // Check if device supports biometric
      final deviceSupports = await isBiometricAvailable();
      _logger.d('AuthController: Device supports biometric: $deviceSupports');
      if (!deviceSupports) {
        _logger.d(
          'AuthController: Device does not support biometric - hiding button',
        );
        return false;
      }

      // Check if refresh_token is stored (optional - may not exist on first login)
      final refreshToken = await _authService.getRefreshToken();
      _logger.d(
        'AuthController: Refresh token exists: ${refreshToken != null}',
      );

      // Show biometric button if enabled and device supports it
      // Refresh token will be available after successful login
      _logger.i(
        'AuthController: All conditions met - showing biometric login button',
      );
      return true;
    } catch (e, stackTrace) {
      _logger.e('AuthController: Error checking biometric visibility: $e');
      _logger.e('AuthController: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 🔧 Toggle biometric setting with validation
  Future<bool> toggleBiometricSetting(bool enabled) async {
    _logger.i('AuthController: Toggling biometric setting to: $enabled');

    if (enabled) {
      // When enabling, validate biometric first
      _logger.d('AuthController: Validating biometric before enabling');
      final canAuthenticate = await isBiometricDeviceAvailable();
      if (!canAuthenticate) {
        _logger.w(
          'AuthController: Cannot enable biometric - device not available',
        );
        return false;
      }

      // Check if biometrics are available
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _logger.w(
          'AuthController: Cannot enable biometric - no biometrics enrolled',
        );
        return false;
      }

      try {
        // Validate biometric authentication
        _logger.d(
          'AuthController: Requesting biometric validation for enabling setting',
        );
        final authenticated = await _localAuth.authenticate(
          localizedReason:
              'Validasi fingerprint untuk mengaktifkan login biometrik',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );

        if (authenticated) {
          await enableBiometricLogin();
          _logger.i('AuthController: Biometric login enabled successfully');
          return true;
        } else {
          _logger.w('AuthController: Biometric validation cancelled by user');
          return false;
        }
      } catch (e) {
        _logger.e('AuthController: Error during biometric validation: $e');
        return false;
      }
    } else {
      // When disabling, disable biometric login
      _logger.d('AuthController: Disabling biometric login');
      await disableBiometricLogin();
      return true;
    }
  }

  /// 🔧 Check if biometric needs password on next login
  Future<bool> isBiometricPasswordNeeded() async {
    final needed = await _storage.read(key: 'biometric_needs_password');
    return needed == 'true';
  }

  /// 🔧 Clear biometric password needed flag
  Future<void> clearBiometricPasswordNeeded() async {
    await _storage.delete(key: 'biometric_needs_password');
  }

  ///  Check if biometric authentication is available on device (detailed)
  Future<bool> isBiometricDeviceAvailable() async {
    _logger.d('AuthController: === DETAILED BIOMETRIC AVAILABILITY CHECK ===');

    try {
      // Check if device supports biometric
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      _logger.d('AuthController: canCheckBiometrics: $canCheckBiometrics');
      _logger.d('AuthController: isDeviceSupported: $isDeviceSupported');

      if (!canCheckBiometrics && !isDeviceSupported) {
        _logger.e(
          'AuthController: Device does not support biometric authentication',
        );
        return false;
      }

      // Check if there are available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _logger.i('AuthController: Available biometrics: $availableBiometrics');
      _logger.i(
        'AuthController: Number of available biometrics: ${availableBiometrics.length}',
      );

      return availableBiometrics.isNotEmpty;
    } catch (e, stackTrace) {
      _logger.e('AuthController: Error checking biometric availability: $e');
      _logger.e('AuthController: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 🔑 Forgot password - request reset token
  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    _logger.i('AuthController: Requesting password reset for email: $email');
    return await _authService.forgotPassword(email);
  }

  /// 🔓 Reset password using token
  Future<Map<String, dynamic>?> resetPassword(
    String email,
    String token,
    String password,
    String passwordConfirmation,
  ) async {
    _logger.i('AuthController: Attempting password reset for email: $email');
    return await _authService.resetPassword(
      email,
      token,
      password,
      passwordConfirmation,
    );
  }
}
