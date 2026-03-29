/// Application-wide configuration constants.
/// Change [baseUrl] to point to your real backend.
class AppConfig {
  AppConfig._();

  /// Base URL for all REST API calls.
  /// Override at runtime by calling [setBaseUrl] (persisted via SharedPreferences).
  static String baseUrl = 'http://localhost:8080/api';

  /// App metadata
  static const String appName = 'Attendance Manager';
  static const String appVersion = '1.0.0';

  /// Toggle this to `true` to use built-in dummy data (no backend needed).
  static bool useDummyData = false;
}
