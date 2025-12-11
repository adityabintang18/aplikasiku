// Use cases dependencies injection setup
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '../core/interfaces/auth_repository.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';

/// Use cases dependencies injection configuration
/// This class wires up all use case dependencies
class UseCasesDependencies {
  /// Initialize all use case dependencies
  static void init() {
    _initAuthUseCases();
  }

  /// Initialize authentication use cases
  static void _initAuthUseCases() {
    // Login Use Case
    Get.lazyPut<LoginUseCase>(
      () => LoginUseCase(
        authRepository: Get.find<AuthRepository>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Register Use Case
    Get.lazyPut<RegisterUseCase>(
      () => RegisterUseCase(
        authRepository: Get.find<AuthRepository>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Logout Use Case
    Get.lazyPut<LogoutUseCase>(
      () => LogoutUseCase(
        authRepository: Get.find<AuthRepository>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Get Current User Use Case
    Get.lazyPut<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(
        authRepository: Get.find<AuthRepository>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );

    // Get Login Status Use Case
    Get.lazyPut<GetLoginStatusUseCase>(
      () => GetLoginStatusUseCase(
        authRepository: Get.find<AuthRepository>(),
        logger: Get.find<Logger>(),
      ),
      fenix: true,
    );
  }

  /// Dispose of all use case dependencies
  static void dispose() {
    try {
      // Dispose authentication use cases
      if (Get.isRegistered<LoginUseCase>()) {
        Get.delete<LoginUseCase>();
      }

      if (Get.isRegistered<RegisterUseCase>()) {
        Get.delete<RegisterUseCase>();
      }

      if (Get.isRegistered<LogoutUseCase>()) {
        Get.delete<LogoutUseCase>();
      }

      if (Get.isRegistered<GetCurrentUserUseCase>()) {
        Get.delete<GetCurrentUserUseCase>();
      }

      if (Get.isRegistered<GetLoginStatusUseCase>()) {
        Get.delete<GetLoginStatusUseCase>();
      }
    } catch (e) {
      if (Get.isRegistered<Logger>()) {
        Get.find<Logger>().w('Error disposing use case dependencies: $e');
      }
    }
  }
}
