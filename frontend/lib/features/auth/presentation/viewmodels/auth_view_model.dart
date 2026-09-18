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

  /// Persists a new theme choice (Settings) and updates the in-memory
  /// session so every screen sees it immediately.
  Future<void> updateThemePreference(String theme) async {
    final result = await _repository.updateThemePreference(theme);
    switch (result) {
      case Ok(value: final user):
        currentUser = user;
        notifyListeners();
      case Err():
        break;
    }
  }

  /// Persists a new CEFR level choice (Story Detail highlight filter) and
  /// updates the in-memory session so every screen sees it immediately.
  Future<void> updateCefrLevel(String level) async {
    final result = await _repository.updateCefrLevel(level);
    switch (result) {
      case Ok(value: final user):
        currentUser = user;
        notifyListeners();
      case Err():
        break;
    }
  }

  /// Persists the "randomize by my level" toggle (Settings) and updates the
  /// in-memory session so every screen sees it immediately.
  Future<void> updateCefrLevelFilterEnabled(bool enabled) async {
    final result = await _repository.updateCefrLevelFilterEnabled(enabled);
    switch (result) {
      case Ok(value: final user):
        currentUser = user;
        notifyListeners();
      case Err():
        break;
    }
  }

  /// Persists the "highlight by my level" toggle (Settings) and updates the
  /// in-memory session so every screen sees it immediately.
  Future<void> updateHighlightFilterByLevelEnabled(bool enabled) async {
    final result = await _repository.updateHighlightFilterByLevelEnabled(enabled);
    switch (result) {
      case Ok(value: final user):
        currentUser = user;
        notifyListeners();
      case Err():
        break;
    }
  }
}
