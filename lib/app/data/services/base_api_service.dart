import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class BaseApiService {
  final Dio client = Dio();
  final storage = const FlutterSecureStorage();
  final logger = Logger();

  String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      logger.e('API_BASE_URL not found in environment variables');
      logger.i('Available env vars: ${dotenv.env.keys.toList()}');
      throw Exception('API_BASE_URL environment variable is required');
    }

    // Ensure URL doesn't end with slash
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    logger.i('Using API base URL: $cleanUrl');
    return cleanUrl;
  }

  /// Get app version from package_info_plus (canonical source)
  Future<String> get appVersion async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      // Validate version format
      final regex = RegExp(r'^\d+\.\d+\.\d+$');
      if (!regex.hasMatch(version)) {
        logger.w(
            'BaseApiService: Invalid version format from package_info: $version, using env fallback');
        final envVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
        return envVersion;
      }

      logger.d(
          'BaseApiService: Using app version from package_info_plus: $version');
      return version;
    } catch (e) {
      logger.w(
          'BaseApiService: package_info_plus not available: $e, using env fallback');

      // Fallback to env variable
      final envVersion = dotenv.env['APP_VERSION'];
      if (envVersion != null && envVersion.isNotEmpty) {
        logger
            .d('BaseApiService: Using fallback version from env: $envVersion');
        return envVersion;
      }

      // Final fallback to default version
      const defaultVersion = '1.0.0';
      logger.w('BaseApiService: Using default version: $defaultVersion');
      return defaultVersion;
    }
  }

  BaseApiService() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final currentVersion = await appVersion;
            options.headers['X-App-Version'] = currentVersion;
            logger.i('Sending X-App-Version header: $currentVersion');
          } catch (e) {
            logger.w('Could not get app version for header: $e');
          }

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
          // Don't handle 426 here - let it propagate to ErrorHandlerService
          // ErrorHandlerService will handle it and trigger the update dialog
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
