class AppUpdateRequiredException implements Exception {
  final String message;
  AppUpdateRequiredException(this.message);

  @override
  String toString() => 'AppUpdateRequiredException: $message';
}
