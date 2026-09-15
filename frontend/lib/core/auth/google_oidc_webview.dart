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

  Future<void> _handlePageLoaded(Uri? loadedUrl) async {
    if (loadedUrl == null || _isCompleting) return;

    final reachedSessionEndpoint = loadedUrl.toString().startsWith(AppConfig.currentUserUrl);
    if (!reachedSessionEndpoint) return;

    setState(() => _isCompleting = true);
    await _importSessionCookie(loadedUrl);
    widget.onSuccess();
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
            onLoadStop: (controller, url) => _handlePageLoaded(url),
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
