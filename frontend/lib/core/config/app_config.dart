/// Central configuration module. All backend URLs are derived here so no
/// other file hardcodes a host.
///
/// Override at build/run time, e.g. on an Android emulator (which maps
/// `10.0.2.2` to the host machine's `localhost`):
///   flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
class AppConfig {
  AppConfig._();

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get googleLoginUrl => '$backendBaseUrl/accounts/google/login/';
  static String get logoutUrl => '$backendBaseUrl/accounts/logout/';
  static String get currentUserUrl => '$backendBaseUrl/api/auth/me/';
  static String get registerUrl => '$backendBaseUrl/api/auth/register/';
  static String get loginUrl => '$backendBaseUrl/api/auth/login/';
}
