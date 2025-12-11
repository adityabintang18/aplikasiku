// Refactored AuthController using Clean Architecture with Use Cases Pattern
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../core/entities/user_entity.dart';
import '../core/entities/login_params.dart';
import '../core/entities/register_params.dart';
import '../core/entities/reset_password_params.dart';
import '../core/interfaces/auth_repository.dart';
import '../core/interfaces/auth_local_data_source.dart';

/// Reactive state for authentication
class AuthState {
  final bool isLoggedIn;
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Refactored AuthController using Clean Architecture
class AuthController extends GetxController {
  late final LoginUseCase _loginUseCase;
  late final RegisterUseCase _registerUseCase;
  late final LogoutUseCase _logoutUseCase;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;
  late final LocalAuthentication _localAuth;
  late final Logger _logger;

  // Reactive state
  final Rx<AuthState> _authState = const AuthState().obs;
  final RxBool isBiometricEnabled = false.obs;

  // Getters for reactive state
  AuthState get authState => _authState.value;
  bool get isLoggedIn => _authState.value.isLoggedIn;
  UserEntity? get currentUser => _authState.value.user;
  bool get isLoading => _authState.value.isLoading;
  String? get errorMessage => _authState.value.errorMessage;

  @override
  void onInit() {
    super.onInit();
    _initializeDependencies();
    _checkBiometricStatus();
  }

  /// Initialize dependencies through dependency injection
  void _initializeDependencies() {
    _loginUseCase = Get.find<LoginUseCase>();
    _registerUseCase = Get.find<RegisterUseCase>();
    _logoutUseCase = Get.find<LogoutUseCase>();
    _getCurrentUserUseCase = Get.find<GetCurrentUserUseCase>();
    _localAuth = LocalAuthentication();
    _logger = Get.find<Logger>();

    _logger.i('AuthController initialized with clean architecture');
  }

  /// 🔐 Login user using use case
  Future<bool> login(String email, String password) async {
    _logger.i('AuthController: Starting login process');

    // Update state to loading
    _updateState(isLoading: true, errorMessage: null);

    try {
      final result = await _loginUseCase.execute(
        LoginParams(email: email, password: password),
      );

      // Handle result directly (not using fold since LoginResult is simple)
      if (result.isSuccess && result.user != null) {
        _logger.i('AuthController: Login successful for ${result.user!.name}');
        _updateState(
          isLoading: false,
          isLoggedIn: true,
          user: result.user,
          errorMessage: null,
        );
        return true;
      } else {
        _logger.w('AuthController: Login failed - ${result.message}');
        _updateState(
          isLoading: false,
          errorMessage: result.message,
          isLoggedIn: false,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'AuthController: Unexpected error during login',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        isLoggedIn: false,
      );
      return false;
    }
  }

  /// 🚪 Logout user using use case
  Future<void> logout() async {
    _logger.i('AuthController: Starting logout process');

    // Update state to loading
    _updateState(isLoading: true);

    try {
      await _logoutUseCase.execute(null);
      _logger.i('AuthController: Logout successful');

      // Clear state
      _updateState(
        isLoading: false,
        isLoggedIn: false,
        user: null,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      _logger.e(
        'AuthController: Error during logout',
        error: e,
        stackTrace: stackTrace,
      );

      // Even if logout fails, clear local state
      _updateState(
        isLoading: false,
        isLoggedIn: false,
        user: null,
        errorMessage: null,
      );
    }
  }

  /// 📝 Register user using use case
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _logger.i('AuthController: Starting registration process');

    // Update state to loading
    _updateState(isLoading: true, errorMessage: null);

    try {
      // Create register params
      final params = RegisterParams(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final result = await _registerUseCase.execute(params);

      // Handle result directly (not using fold since RegisterResult is simple)
      if (result.isSuccess && result.user != null) {
        _logger.i(
          'AuthController: Registration successful for ${result.user!.name}',
        );
        _updateState(
          isLoading: false,
          isLoggedIn: true,
          user: result.user,
          errorMessage: null,
        );
        return true;
      } else {
        _logger.w('AuthController: Registration failed - ${result.message}');
        _updateState(
          isLoading: false,
          errorMessage: result.message,
          isLoggedIn: false,
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e(
        'AuthController: Unexpected error during registration',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        isLoggedIn: false,
      );
      return false;
    }
  }

  /// 🔎 Check login status using use case
  Future<void> checkLoginStatus() async {
    _logger.i('AuthController: Checking login status');

    try {
      final result = await _getCurrentUserUseCase.execute(null);

      if (result.isAuthenticated && result.user != null) {
        _logger.i('AuthController: User is logged in - ${result.user!.name}');
        _updateState(isLoggedIn: true, user: result.user, errorMessage: null);
      } else {
        _logger.i('AuthController: User is not logged in');
        _updateState(isLoggedIn: false, user: null, errorMessage: null);
      }
    } catch (e, stackTrace) {
      _logger.e(
        'AuthController: Error checking login status',
        error: e,
        stackTrace: stackTrace,
      );
      _updateState(isLoggedIn: false, user: null, errorMessage: null);
    }
  }

  /// 🔐 Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    _logger.i('AuthController: Starting biometric login');

    try {
      // Check if biometric is enabled
      final enabled = await isBiometricLoginEnabled();
      if (!enabled) {
        _logger.w('AuthController: Biometric login not enabled');
        return false;
      }

      // Check device biometric support
      final canAuthenticate =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _logger.w(
          'AuthController: Device does not support biometric authentication',
        );
        return false;
      }

      // Check if there are any enrolled biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _logger.w('AuthController: No biometrics enrolled');
        return false;
      }

      // Authenticate with biometric
      _logger.i('AuthController: Attempting biometric authentication...');
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan fingerprint untuk login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        _logger.i('AuthController: Biometric authentication successful');

        // For biometric login, we need to use the repository directly
        // since we don't have a specific biometric use case yet
        final authRepository = Get.find<AuthRepository>();
        final result = await authRepository.loginWithBiometric();

        if (result.success && result.user != null) {
          _logger.i('AuthController: Biometric login successful');
          _updateState(isLoggedIn: true, user: result.user, errorMessage: null);
          return true;
        } else {
          _logger.w(
            'AuthController: Biometric login failed - ${result.message}',
          );
          _updateState(errorMessage: result.message);
          return false;
        }
      }

      _logger.w('AuthController: Biometric authentication failed');
      return false;
    } catch (e, stackTrace) {
      _logger.e(
        'AuthController: Biometric authentication error',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// 💾 Enable biometric login
  Future<bool> enableBiometricLogin() async {
    try {
      // Validate biometric first
      final canAuthenticate = await isBiometricDeviceAvailable();
      if (!canAuthenticate) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return false;
      }

      // Validate biometric authentication
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
        // Save biometric preference
        final localDataSource = Get.find<AuthLocalDataSource>();
        await localDataSource.setBiometricEnabled(true);
        isBiometricEnabled.value = true;
        _logger.i('AuthController: Biometric login enabled');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('AuthController: Error enabling biometric login', error: e);
      return false;
    }
  }

  /// 🗑️ Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      final localDataSource = Get.find<AuthLocalDataSource>();
      await localDataSource.setBiometricEnabled(false);
      isBiometricEnabled.value = false;
      _logger.i('AuthController: Biometric login disabled');
    } catch (e) {
      _logger.e('AuthController: Error disabling biometric login', error: e);
    }
  }

