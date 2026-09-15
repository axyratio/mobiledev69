import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../domain/auth_repository.dart';
import '../../domain/models/session_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide session state, checked once at startup and after login/logout
/// (FR-03: gated screens redirect to login when there is no valid session).
/// Consumed by `router/app_router.dart` as the route guard's source of
/// truth via `refreshListenable`.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.unknown;
  SessionUser? currentUser;

  Future<void> checkSession() async {
    final result = await _repository.fetchCurrentUser();
    final user = switch (result) {
      Ok(value: final value) => value,
      Err() => null,
    };
    currentUser = user;
    status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  /// Called once a login/sign-up/OIDC flow has established a fresh session
  /// cookie, so the router can pick up the change and redirect to Home.
  Future<void> completeLogin() => checkSession();

  Future<void> logout() async {
    await _repository.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
