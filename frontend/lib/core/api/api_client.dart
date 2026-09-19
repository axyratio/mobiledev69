import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Thin wrapper around the shared [Dio] instance every repository talks
/// through. This is the "Service" layer's HTTP client (ApiClient) — it
/// knows nothing about auth-specific endpoints or domain models, only how
/// to make cookie-authenticated requests.
class ApiClient {
  ApiClient._(this.dio);

  final Dio dio;

  static Future<ApiClient> create({required CookieJar cookieJar}) async {
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
    return ApiClient._(dio);
  }
}
