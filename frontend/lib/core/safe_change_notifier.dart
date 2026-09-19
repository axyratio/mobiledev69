import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] mixin for ViewModels that do async work (typically
/// started right from the constructor) and call [notifyListeners] again
/// once it resolves.
///
/// That resolution can land *after* the screen — and its ViewModel — has
/// already been disposed (e.g. a fast post-login redirect tears down the
/// screen that kicked off a `load()` before its `Future.wait(...)`
/// resolves), and plain [notifyListeners] asserts on a disposed
/// [ChangeNotifier], crashing with "A FooViewModel was used after being
/// disposed." Call [safeNotifyListeners] instead everywhere a
/// [notifyListeners] call follows an `await`.
mixin SafeChangeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }
}
