import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/config/app_config.dart';

/// Authenticated-user snapshot returned by GET /api/auth/me/.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.name,
    required this.themePreference,
  });

  final int id;
  final String email;
  final String name;
  final String themePreference;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      themePreference: json['theme_preference'] as String? ?? 'light',
    );
  }
}

/// Wraps all backend auth calls behind a single cookie-aware HTTP client.
///
/// The Django backend authenticates via session cookies (django-allauth),
/// not bearer tokens, so this service persists the `sessionid` cookie
/// across app restarts with a [PersistCookieJar] rather than storing a JWT.
class AuthService {
  AuthService._(this._dio, this._cookieJar);

  final Dio _dio;
  final PersistCookieJar _cookieJar;

  static Future<AuthService> create() async {
    final dio = Dio(
      BaseOptions(validateStatus: (status) => status != null && status < 500),
    );
    final appDir = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${appDir.path}/.cookies/'));
    dio.interceptors.add(CookieManager(cookieJar));
    return AuthService._(dio, cookieJar);
  }

  /// Returns the current session's user, or null if there is no valid
  /// session (backend responds 401) — drives FR-03's redirect-to-login.
  Future<SessionUser?> fetchCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>(AppConfig.currentUserUrl);
    final body = response.data ?? const <String, dynamic>{};
    if (body['is_authenticated'] != true) return null;
    return SessionUser.fromJson(body);
  }

  /// Copies the session cookie captured by the OIDC web view into this
  /// service's cookie jar so subsequent Dio calls are authenticated too.
  Future<void> importSessionCookie(String rawCookieHeader) async {
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
    await _cookieJar.saveFromResponse(Uri.parse(AppConfig.backendBaseUrl), cookies);
  }

  /// Clears the session both server-side and on-device (FR-02).
  Future<void> logout() async {
    await _dio.get<void>(
      AppConfig.logoutUrl,
      options: Options(followRedirects: false, validateStatus: (status) => true),
    );
    await _cookieJar.deleteAll();
  }
}
