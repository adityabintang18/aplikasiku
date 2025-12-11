import 'dart:io';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart' as dio;
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 &&
          response.data['access_token'] != null &&
          response.data['refresh_token'] != null) {
        await storage.write(
          key: 'access_token',
          value: response.data['access_token'],
        );
        await storage.write(key: 'token', value: response.data['access_token']);
        await storage.write(
          key: 'refresh_token',
          value: response.data['refresh_token'],
        );
        return {
          'success': true,
          'message': response.data['message'] ?? 'Login berhasil.',
        };
      }
      return {
        'success': false,
        'message':
            response.data['message'] ?? 'Login gagal. Cek email & password.',
      };
    } catch (e) {
      logger.e('Login error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan saat login.'};
    }
  }

  /// 📦 Ambil access_token dari storage
  Future<String?> getToken() async {
    return await storage.read(key: 'access_token');
  }

  /// 📦 Ambil refresh_token dari storage
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  /// 🚪 Logout dan hapus semua token
  Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'token');
    await storage.delete(key: 'refresh_token');
  }

  /// 🔎 Cek apakah token valid
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  /// 🔐 Login dengan refresh_token (untuk biometric)
  Future<Map<String, dynamic>> loginWithToken(String refreshToken) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/login-with-token',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        await storage.write(
          key: 'access_token',
          value: response.data['access_token'],
        );
        await storage.write(
          key: 'token', // For compatibility
          value: response.data['access_token'],
        );
        return {
          'success': true,
          'message': response.data['message'] ?? 'Login berhasil.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Token tidak valid.',
      };
    } catch (e) {
      logger.e('Login with token error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan saat login.'};
    }
  }

  /// 📝 Register user baru
  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Registrasi berhasil!',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Registrasi gagal.',
      };
    } catch (e) {
      logger.e('Register error: $e');
      return null;
    }
  }

  /// 👤 Get user info
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await client.get('$baseUrl/profile');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      // Check if it's a 404 error, handle gracefully for development/demo
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
          'User endpoint not found (404). This is normal for development/demo.',
        );
        return {'name': 'Demo User', 'email': 'demo@example.com'};
      }
      logger.e('Get user info error: $e');
      return null;
    }
  }

  /// 📊 Get transaction types
  Future<List<Map<String, dynamic>>?> getTransactionTypes() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await client.get('$baseUrl/ref/jenis');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
          'Transaction types endpoint not found (404). This is normal for development/demo.',
        );
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

  Future<Map<String, dynamic>> addTransactionTypes(
    String name, {
    String? deskripsi,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final data = {'nama': name};
      if (deskripsi != null && deskripsi.isNotEmpty) {
        data['deskripsi'] = deskripsi;
      }

      final response = await client.post('$baseUrl/ref/jenis', data: data);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Category added successfully',
          'data': response.data,
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to add category',
      };
    } catch (e) {
      logger.e('Add category error: $e');
      return {'success': false, 'message': 'Error adding category'};
    }
  }

  /// 📂 Get categories
  Future<List<Map<String, dynamic>>?> getCategories() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await client.get('$baseUrl/ref/kategori');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        logger.w(
          'Categories endpoint not found (404). This is normal for development/demo.',
        );
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

  /// 🔒 Change password
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
    String newPasswordConfirmation,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await client.post(
        '$baseUrl/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Password changed successfully.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to change password.',
      };
    } catch (e) {
      logger.e('Change password error: $e');
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? 'Failed to change password.',
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while changing password.',
      };
    }
  }

  /// ✏️ Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    File? photo,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

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
        return {
          'success': true,
          'message':
              response.data['message'] ?? 'Profile updated successfully.',
          'user': response.data['user'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to update profile.',
        'errors': response.data['errors'],
        'details': response.data['details'],
      };
    } catch (e) {
      logger.e('Update profile error: $e');
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Failed to update profile.',
          'errors': e.response?.data['errors'],
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while updating profile.',
      };
    }
  }

  /// 🔑 Forgot password - request reset token
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Reset token generated.',
          'reset_token': response.data['reset_token'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to send reset email.',
      };
    } catch (e) {
      logger.e('Forgot password error: $e');
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message':
              e.response?.data['message'] ?? 'Failed to send reset email.',
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while requesting password reset.',
      };
    }
  }

  /// 🔓 Reset password using token
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await client.post(
        '$baseUrl/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successful.',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to reset password.',
      };
    } catch (e) {
      logger.e('Reset password error: $e');
      if (e is DioException && e.response != null) {
        return {
          'success': false,
          'message': e.response?.data['message'] ?? 'Failed to reset password.',
        };
      }
      return {
        'success': false,
        'message': 'An error occurred while resetting password.',
      };
    }
  }
}
