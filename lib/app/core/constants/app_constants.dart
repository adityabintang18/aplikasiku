// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Aplikasiku';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String apiKeyKey = 'API_KEY';
  static const String appVersionKey = 'APP_VERSION';

  // Storage Keys
  static const String tokenKey = 'token';
  static const String biometricEmailKey = 'biometric_email';
  static const String fingerprintIdKey = 'fingerprint_id';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricNeedsPasswordKey = 'biometric_needs_password';

  // Route Names
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String transactionRoute = '/transaction';
  static const String statisticRoute = '/statistic';
  static const String profileRoute = '/profile';
  static const String updateRequiredRoute = '/update-required';
  static const String transactionDetailRoute = '/transaction-detail';

  // Timeout durations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDelay = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 255;
  static const int maxPhoneLength = 20;
  static const int maxTitleLength = 255;
  static const int maxDescriptionLength = 1000;

  // File upload
  static const int maxFileSizeBytes = 2048 * 1024; // 2MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayDateTimeFormat = 'dd MMM yyyy HH:mm';
}
