import 'package:flutter/material.dart';

/// App-wide Light/Dark toggle (FR-17). Deliberately in-memory only for now —
/// persisting the preference (FR-18, an Extra Feature) is a later pass, so
/// this never touches local storage or the backend.
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
