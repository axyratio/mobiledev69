import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Persists the backend's session cookie on-device (FR-01/FR-02).
///
/// The Django backend authenticates via session cookies (django-allauth),
/// not bearer tokens, so this is the app's "token store" equivalent: a
/// [CookieJar] [ApiClient] attaches to Dio as a cookie-jar interceptor;
/// this class only owns its lifecycle (creation, clearing it on logout).
///
/// On mobile/desktop this is a [PersistCookieJar] backed by a real file
/// (survives app restarts). On web there's no filesystem to write to —
/// `getApplicationDocumentsDirectory()` throws `MissingPluginException`
/// there — and it wouldn't matter anyway: the actual session cookie is
/// cross-origin, so the *browser* holds it (via `withCredentials` on
/// [ApiClient]'s Dio instance), invisible to this jar either way. A plain
/// in-memory [CookieJar] is enough to satisfy [CookieManager]'s API.
class SessionStore {
  SessionStore._(this._cookieJar);

  final CookieJar _cookieJar;

  CookieJar get cookieJar => _cookieJar;

  static Future<SessionStore> create() async {
    if (kIsWeb) return SessionStore._(CookieJar());
    final appDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${appDir.path}/.cookies/'));
    return SessionStore._(cookieJar);
  }

  Future<void> clear() => _cookieJar.deleteAll();
}
