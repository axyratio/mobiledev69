import 'package:flutter/foundation.dart';

import '../../../../core/result.dart';
import '../../../../core/safe_change_notifier.dart';
import '../../domain/auth_repository.dart';
import 'auth_view_model.dart';

/// Screen-scoped state + business logic for [LoginScreen] (View talks to
/// this, never to [AuthRepository] directly).
class LoginViewModel extends ChangeNotifier with SafeChangeNotifier {
  LoginViewModel({required AuthRepository repository, required AuthViewModel authViewModel})
      : _repository = repository,
        _authViewModel = authViewModel;

  final AuthRepository _repository;
  final AuthViewModel _authViewModel;

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> submit({required String email, required String password}) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.login(email: email, password: password);

    isSubmitting = false;
    switch (result) {
      case Ok():
        // Refresh the app-wide session so the router's guard redirects to
        // Home; there's nothing screen-local left to update.
        await _authViewModel.completeLogin();
        return true;
      case Err(message: final message):
        errorMessage = message;
        safeNotifyListeners();
        return false;
    }
  }
}
