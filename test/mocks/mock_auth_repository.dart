// Simple mock for AuthRepository interface (no external dependencies)
import '../../lib/app/core/interfaces/auth_repository.dart';
import '../../lib/app/core/entities/auth_result.dart';
import '../../lib/app/core/entities/login_params.dart';
import '../../lib/app/core/entities/register_params.dart';
import '../../lib/app/core/entities/user_entity.dart';
import '../../lib/app/core/entities/tokens_entity.dart';
import '../../lib/app/core/entities/update_profile_params.dart';
import '../../lib/app/core/entities/change_password_params.dart';
import '../../lib/app/core/entities/reset_password_params.dart';

/// Simple mock implementation of AuthRepository for testing
class MockAuthRepository implements AuthRepository {
  // Store call history for verification
  final List<String> callHistory = [];

  // Configurable responses
  AuthResult? loginResponse;
  AuthResult? registerResponse;
  AuthResult? biometricLoginResponse;
  AuthResult? updateProfileResponse;
  AuthResult? changePasswordResponse;
  AuthResult? forgotPasswordResponse;
  AuthResult? resetPasswordResponse;
  AuthResult? refreshTokenResponse;
  UserEntity? getCurrentUserResponse;
  bool? isLoggedInResponse;
  bool? isSessionValidResponse;
  TokensEntity? getCurrentTokensResponse;
  Exception? throwException;

  @override
  Future<AuthResult> login(LoginParams params) async {
    callHistory.add('login(${params.email})');

    if (throwException != null) {
      throw throwException!;
    }

    return loginResponse ??
        AuthResult.failure(message: 'Mock login not configured');
  }

  @override
  Future<AuthResult> loginWithBiometric() async {
    callHistory.add('loginWithBiometric()');

    if (throwException != null) {
      throw throwException!;
    }

    return biometricLoginResponse ??
        AuthResult.failure(message: 'Mock biometric login not configured');
  }

  @override
  Future<AuthResult> register(RegisterParams params) async {
    callHistory.add('register(${params.email})');

    if (throwException != null) {
      throw throwException!;
    }

    return registerResponse ??
        AuthResult.failure(message: 'Mock register not configured');
  }

  @override
  Future<void> logout() async {
    callHistory.add('logout()');

    if (throwException != null) {
      throw throwException!;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    callHistory.add('isLoggedIn()');

    if (throwException != null) {
      throw throwException!;
    }

    return isLoggedInResponse ?? false;
  }

  @override
  Future<AuthResult> refreshToken() async {
    callHistory.add('refreshToken()');

    if (throwException != null) {
      throw throwException!;
    }

    return refreshTokenResponse ??
        AuthResult.failure(message: 'Mock refresh token not configured');
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    callHistory.add('getCurrentUser()');

    if (throwException != null) {
      throw throwException!;
    }

    return getCurrentUserResponse;
  }

  @override
  Future<AuthResult> updateProfile(UpdateProfileParams params) async {
    callHistory.add('updateProfile()');

    if (throwException != null) {
      throw throwException!;
    }

    return updateProfileResponse ??
        AuthResult.failure(message: 'Mock update profile not configured');
  }

  @override
  Future<AuthResult> changePassword(ChangePasswordParams params) async {
    callHistory.add('changePassword()');

    if (throwException != null) {
      throw throwException!;
    }

    return changePasswordResponse ??
        AuthResult.failure(message: 'Mock change password not configured');
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    callHistory.add('forgotPassword($email)');

    if (throwException != null) {
      throw throwException!;
    }

    return forgotPasswordResponse ??
        AuthResult.failure(message: 'Mock forgot password not configured');
  }

  @override
  Future<AuthResult> resetPassword(ResetPasswordParams params) async {
    callHistory.add('resetPassword(${params.email})');

    if (throwException != null) {
      throw throwException!;
    }

    return resetPasswordResponse ??
        AuthResult.failure(message: 'Mock reset password not configured');
  }

  @override
  Future<void> saveSession(AuthResult authResult) async {
    callHistory.add('saveSession()');

    if (throwException != null) {
      throw throwException!;
    }
  }

  @override
  Future<void> clearSession() async {
    callHistory.add('clearSession()');

    if (throwException != null) {
      throw throwException!;
    }
  }

  @override
  Future<bool> isSessionValid() async {
    callHistory.add('isSessionValid()');

    if (throwException != null) {
      throw throwException!;
    }

    return isSessionValidResponse ?? false;
  }

  @override
  Future<TokensEntity?> getCurrentTokens() async {
    callHistory.add('getCurrentTokens()');

    if (throwException != null) {
      throw throwException!;
    }

    return getCurrentTokensResponse;
  }

  /// Helper methods for test setup
  void setupSuccessfulLogin({UserEntity? user}) {
    loginResponse = AuthResult.success(
      message: 'Login successful',
      user: user ?? _createMockUser(),
    );
  }

  void setupFailedLogin({String message = 'Login failed'}) {
    loginResponse = AuthResult.failure(message: message);
  }

  void setupSuccessfulRegister({UserEntity? user}) {
    registerResponse = AuthResult.success(
      message: 'Registration successful',
      user: user ?? _createMockUser(),
    );
  }

  void setupFailedRegister({String message = 'Registration failed'}) {
    registerResponse = AuthResult.failure(message: message);
  }

  void setupLoggedInUser({UserEntity? user}) {
    isLoggedInResponse = true;
    getCurrentUserResponse = user ?? _createMockUser();
  }

  void setupLoggedOutUser() {
    isLoggedInResponse = false;
    getCurrentUserResponse = null;
  }

  void setupThrowException(Exception exception) {
    throwException = exception;
  }

  void clearCallHistory() {
    callHistory.clear();
  }

  bool wasCalled(String methodName) {
    return callHistory.any((call) => call.startsWith(methodName));
  }

  int getCallCount(String methodName) {
    return callHistory.where((call) => call.startsWith(methodName)).length;
  }

  UserEntity _createMockUser() {
    return UserEntity.withRequiredFields(
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
    );
  }
}
