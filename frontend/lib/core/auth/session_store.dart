import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the backend's session cookie on-device (FR-01/FR-02).
///
/// The Django backend authenticates via session cookies (django-allauth),
/// not bearer tokens, so this is the app's "token store" equivalent: a
/// [PersistCookieJar] that survives app restarts. [ApiClient] attaches it
/// to Dio as a cookie-jar interceptor; this class only owns its lifecycle
/// (creation, clearing it on logout).
class SessionStore {
  SessionStore._(this._cookieJar);

  final PersistCookieJar _cookieJar;

  PersistCookieJar get cookieJar => _cookieJar;

  static Future<SessionStore> create() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${appDir.path}/.cookies/'));
    return SessionStore._(cookieJar);
  }

  Future<void> clear() => _cookieJar.deleteAll();
}
