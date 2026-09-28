import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the OIDC tokens the mobile app gets back from `/openid/token/`
/// (FR-01/FR-02) — the native-app equivalent of [SessionStore]'s cookie jar,
/// since the app authenticates against this backend's own OIDC provider via
/// `flutter_appauth` instead of a browser session.
///
/// Only ever populated on mobile ([signInWithOidc]'s non-web branch); Flutter
/// web keeps using the cookie-based flow, so [accessToken] just stays null
/// there and [ApiClient]'s interceptor never attaches an Authorization
/// header.
class TokenStore {
  TokenStore._(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'oidc_access_token';
  static const _refreshTokenKey = 'oidc_refresh_token';

  factory TokenStore.create() => TokenStore._(const FlutterSecureStorage());

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);

  Future<void> save({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
