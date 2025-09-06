import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAnimating = false;

  ThemeMode get themeMode => _themeMode;
  bool get isAnimating => _isAnimating;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[themeModeIndex];
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.system;
    }
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      // Handle error silently
    }
  }

  // Toggle between light and dark theme with animation
  Future<void> toggleTheme() async {
    _isAnimating = true;
    notifyListeners();

    // Small delay to trigger animation
    await Future.delayed(const Duration(milliseconds: 30));

    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // If system mode, check current brightness and toggle opposite
      _themeMode = ThemeMode.light;
    }

    await _saveTheme();
    
    // Animation duration
    await Future.delayed(const Duration(milliseconds: 200));
    
    _isAnimating = false;
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _isAnimating = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 30));
      
      _themeMode = mode;
      await _saveTheme();
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      _isAnimating = false;
      notifyListeners();
    }
  }

  // Check if current theme is dark
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}
