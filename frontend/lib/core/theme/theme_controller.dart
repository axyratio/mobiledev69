import 'package:flutter/material.dart';

/// App-wide Light/Dark toggle (FR-17). Holds only the in-memory [mode] —
/// persisting it to the backend (FR-18) is the caller's job: `app.dart`
/// seeds it from the session on load, and Settings pushes changes back via
/// `AuthViewModel.updateThemePreference`.
class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  bool get isDark => mode == ThemeMode.dark;

  void toggle() {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode value) {
    if (value == mode) return;
    mode = value;
    notifyListeners();
  }
}
