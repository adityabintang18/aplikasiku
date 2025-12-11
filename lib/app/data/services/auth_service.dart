import 'dart:io';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart' as dio;
import 'base_api_service.dart';
import '../models/auth_result_model.dart';
import '../models/user_profile_model.dart';

/// Authentication service for handling user authentication operations
class AuthService extends BaseApiService {
  // =====================
  // AUTHENTICATION METHODS
  // =====================

  /// Login user with email and password
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 &&
          response.data['access_token'] != null &&
          response.data['refresh_token'] != null) {
        await _storeTokens(response.data);
        return AuthResult.success(
            response.data['message'] ?? 'Login berhasil.');
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Login gagal. Cek email & password.');
    } catch (e) {
      logger.e('Login error: $e');
      return AuthResult.failure('Terjadi kesalahan saat login.');
    }
  }

  /// Legacy login method for backward compatibility
  Future<Map<String, dynamic>> loginLegacy(
      String email, String password) async {
    final result = await login(email, password);
    return result.toLegacyMap();
  }

  /// Login using refresh token (for biometric authentication)
  Future<AuthResult> loginWithToken(String refreshToken) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/login-with-token',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        await _storeAccessToken(response.data['access_token']);
        return AuthResult.success(
            response.data['message'] ?? 'Login berhasil.');
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Token tidak valid.');
    } catch (e) {
      logger.e('Login with token error: $e');
      return AuthResult.failure('Terjadi kesalahan saat login.');
    }
  }

  /// Legacy login with token for backward compatibility
  Future<Map<String, dynamic>> loginWithTokenLegacy(String refreshToken) async {
    final result = await loginWithToken(refreshToken);
    return result.toLegacyMap();
  }

  /// Register new user
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Registrasi berhasil!');
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Registrasi gagal.');
    } catch (e) {
      logger.e('Register error: $e');
      return AuthResult.failure('Terjadi kesalahan saat registrasi.');
    }
  }

  /// Legacy register method for backward compatibility
  Future<Map<String, dynamic>?> registerLegacy(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final result = await register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return result.toLegacyMap();
  }

  /// Logout user and clear all tokens
  Future<void> logout() async {
    try {
      await client.post('$baseUrl/auth/logout');
    } catch (e) {
      logger.w('Logout API call failed, but clearing tokens anyway: $e');
    } finally {
      await _clearTokens();
    }
  }

  // =====================
  // PASSWORD MANAGEMENT
  // =====================

  /// Change user password
  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Password berhasil diubah.');
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Gagal mengubah password.');
    } catch (e) {
      logger.e('Change password error: $e');
      if (e is DioException && e.response != null) {
        return AuthResult.failure(
            e.response?.data['message'] ?? 'Gagal mengubah password.');
      }
      return AuthResult.failure('Terjadi kesalahan saat mengubah password.');
    }
  }

  /// Legacy change password method for backward compatibility
  Future<Map<String, dynamic>> changePasswordLegacy(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final result = await changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return result.toLegacyMap();
  }

  /// Request password reset token
  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Token reset telah dikirim.',
            resetToken: response.data['reset_token']);
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Gagal mengirim email reset.');
    } catch (e) {
      logger.e('Forgot password error: $e');
      if (e is DioException && e.response != null) {
        return AuthResult.failure(
            e.response?.data['message'] ?? 'Gagal mengirim email reset.');
      }
      return AuthResult.failure(
          'Terjadi kesalahan saat meminta reset password.');
    }
  }

  /// Legacy forgot password method for backward compatibility
  Future<Map<String, dynamic>> forgotPasswordLegacy(String email) async {
    final result = await forgotPassword(email);
    return result.toLegacyMap();
  }

  /// Reset password using token
  Future<AuthResult> resetPassword({
    required String email,
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Password berhasil direset.');
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Gagal mereset password.');
    } catch (e) {
      logger.e('Reset password error: $e');
      if (e is DioException && e.response != null) {
        return AuthResult.failure(
            e.response?.data['message'] ?? 'Gagal mereset password.');
      }
      return AuthResult.failure('Terjadi kesalahan saat mereset password.');
    }
  }

  /// Legacy reset password method for backward compatibility
  Future<Map<String, dynamic>> resetPasswordLegacy(
    String email,
    String token,
    String password,
    String confirmPassword,
  ) async {
    final result = await resetPassword(
      email: email,
      token: token,
      password: password,
      confirmPassword: confirmPassword,
    );
    return result.toLegacyMap();
  }

  // =====================
  // PROFILE MANAGEMENT
  // =====================

  /// Get current user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await client.get('$baseUrl/profile');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // Handle 404 gracefully for development/demo
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
            'User endpoint not found (404). This is normal for development/demo.');
        return UserProfile.demoUser();
      }
      logger.e('Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? name,
    String? email,
    String? phone,
    File? photo,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;

      if (photo != null) {
        data['photo'] = await dio.MultipartFile.fromFile(
          photo.path,
          filename: 'photo.jpg',
        );
      }

      final response = await client.post(
        '$baseUrl/profile/update',
        data: photo != null ? dio.FormData.fromMap(data) : data,
      );

      if (response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Profile berhasil diperbarui.',
            userData: response.data['user']);
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Gagal memperbarui profile.');
    } catch (e) {
      logger.e('Update profile error: $e');
      if (e is DioException && e.response != null) {
        return AuthResult.failure(
            e.response?.data['message'] ?? 'Gagal memperbarui profile.');
      }
      return AuthResult.failure('Terjadi kesalahan saat memperbarui profile.');
    }
  }

  /// Legacy update profile method for backward compatibility
  Future<Map<String, dynamic>> updateProfileLegacy({
    String? name,
    String? email,
    String? phone,
    File? photo,
  }) async {
    final result = await updateProfile(
      name: name,
      email: email,
      phone: phone,
      photo: photo,
    );
    return result.toLegacyMap();
  }

  // =====================
  // REFERENCE DATA METHODS
  // =====================

  /// Get transaction types
  Future<List<Map<String, dynamic>>?> getTransactionTypes() async {
    try {
      final response = await client.get('$baseUrl/ref/jenis');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      // Handle 404 gracefully for development/demo
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
            'Transaction types endpoint not found (404). This is normal for development/demo.');
        return [
          {'id': '1', 'name': 'Income', 'type': 'income'},
          {'id': '2', 'name': 'Expense', 'type': 'expense'},
          {'id': '3', 'name': 'Transfer', 'type': 'transfer'},
        ];
      }
      logger.e('Get transaction types error: $e');
      return null;
    }
  }

  /// Add new transaction type
  Future<AuthResult> addTransactionTypes(
    String name, {
    String? deskripsi,
  }) async {
    try {
      final data = <String, dynamic>{'nama': name};
      if (deskripsi != null && deskripsi.isNotEmpty) {
        data['deskripsi'] = deskripsi;
      }

      final response = await client.post('$baseUrl/ref/jenis', data: data);

      if (response.statusCode == 201) {
        return AuthResult.success('Category added successfully',
            userData: response.data);
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Failed to add category');
    } catch (e) {
      logger.e('Add category error: $e');
      return AuthResult.failure('Error adding category');
    }
  }

  /// Legacy add transaction types method for backward compatibility
  Future<Map<String, dynamic>> addTransactionTypesLegacy(
    String nama, {
    String? deskripsi,
  }) async {
    final result = await addTransactionTypes(nama, deskripsi: deskripsi);
    return result.toLegacyMap();
  }

  /// Get categories
  Future<List<Map<String, dynamic>>?> getCategories() async {
    try {
      final response = await client.get('$baseUrl/ref/kategori');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      // Handle 404 gracefully for development/demo
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
            'Categories endpoint not found (404). This is normal for development/demo.');
        return [
          {'id': 14, 'nama': 'Gaji', 'deskripsi': 'Pemasukan'},
          {'id': 15, 'nama': 'Bonus', 'deskripsi': 'Pemasukan'},
          {'id': 16, 'nama': 'Investasi', 'deskripsi': 'Pemasukan'},
          {'id': 17, 'nama': 'Lain-lain', 'deskripsi': 'Pemasukan'},
          {'id': 18, 'nama': 'Makanan & Minuman', 'deskripsi': 'Pengeluaran'},
          {'id': 19, 'nama': 'Transportasi', 'deskripsi': 'Pengeluaran'},
          {'id': 20, 'nama': 'Tagihan & Utilitas', 'deskripsi': 'Pengeluaran'},
        ];
      }
      logger.e('Get categories error: $e');
      return null;
    }
  }

  /// Add new category (for transaction categories)
  Future<AuthResult> addCategory({
    required String nama,
    String? deskripsi,
  }) async {
    try {
      final data = <String, dynamic>{'nama': nama};
      if (deskripsi != null && deskripsi.isNotEmpty) {
        data['deskripsi'] = deskripsi;
      }

      final response = await client.post('$baseUrl/ref/kategori', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult.success(
            response.data['message'] ?? 'Category added successfully',
            userData: response.data);
      }

      return AuthResult.failure(
          response.data['message'] ?? 'Failed to add category');
    } catch (e) {
      logger.e('Add category error: $e');
      return AuthResult.failure('Error adding category');
    }
  }

  /// Legacy add category method for backward compatibility
  Future<Map<String, dynamic>> addCategoryLegacy({
    required String nama,
    String? deskripsi,
  }) async {
    final result = await addCategory(nama: nama, deskripsi: deskripsi);
    return result.toLegacyMap();
  }

  // =====================
  // TOKEN MANAGEMENT
  // =====================

  /// Get access token from storage
  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  /// Get refresh token from storage
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  /// Check if access token is valid
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  // =====================
  // BACKWARD COMPATIBILITY METHODS
  // =====================

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>> getUserInfo() async {
    final profile = await getUserProfile();
    if (profile != null) {
      return {
        'success': true,
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'photo_url': profile.photoUrl,
      };
    }
    return {'success': false, 'message': 'Failed to get user info'};
  }

  // =====================
  // PRIVATE HELPER METHODS
  // =====================

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'access_token', value: data['access_token']);
    await storage.write(
        key: 'token', value: data['access_token']); // For compatibility
    await storage.write(key: 'refresh_token', value: data['refresh_token']);
  }

  Future<void> _storeAccessToken(String token) async {
    await storage.write(key: 'access_token', value: token);
    await storage.write(key: 'token', value: token); // For compatibility
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'token');
    await storage.delete(key: 'refresh_token');
  }
}