  /// 🔍 Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final localDataSource = Get.find<AuthLocalDataSource>();
      final enabled = await localDataSource.isBiometricEnabled();

      // Sync reactive variable
      if (isBiometricEnabled.value != enabled) {
        isBiometricEnabled.value = enabled;
      }

      return enabled;
    } catch (e) {
      _logger.e(
        'AuthController: Error checking biometric enabled status',
        error: e,
      );
      return false;
    }
  }

  /// 🔍 Check if biometric authentication is available on device
  Future<bool> isBiometricDeviceAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      _logger.d(
        'AuthController: Biometric support check - canCheck: $canCheckBiometrics, supported: $isDeviceSupported',
      );

      if (!canCheckBiometrics && !isDeviceSupported) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      _logger.d('AuthController: Available biometrics: $availableBiometrics');

      return availableBiometrics.isNotEmpty;
    } catch (e) {
      _logger.e(
        'AuthController: Error checking biometric availability',
        error: e,
      );
      return false;
    }
  }

  /// 🔍 Check if biometric login should be shown
  Future<bool> shouldShowBiometricLogin() async {
    try {
      final enabled = await isBiometricLoginEnabled();
      if (!enabled) return false;

      final deviceSupports = await isBiometricDeviceAvailable();
      if (!deviceSupports) return false;

      // Show biometric button if enabled and device supports it
      return true;
    } catch (e) {
      _logger.e(
        'AuthController: Error checking biometric show status',
        error: e,
      );
      return false;
    }
  }

  /// 🔧 Toggle biometric setting
  Future<bool> toggleBiometricSetting(bool enabled) async {
    if (enabled) {
      return await enableBiometricLogin();
    } else {
      await disableBiometricLogin();
      return true;
    }
  }

  /// 🔑 Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final result = await authRepository.forgotPassword(email);
      return result.success;
    } catch (e) {
      _logger.e('AuthController: Error requesting password reset', error: e);
      return false;
    }
  }

  /// 🔓 Reset password
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final result = await authRepository.resetPassword(
        ResetPasswordParams(
          email: email,
          token: token,
          newPassword: password,
          newPasswordConfirmation: passwordConfirmation,
        ),
      );
      return result.success;
    } catch (e) {
      _logger.e('AuthController: Error resetting password', error: e);
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _updateState(errorMessage: null);
  }

  /// Private method to update state
  void _updateState({
    bool? isLoggedIn,
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    _authState.value = _authState.value.copyWith(
      isLoggedIn: isLoggedIn,
      user: user,
      isLoading: isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Check biometric status on init
  Future<void> _checkBiometricStatus() async {
    isBiometricEnabled.value = await isBiometricLoginEnabled();
  }
}
