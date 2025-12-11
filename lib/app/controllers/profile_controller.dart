import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:aplikasiku/app/data/services/auth_service.dart';
import 'package:aplikasiku/app/controllers/auth_controller.dart';
import 'package:logger/logger.dart';
import 'package:aplikasiku/app/mixins/update_handler_mixin.dart';
import 'package:aplikasiku/app/utils/exceptions.dart';

class ProfileController extends GetxController with UpdateHandlerMixin {
  final AuthService _authService = AuthService();
  final _logger = Logger();

  AuthController get _authController => Get.find<AuthController>();

  var userInfo = {}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchUserProfile();
    super.onInit();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading(true);
      final result = await _authService.getUserInfo();
      if (result != null) {
        userInfo.value = result;
        _logger.i('User profile loaded: $result');
      }
    } catch (e) {
      if (e is AppUpdateRequiredException) {
        handleUpdateException();
      } else {
        _logger.e('Error fetchUserProfile', error: e);
      }
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> updatedData, {
    File? photo,
  }) async {
    try {
      isLoading(true);
      final result = await _authService.updateProfile(
        name: updatedData['name'],
        email: updatedData['email'],
        photo: photo,
      );
      if (result != null && result['success'] == true) {
        // Refresh user info after successful update
        await fetchUserProfile();
        isLoading(false);
        return {'success': true, 'message': 'Profile updated successfully'};
      } else {
        isLoading(false);
        return result ??
            {'success': false, 'message': 'Failed to update profile'};
      }
    } catch (e) {
      isLoading(false);
      _logger.e('Error updateProfile', error: e);
      return {
        'success': false,
        'message': 'An error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<void> logout() async {
    await _authController.logout();
  }

  Future<void> refreshProfile() async {
    await fetchUserProfile();
  }

  /// Called when page is entered - refresh data automatically
  Future<void> onPageEnter() async {
    _logger.i('ProfileController: onPageEnter called - refreshing data');
    await refreshProfile();
  }

  Future<Map<String, dynamic>?> changePassword(
    String oldPassword,
    String newPassword,
    String confirmation,
  ) async {
    try {
      isLoading(true);
      final result = await _authService.changePassword(
        oldPassword,
        newPassword,
        confirmation,
      );

      // If password change successful, disable biometric for security
      if (result != null && result['success'] == true) {
        await _authController.disableBiometricLogin();
      }

      return result;
    } catch (e) {
      _logger.e('Error changePassword', error: e);
      return {'success': false, 'message': 'An error occurred'};
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      isLoading(true);
      final result = await _authService.forgotPassword(email);
      return result;
    } catch (e) {
      _logger.e('Error forgotPassword', error: e);
      return {'success': false, 'message': 'An error occurred'};
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>?> resetPassword(
    String email,
    String token,
    String password,
    String confirmation,
  ) async {
    try {
      isLoading(true);
      final result = await _authService.resetPassword(
        email,
        token,
        password,
        confirmation,
      );
      return result;
    } catch (e) {
      _logger.e('Error resetPassword', error: e);
      return {'success': false, 'message': 'An error occurred'};
    } finally {
      isLoading(false);
    }
  }
}
