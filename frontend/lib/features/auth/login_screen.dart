import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/config/app_config.dart';
import 'auth_service.dart';

/// Hosts the Google OIDC flow in an embedded web view (FR-01).
///
/// The Django backend drives the entire OIDC exchange server-side; this
/// screen only has to detect the final redirect back to our own
/// `/api/auth/me/` endpoint, copy the resulting session cookie into
/// [AuthService], and hand control back to the caller.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  final AuthService authService;
  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isCompletingLogin = false;

  Future<void> _handlePageLoaded(Uri? loadedUrl) async {
    if (loadedUrl == null || _isCompletingLogin) return;

    final reachedSessionEndpoint = loadedUrl.toString().startsWith(AppConfig.currentUserUrl);
    if (!reachedSessionEndpoint) return;

    setState(() => _isCompletingLogin = true);
    await _importSessionCookie(loadedUrl);
    widget.onLoginSuccess();
  }

  Future<void> _importSessionCookie(Uri url) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri.uri(url));
    final cookieHeader = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    await widget.authService.importSessionCookie(cookieHeader);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(AppConfig.googleLoginUrl)),
            onLoadStop: (controller, url) => _handlePageLoaded(url),
          ),
          if (_isCompletingLogin)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
