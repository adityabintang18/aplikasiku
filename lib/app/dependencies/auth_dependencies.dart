// Authentication dependencies injection setup
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../core/interfaces/auth_repository.dart';
import '../core/interfaces/auth_remote_data_source.dart';
import '../core/interfaces/auth_local_data_source.dart';
import '../core/interfaces/network_info.dart';

import '../data/repositories/auth_repository_impl.dart';
import '../data/datasources/auth_remote_data_source_impl.dart';
import '../data/datasources/auth_local_data_source_impl.dart';
import '../core/services/network_info_impl.dart';
// import '../core/entities/user_entity.dart';

/// Authentication dependencies injection configuration
/// This class wires up all authentication-related dependencies
class AuthDependencies {
  /// Initialize all authentication dependencies
  static void init() {
    _initCoreDependencies();
    _initDataSources();
    _initRepository();
  }

  /// Initialize core dependencies (Logger, Storage, Network, etc.)
  static void _initCoreDependencies() {
    // Logger
    Get.lazyPut<Logger>(
      () => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 5,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: false,
        ),
      ),
      fenix: true,
    );

    // Dio HTTP Client
    Get.lazyPut<Dio>(() {
      final dio = Dio();

      // Base configuration
      dio.options.baseUrl = 'https://api.example.com'; // TODO: Move to config
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(seconds: 30);

      // Headers
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Interceptors
      dio.interceptors.addAll([
        // TODO: Add Auth Interceptor
        // AuthInterceptor(Get.find<AuthRepository>()),

        // Logger Interceptor
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => Get.find<Logger>().d(obj),
        ),

        // Error Interceptor
        InterceptorsWrapper(
          onError: (DioException e, ErrorInterceptorHandler handler) {
            Get.find<Logger>().e('Dio Error: ${e.message}');
            handler.next(e);
          },
        ),
      ]);

      return dio;
    }, fenix: true);

    // Flutter Secure Storage
    Get.lazyPut<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          accountName: 'aplikasiku_secure_storage',
        ),
      ),
      fenix: true,
    );
  }

  /// Initialize data sources
  static void _initDataSources() {
    // Auth Remote Data Source
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Auth Local Data Source
    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        secureStorage: Get.find<FlutterSecureStorage>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Network Info Service - Simplified for now
    Get.lazyPut<NetworkInfo>(
      () => NetworkInfoImpl(logger: Get.find<Logger>()),
      fenix: true,
    );
  }

  /// Initialize repository
  static void _initRepository() {
    // Auth Repository
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
        localDataSource: Get.find<AuthLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );
  }

  /// Dispose of all authentication dependencies (for testing or cleanup)
  static void dispose() {
    try {
      // Dispose repository
      if (Get.isRegistered<AuthRepository>()) {
        Get.delete<AuthRepository>();
      }

      // Dispose data sources
      if (Get.isRegistered<AuthRemoteDataSource>()) {
        Get.delete<AuthRemoteDataSource>();
      }

      if (Get.isRegistered<AuthLocalDataSource>()) {
        Get.delete<AuthLocalDataSource>();
      }

      if (Get.isRegistered<NetworkInfo>()) {
        Get.delete<NetworkInfo>();
      }

      // Dispose core dependencies
      if (Get.isRegistered<Logger>()) {
        Get.delete<Logger>();
      }

      if (Get.isRegistered<Dio>()) {
        Get.delete<Dio>();
      }

      if (Get.isRegistered<FlutterSecureStorage>()) {
        Get.delete<FlutterSecureStorage>();
      }
    } catch (e) {
      if (Get.isRegistered<Logger>()) {
        Get.find<Logger>().w('Error disposing auth dependencies: $e');
      }
    }
  }

  /// Reset all authentication state (useful for logout)
  static void resetAuthState() {
    try {
      // Clear local data source
      if (Get.isRegistered<AuthLocalDataSource>()) {
        Get.find<AuthLocalDataSource>().clearSession();
      }

      // Reset repository state (if needed)
      // Repository will automatically fetch fresh data on next call
    } catch (e) {
      if (Get.isRegistered<Logger>()) {
        Get.find<Logger>().w('Error resetting auth state: $e');
      }
    }
  }
}
