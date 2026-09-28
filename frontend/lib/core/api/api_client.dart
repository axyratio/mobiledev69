import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_appauth/flutter_appauth.dart';

import '../auth/token_store.dart';
import '../config/app_config.dart';

/// Thin wrapper around the shared [Dio] instance every repository talks
/// through. This is the "Service" layer's HTTP client (ApiClient) — it
/// knows nothing about auth-specific endpoints or domain models, only how
/// to make authenticated requests.
///
/// Web keeps using cookie-based sessions (see [SessionStore]/[CookieManager]
/// below). Mobile instead authenticates via this backend's own OIDC
/// provider (FR-01) and never gets a session cookie, so every request here
/// attaches whatever access token [TokenStore] holds as a Bearer header,
/// transparently refreshing it once on a 401 before giving up.
class ApiClient {
  ApiClient._(this.dio);

  final Dio dio;

  static Future<ApiClient> create({
    required CookieJar cookieJar,
    required TokenStore tokenStore,
  }) async {
    final dio = Dio(
      BaseOptions(
        validateStatus: (status) => status != null && status < 500,
        // Flutter web only: the browser's XHR adapter reads this to decide
        // whether to send/accept cookies on a cross-origin request (the
        // frontend and backend are on different Render domains). Ignored
        // on mobile, where CookieManager below does the equivalent job.
        extra: {'withCredentials': true},
      ),
    );
    // dio_cookie_manager asserts against being constructed at all on web
    // ("Don't use the manager in Web environments") — the browser already
    // handles cookies natively there via withCredentials above, so this
    // interceptor is both unnecessary and disallowed on that platform.
    if (!kIsWeb) {
      dio.interceptors.add(CookieManager(cookieJar));
    }
    dio.interceptors.add(_BearerTokenInterceptor(dio, tokenStore));
    return ApiClient._(dio);
  }
}

/// Attaches `Authorization: Bearer <access_token>` from [TokenStore] when
/// present (mobile only — [TokenStore] stays empty on web, which
/// authenticates via cookie instead, see `oidc_auth.dart`). On a 401,
/// tries exchanging the stored refresh token once via `/openid/token/`
/// before giving up, so a short-lived access token (1h, `OIDC_TOKEN_EXPIRE`)
/// doesn't force the user to sign in again on every app reopen.
class _BearerTokenInterceptor extends Interceptor {
  _BearerTokenInterceptor(this._dio, this._tokenStore);

  final Dio _dio;
  final TokenStore _tokenStore;
  static const _retriedFlag = 'bearer_retry_attempted';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _tokenStore.accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    if (err.response?.statusCode != 401 || alreadyRetried) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStore.refreshToken;
    if (refreshToken == null) return handler.next(err);

    try {
      final refreshed = await const FlutterAppAuth().token(
        TokenRequest(
          AppConfig.oidcClientId,
          AppConfig.oidcRedirectUri,
          issuer: AppConfig.oidcIssuer,
          refreshToken: refreshToken,
          grantType: 'refresh_token',
          allowInsecureConnections: !AppConfig.backendBaseUrl.startsWith('https'),
        ),
      );
      final newAccessToken = refreshed.accessToken;
      if (newAccessToken == null) return handler.next(err);

      await _tokenStore.save(
        accessToken: newAccessToken,
        refreshToken: refreshed.refreshToken,
      );

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra[_retriedFlag] = true;
      final retryResponse = await _dio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh token itself is invalid/expired — nothing left to do but
      // surface the original 401 so the app routes back to login.
      return handler.next(err);
    }
  }
}
