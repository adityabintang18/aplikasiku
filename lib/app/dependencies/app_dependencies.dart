// Main application dependencies injection initializer
import 'package:get/get.dart';

import 'auth_dependencies.dart';
import 'usecases_dependencies.dart';
// TODO: Add other dependency modules as they're implemented
// import 'transaction_dependencies.dart';
// import 'profile_dependencies.dart';

/// Main application dependencies injection setup
/// This class initializes all dependency modules in the correct order
class AppDependencies {
  /// Initialize all application dependencies
  static void init() {
    // Initialize in dependency order (low-level first)

    // 1. Core dependencies (Logger, Storage, etc.)
    // These are initialized within AuthDependencies

    // 2. Authentication dependencies (high priority)
    AuthDependencies.init();

    // 3. Use Cases dependencies (business logic layer)
    UseCasesDependencies.init();

    // 4. Other feature dependencies (initialize when ready)
    // TransactionDependencies.init();
    // ProfileDependencies.init();

    // 5. Cross-cutting concerns (error handling, analytics, etc.)
    _initErrorHandling();
    _initGlobalConfigs();
  }

  /// Initialize error handling and logging
  static void _initErrorHandling() {
    // Global error handler setup
    // This can be expanded to include crash reporting, analytics, etc.
    Get.config(
      // Configure GetX global settings
      enableLog: true,
      logWriterCallback: (text, {bool isError = false}) {
        // Route logs to your preferred logging system
        // For now, they're handled by the Logger instances
      },
    );
  }

  /// Initialize global configurations
  static void _initGlobalConfigs() {
    // Set up any global app configurations
    // This could include theme, localization, etc.
  }

  /// Clean up all dependencies (useful for testing or app reset)
  static void dispose() {
    AuthDependencies.dispose();
    UseCasesDependencies.dispose();
    // Add other dependencies disposal here
  }

  /// Reset all application state (useful for logout or app restart)
  static void resetAppState() {
    AuthDependencies.resetAuthState();
    // Reset other module states here
  }
}
