/// Environment and compile-time configuration for CampusFix.
class AppConfig {
  AppConfig._();

  /// Base API URL supplied via `--dart-define=API_BASE_URL=...`.
  /// Defaults to Android emulator loopback alias (10.0.2.2:8000/api).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const String appVersion = '1.0.0';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 20);
}
