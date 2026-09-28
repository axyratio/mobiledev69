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

  /// The `client_id` of the OIDC `Client` registered for this app in the
  /// backend's own `/admin/` (django-oidc-provider) — public client, PKCE,
  /// `redirect_uris` set to [oidcRedirectUri]. Pass at build/run time:
  ///   flutter run --dart-define=OIDC_CLIENT_ID=xxxxxx
  static const String oidcClientId = String.fromEnvironment('OIDC_CLIENT_ID');

  /// The custom URL scheme the OS hands back to this app once the system
  /// browser finishes the OIDC redirect (FR-01) — must exactly match one of
  /// the Client's registered `redirect_uris`, and the scheme half must match
  /// `appAuthRedirectScheme` in `android/app/build.gradle.kts` /
  /// `CFBundleURLSchemes` in `ios/Runner/Info.plist`.
  static const String oidcRedirectUri = 'com.example.frontend:/oauth2redirect';

  /// This backend's own OIDC issuer (see `/openid/.well-known/openid-configuration/`),
  /// used by `flutter_appauth` to discover the authorize/token endpoints.
  static String get oidcIssuer => '$backendBaseUrl/openid';

  /// Full-page redirect target for the web login flow (FR-01) — the browser
  /// tab navigates straight to this backend's own login page (not through
  /// `/openid/authorize/`, since the browser tab already gets a normal
  /// session cookie from logging in there directly) and comes back to
  /// [AppConfig.backendBaseUrl]'s configured `FRONTEND_URL` once done.
  static String get oidcLoginUrl => '$backendBaseUrl/accounts/login/';

  static String get logoutUrl => '$backendBaseUrl/accounts/logout/';
  static String get currentUserUrl => '$backendBaseUrl/api/auth/me/';
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
