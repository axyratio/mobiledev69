import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the backend's session cookie on-device (FR-01/FR-02).
///
/// The Django backend authenticates via session cookies (django-allauth),
/// not bearer tokens, so this is the app's "token store" equivalent: a
/// [PersistCookieJar] that survives app restarts. [ApiClient] attaches it
/// to Dio as a cookie-jar interceptor; this class only owns its lifecycle
/// (creation, importing a cookie captured from the OIDC web view, clearing
/// it on logout).
class SessionStore {
  SessionStore._(this._cookieJar);

  final PersistCookieJar _cookieJar;

  PersistCookieJar get cookieJar => _cookieJar;

  static Future<SessionStore> create() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${appDir.path}/.cookies/'));
    return SessionStore._(cookieJar);
  }

  /// Copies the session cookie captured by the OIDC web view (a raw
  /// `name=value; name2=value2` header string) into the persisted jar so
  /// subsequent Dio calls are authenticated too.
  Future<void> importCookieHeader(String rawCookieHeader, Uri baseUrl) async {
    if (rawCookieHeader.isEmpty) return;
    final cookies = rawCookieHeader
        .split(';')
        .map((pair) => pair.trim())
        .where((pair) => pair.contains('='))
        .map((pair) {
          final separatorIndex = pair.indexOf('=');
          final name = pair.substring(0, separatorIndex);
          final value = pair.substring(separatorIndex + 1);
          return Cookie(name, value);
        })
        .toList();
    await _cookieJar.saveFromResponse(baseUrl, cookies);
  }

  Future<void> clear() => _cookieJar.deleteAll();
}
