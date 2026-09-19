import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/viewmodels/auth_view_model.dart';

/// Redirects unauthenticated users to `/login` and keeps signed-in users
/// off the auth screens (FR-03: gated screens redirect to login when there
/// is no valid session, and vice versa).
String? authGuard(AuthViewModel authViewModel, GoRouterState state) {
  final status = authViewModel.status;
  final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

  final String? result;
  switch (status) {
    case AuthStatus.unknown:
      result = null; // still checking the session — stay put on the splash route
    case AuthStatus.unauthenticated:
      result = isAuthRoute ? null : '/login';
    case AuthStatus.authenticated:
      result = isAuthRoute ? '/' : null;
  }
  // TEMP DEBUG — remove once the HomeViewModel disposal race is diagnosed.
  debugPrint(
    '[authGuard] status=$status matchedLocation=${state.matchedLocation} -> redirect=$result',
  );
  return result;
}
