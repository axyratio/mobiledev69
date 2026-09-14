import 'package:flutter/foundation.dart';

import 'auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide session state, checked once at startup and after login/logout
/// (FR-03: gated screens redirect to login when there is no valid session).
class AuthState extends ChangeNotifier {
  AuthState(this.authService);

  final AuthService authService;

  AuthStatus status = AuthStatus.unknown;
  SessionUser? currentUser;

  Future<void> checkSession() async {
    final user = await authService.fetchCurrentUser();
    currentUser = user;
    status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  /// Called by LoginScreen once the OIDC web view reaches the backend's
  /// session endpoint with a fresh cookie already imported.
  Future<void> completeLogin() => checkSession();

  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
