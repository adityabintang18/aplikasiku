import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:aplikasiku/app/utils/exceptions.dart';

abstract class BaseApiService {
  final Dio client = Dio();
  final storage = const FlutterSecureStorage();
  final logger = Logger();

  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.example.com';

  String get appVersion {
    final version = dotenv.env['APP_VERSION'] ?? '1.0.0';
    // Basic validation: should match x.y.z format
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    if (!regex.hasMatch(version)) {
      throw Exception('Invalid APP_VERSION format: $version. Expected x.y.z');
    }
    return version;
  }

  BaseApiService() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add X-App-Version header
          options.headers['X-App-Version'] = appVersion;
          logger.i('Sending X-App-Version header: $appVersion');

          // Add Authorization header if token exists and not already set
          if (!options.headers.containsKey('Authorization')) {
            final token = await getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              logger.i('Added Authorization header for ${options.uri}');
            } else {
              logger.w('No token found for request to ${options.uri}');
            }
          }

          handler.next(options);
        },
        onError: (DioException e, handler) {
          logger.e(
            'DioException: ${e.message}, status: ${e.response?.statusCode}, url: ${e.requestOptions.uri}',
          );
          // Handle 426 Upgrade Required
          if (e.response?.statusCode == 426) {
            logger.w('Received 426 Upgrade Required, throwing exception');
            throw AppUpdateRequiredException('App update required');
          }
          handler.next(e);
        },
      ),
    );
  }

  /// Get access token from storage
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  /// Get refresh token from storage
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }
}
