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

  /// The same Google OAuth **web** client ID the backend uses (allauth's
  /// `GOOGLE_OIDC_CLIENT_ID`). Passed to `GoogleSignIn` as
  /// `serverClientId` so the ID token it returns on mobile has this as its
  /// audience — letting the backend verify it with the client it already
  /// has, without a separate mobile-specific secret. Get it from Google
  /// Cloud Console → Credentials (the existing "Web client" entry), then
  /// pass at build/run time:
  ///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Full-page redirect target for the web login flow (FR-01) — the
  /// browser tab navigates here directly since it's already a real
  /// browser session; Google shows its normal account picker because
  /// it's the browser's own session, not an embedded web view.
  static String get googleLoginUrl => '$backendBaseUrl/accounts/google/login/';

  /// Trades a Google ID token (from the mobile app's native Sign-In SDK)
  /// for a session cookie (FR-01).
  static String get googleTokenLoginUrl => '$backendBaseUrl/api/auth/google/token/';
  static String get logoutUrl => '$backendBaseUrl/accounts/logout/';
  static String get currentUserUrl => '$backendBaseUrl/api/auth/me/';
  static String get registerUrl => '$backendBaseUrl/api/auth/register/';
  static String get loginUrl => '$backendBaseUrl/api/auth/login/';
  static String get updateThemePreferenceUrl => '$backendBaseUrl/api/auth/theme/';
  static String get updateCefrLevelUrl => '$backendBaseUrl/api/auth/cefr-level/';
  static String get updateCefrLevelFilterUrl =>
      '$backendBaseUrl/api/auth/cefr-level-filter/';
  static String get updateHighlightLevelFilterUrl =>
      '$backendBaseUrl/api/auth/highlight-level-filter/';
  static String get storiesUrl => '$backendBaseUrl/api/stories/';
  static String get storiesGenerateUrl =>
      '$backendBaseUrl/api/stories/generate/';
  static String storyDetailUrl(int id) => '$backendBaseUrl/api/stories/$id/';
  static String get wordsTodayUrl => '$backendBaseUrl/api/words/today/';
  static String get wordsRandomUrl => '$backendBaseUrl/api/words/random/';
  static String get wordsSearchUrl => '$backendBaseUrl/api/words/search/';
}
