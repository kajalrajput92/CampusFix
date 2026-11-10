/// Environment and compile-time configuration for CampusFix.
class AppConfig {
  AppConfig._();

  /// Base API URL supplied via `--dart-define=API_BASE_URL=...`.
  /// Defaults to host Wi-Fi LAN IP (192.168.1.8:8000/api) for physical devices.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.8:8000/api',
  );

  static const String appVersion = '1.0.0';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 20);
}
