// Concrete implementation of remote data source for authentication
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/interfaces/auth_remote_data_source.dart';
import '../../core/entities/login_params.dart';
import '../../core/entities/register_params.dart';
import '../../core/entities/update_profile_params.dart';
import '../../core/entities/change_password_params.dart';
import '../../core/entities/reset_password_params.dart';
import '../../core/exceptions/app_exception.dart';
import '../services/base_api_service.dart';

/// Concrete implementation of remote data source for authentication API
class AuthRemoteDataSourceImpl extends BaseApiService
    implements AuthRemoteDataSource {
  final Logger _logger;

  AuthRemoteDataSourceImpl({Logger? logger})
      : _logger = logger ?? Logger(),
        super();

  @override
  Future<Map<String, String>> get defaultHeaders async {
    try {
      final version = await appVersion;
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Aplikasiku/$version',
      };
    } catch (e) {
      _logger.w('Could not get app version for User-Agent header: $e');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Aplikasiku/1.0.0',
      };
    }
  }

  /// Helper method to handle API responses
  Future<Map<String, dynamic>> _handleResponse(Response response) async {
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _createExceptionFromResponse(response);
      }
    } catch (e) {
      _logger.e('Error handling response: $e');
      rethrow;
    }
  }

  /// Create appropriate exception from HTTP response
  AppException _createExceptionFromResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final data = response.data as Map<String, dynamic>?;
    final message = data?['message'] ?? 'Unknown error occurred';

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return AuthException('Authentication failed: $message');
      case 403:
        return AuthException('Access denied: $message');
      case 404:
        return ServerException(
          'Resource not found: $message',
          null,
          statusCode,
        );
      case 422:
        return ValidationException(message);
      case 429:
        return ServerException('Too many requests: $message', null, statusCode);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('Server error: $message', null, statusCode);
      default:
        return ServerException('HTTP $statusCode: $message', null, statusCode);
    }
  }

  /// Handle Dio exceptions
  AppException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Request timed out: ${error.message}');
      case DioExceptionType.connectionError:
        return NetworkException('Connection error: ${error.message}');
      case DioExceptionType.badResponse:
        return _createExceptionFromResponse(error.response!);
      case DioExceptionType.cancel:
        return ServerException('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        return UnknownException('Unknown error: ${error.message}');
    }
  }

  /// Make HTTP request with error handling
  Future<Map<String, dynamic>> _makeRequest(
    Future<Response> Function() request, {
    String? customErrorMessage,
  }) async {
    try {
      final response = await request();
      return await _handleResponse(response);
    } on DioException catch (e) {
      _logger.e('Dio error in request: ${e.message}');
      throw _handleDioException(e);
    } on SocketException catch (e) {
      _logger.e('Socket error: ${e.message}');
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      _logger.e('Unexpected error: $e');
      throw UnknownException(customErrorMessage ?? 'Unexpected error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login(LoginParams params) async {
    _logger.i('Remote login attempt for: ${params.email}');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/login',
        data: params.toJson(),
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Login failed',
    );

    _logger.i('Remote login successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> loginWithBiometric(String refreshToken) async {
    _logger.i('Remote biometric login attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/login-with-token',
        data: {'refresh_token': refreshToken},
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Biometric login failed',
    );

    _logger.i('Remote biometric login successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> register(RegisterParams params) async {
    _logger.i('Remote register attempt for: ${params.email}');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/register',
        data: params.toJson(),
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Registration failed',
    );

    _logger.i('Remote registration successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> logout(String accessToken) async {
    _logger.i('Remote logout attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/logout',
        options: Options(
          headers: {...headers, 'Authorization': 'Bearer $accessToken'},
        ),
      ),
      customErrorMessage: 'Logout failed',
    );

    _logger.i('Remote logout successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    _logger.i('Remote token refresh attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Token refresh failed',
    );

    _logger.i('Remote token refresh successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    _logger.i('Remote get current user attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.get(
        '$baseUrl/profile',
        options: Options(
          headers: {...headers, 'Authorization': 'Bearer $accessToken'},
        ),
      ),
      customErrorMessage: 'Failed to get user information',
    );

    _logger.i('Remote get current user successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateProfile(
    String accessToken,
    UpdateProfileParams params,
  ) async {
    _logger.i('Remote update profile attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/profile/update',
        data: params.toJson(),
        options: Options(
          headers: {...headers, 'Authorization': 'Bearer $accessToken'},
        ),
      ),
      customErrorMessage: 'Profile update failed',
    );

    _logger.i('Remote profile update successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> changePassword(
    String accessToken,
    ChangePasswordParams params,
  ) async {
    _logger.i('Remote change password attempt');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/change-password',
        data: params.toJson(),
        options: Options(
          headers: {...headers, 'Authorization': 'Bearer $accessToken'},
        ),
      ),
      customErrorMessage: 'Password change failed',
    );

    _logger.i('Remote password change successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _logger.i('Remote forgot password attempt for: $email');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/forgot-password',
        data: {'email': email},
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Forgot password request failed',
    );

    _logger.i('Remote forgot password successful');
    return response;
  }

  @override
  Future<Map<String, dynamic>> resetPassword(ResetPasswordParams params) async {
    _logger.i('Remote reset password attempt for: ${params.email}');

    final headers = await defaultHeaders;
    final response = await _makeRequest(
      () => client.post(
        '$baseUrl/auth/reset-password',
        data: params.toJson(),
        options: Options(headers: headers),
      ),
      customErrorMessage: 'Password reset failed',
    );

    _logger.i('Remote password reset successful');
    return response;
  }

  @override
  Future<bool> checkConnectivity() async {
    try {
      final headers = await defaultHeaders;
      final response = await client.get(
        '$baseUrl/health',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final isConnected = response.statusCode == 200;
      _logger.d('Connectivity check result: $isConnected');
      return isConnected;
    } catch (e) {
      _logger.w('Connectivity check failed: $e');
      return false;
    }
  }
}
