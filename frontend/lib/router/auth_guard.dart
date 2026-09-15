import 'package:go_router/go_router.dart';

import '../features/auth/presentation/viewmodels/auth_view_model.dart';

/// Redirects unauthenticated users to `/login` and keeps signed-in users
/// off the auth screens (FR-03: gated screens redirect to login when there
/// is no valid session, and vice versa).
String? authGuard(AuthViewModel authViewModel, GoRouterState state) {
  final status = authViewModel.status;
  final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

  switch (status) {
    case AuthStatus.unknown:
      return null; // still checking the session — stay put on the splash route
    case AuthStatus.unauthenticated:
      return isAuthRoute ? null : '/login';
    case AuthStatus.authenticated:
      return isAuthRoute ? '/' : null;
  }
}
