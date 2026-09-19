import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../config/app_config.dart';
import '../result.dart';

/// Signs in with Google (FR-01), choosing the right flow per platform so
/// Google's account picker shows the accounts already signed in — instead
/// of asking to type credentials from scratch, which is what an embedded
/// web view (no access to the device's/browser's Google session) forced.
Future<void> signInWithGoogle(BuildContext context) {
  return kIsWeb ? _signInOnWeb(context) : _signInOnMobile(context);
}

/// Flutter web already runs inside a real browser tab, so a plain
/// full-page redirect is enough — Google sees the same browser profile the
/// user is already signed into, no popup or SDK needed. The backend sends
/// the tab back to FRONTEND_URL once the OIDC flow completes, landing on a
/// fresh load of this same app, which re-checks the session on startup
/// ([AuthViewModel.checkSession]) and picks up the cookie the redirect
/// just set.
Future<void> _signInOnWeb(BuildContext context) async {
  await launchUrl(Uri.parse(AppConfig.googleLoginUrl), webOnlyWindowName: '_self');
}

/// Mobile uses the native Google Sign-In SDK (Google Play Services /
/// iOS's own SDK) instead of any browser at all, so the account picker is
/// the OS's own — sharing whatever Google account is already signed in on
/// the device. `serverClientId` makes the returned ID token's audience
/// the same web client the backend already trusts (FR-01), which trades
/// it for a real session cookie via [AuthRepository.loginWithGoogleIdToken].
Future<void> _signInOnMobile(BuildContext context) async {
  final repository = context.read<AuthRepository>();
  final authViewModel = context.read<AuthViewModel>();

  final googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: AppConfig.googleWebClientId,
  );

  GoogleSignInAccount? account;
  try {
    account = await googleSignIn.signIn();
  } catch (error) {
    // User cancelled the native sheet — not an error worth surfacing.
    if (error is PlatformException && error.code == GoogleSignIn.kSignInCanceledError) {
      return;
    }
    if (!context.mounted) return;
    _showError(context, 'ลงชื่อเข้าใช้ด้วย Google ไม่สำเร็จ กรุณาลองใหม่');
    return;
  }
  if (account == null) return; // user cancelled the account picker
  if (!context.mounted) return;

  final idToken = (await account.authentication).idToken;
  if (idToken == null) {
    if (!context.mounted) return;
    _showError(
      context,
      'ไม่ได้รับข้อมูลยืนยันจาก Google กรุณาลองใหม่ (ถ้ายังไม่ได้ ให้ลองออกจากระบบ Google ในแอปอื่นแล้วลองใหม่)',
    );
    return;
  }
  if (!context.mounted) return;

  final result = await repository.loginWithGoogleIdToken(idToken);
  if (!context.mounted) return;

  switch (result) {
    case Ok():
      await authViewModel.completeLogin();
    case Err(message: final message):
      _showError(context, message);
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
