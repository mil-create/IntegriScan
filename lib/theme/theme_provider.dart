import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Global theme state. Wrap the app in `ChangeNotifierProvider` and any
/// widget that calls `context.watch<ThemeProvider>()` rebuilds
/// automatically when [toggleTheme] fires — the Flutter equivalent of a
/// React context + useState pair.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  AppColors get colors => _isDarkMode ? AppColors.dark : AppColors.light;
  Brightness get brightness =>
      _isDarkMode ? Brightness.dark : Brightness.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }
}
