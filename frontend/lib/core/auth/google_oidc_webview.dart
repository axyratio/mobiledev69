import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/app_config.dart';
import 'session_store.dart';

/// Hosts the Google OIDC flow in an embedded web view (FR-01).
///
/// The Django backend drives the entire OIDC exchange server-side; this
/// screen only has to detect the final redirect back to our own
/// `/api/auth/me/` endpoint, copy the resulting session cookie into
/// [SessionStore], and hand control back to the caller. Shared by both the
/// login and sign-up screens: allauth's `/accounts/google/login/` endpoint
/// transparently creates the account on first sign-in, so there's nothing
/// sign-up-specific about this flow.
///
/// This lives in `core/auth` rather than behind [AuthRepository] because
/// it's an interactive redirect capture, not a single request/response
/// call — it doesn't fit the repository's request-based contract.
class GoogleOAuthScreen extends StatefulWidget {
  const GoogleOAuthScreen({super.key, required this.sessionStore, required this.onSuccess});

  final SessionStore sessionStore;
  final VoidCallback onSuccess;

  @override
  State<GoogleOAuthScreen> createState() => _GoogleOAuthScreenState();
}

class _GoogleOAuthScreenState extends State<GoogleOAuthScreen> {
  bool _isCompleting = false;

  // Intercepted before the navigation actually loads (unlike onLoadStop,
  // which fires *after* the page renders) — LOGIN_REDIRECT_URL points at a
  // raw JSON endpoint, and letting the WebView load JSON as a "page" is
  // unreliable across platforms (some never fire onLoadStop for a
  // non-HTML response), which is what left the JSON stuck on screen.
  Future<NavigationActionPolicy> _interceptNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null || _isCompleting) return NavigationActionPolicy.ALLOW;

    final reachedSessionEndpoint = url.toString().startsWith(AppConfig.currentUserUrl);
    if (!reachedSessionEndpoint) return NavigationActionPolicy.ALLOW;

    setState(() => _isCompleting = true);
    await _importSessionCookie(url);
    widget.onSuccess();
    // This screen was pushed with a plain Navigator.push, on top of
    // go_router's own navigator — go_router's redirect (triggered by
    // onSuccess updating AuthViewModel) can't dismiss a route it doesn't
    // manage, so without this the WebView would sit there forever.
    if (mounted) Navigator.of(context).pop();
    return NavigationActionPolicy.CANCEL;
  }

  Future<void> _importSessionCookie(Uri url) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri.uri(url));
    final cookieHeader = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
    await widget.sessionStore.importCookieHeader(cookieHeader, Uri.parse(AppConfig.backendBaseUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Continue with Google')),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(AppConfig.googleLoginUrl)),
            shouldOverrideUrlLoading: _interceptNavigation,
          ),
          if (_isCompleting)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
