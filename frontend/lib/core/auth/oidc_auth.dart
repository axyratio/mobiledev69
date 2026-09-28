import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../config/app_config.dart';
import 'token_store.dart';

const _oidcScopes = ['openid', 'profile', 'email', 'app_profile'];

/// Guards against a second OIDC flow starting while one is still in flight.
/// AppAuth-Android keeps only a single pending-request state at a time; a
/// second `authorizeAndExchangeCode` call (e.g. from an impatient double-tap
/// on "Continue via OIDC" before the browser finishes loading) overwrites
/// that state, so the first flow's callback comes back with "No stored
/// state - unable to handle response" once the user finally completes it.
bool _oidcFlowInProgress = false;

/// Signs in via this backend's own OIDC provider (FR-01), choosing the right
/// flow per platform.
Future<void> signInWithOidc(BuildContext context) async {
  if (_oidcFlowInProgress) return;
  _oidcFlowInProgress = true;
  try {
    await (kIsWeb ? _signInOnWeb(context) : _signInOnMobile(context));
  } finally {
    _oidcFlowInProgress = false;
  }
}

/// Flutter web already runs inside a real browser tab, so a plain full-page
/// redirect straight to the backend's login page is enough — it sets a
/// normal session cookie there directly, no separate token exchange needed.
/// The backend sends the tab back to FRONTEND_URL once login completes,
/// landing on a fresh load of this same app, which re-checks the session on
/// startup ([AuthViewModel.checkSession]) and picks up the cookie the
/// redirect just set.
Future<void> _signInOnWeb(BuildContext context) async {
  await launchUrl(Uri.parse(AppConfig.oidcLoginUrl), webOnlyWindowName: '_self');
}

/// Mobile opens the system browser for the standard OIDC Authorization Code
/// + PKCE flow (`flutter_appauth` wraps AppAuth Android/iOS), landing back
/// in the app via [AppConfig.oidcRedirectUri]'s custom URL scheme. Unlike
/// the web flow, this never gets a session cookie — the access/refresh
/// tokens returned here are stored in [TokenStore] and attached as a
/// Bearer header by [ApiClient]'s interceptor on every later request.
///
/// `promptValues: ['login']` forces the backend to show its login form
/// every time, even if the system browser still has a session cookie from a
/// previous account — this button only ever appears on [LoginScreen] (i.e.
/// the app itself has no session yet), so there's no case where skipping
/// straight to the old account would be the right call; forcing it is also
/// the only way `django-oidc-provider` supports switching accounts, since
/// it doesn't implement a real `select_account` chooser (single Django
/// session per browser, not Google's "multiple signed-in accounts").
Future<void> _signInOnMobile(BuildContext context) async {
  final tokenStore = context.read<TokenStore>();
  final authViewModel = context.read<AuthViewModel>();

  final AuthorizationTokenResponse response;
  try {
    response = await const FlutterAppAuth().authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AppConfig.oidcClientId,
        AppConfig.oidcRedirectUri,
        issuer: AppConfig.oidcIssuer,
        scopes: _oidcScopes,
        promptValues: const ['login'],
        allowInsecureConnections: !AppConfig.backendBaseUrl.startsWith('https'),
      ),
    );
  } on FlutterAppAuthUserCancelledException {
    return; // user backed out of the system browser sheet
  } catch (_) {
    if (!context.mounted) return;
    _showError(context, 'ลงชื่อเข้าใช้ไม่สำเร็จ กรุณาลองใหม่');
    return;
  }

  final accessToken = response.accessToken;
  if (accessToken == null) {
    if (!context.mounted) return;
    _showError(context, 'ไม่ได้รับข้อมูลยืนยันตัวตน กรุณาลองใหม่');
    return;
  }

  await tokenStore.save(accessToken: accessToken, refreshToken: response.refreshToken);
  if (!context.mounted) return;
  await authViewModel.completeLogin();
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
