import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A notifier class that manages theme state and persistence
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  bool _isLoaded = false;
  String? _error;

  ThemeMode get mode => _mode;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  ThemeNotifier() {
    _initialize();
  }

  /// Initialize theme mode from persistent storage
  Future<void> _initialize() async {
    try {
      // Ensure bindings are ready before scheduling UI updates
      WidgetsFlutterBinding.ensureInitialized();

      final prefs = await SharedPreferences.getInstance();

      // Get the stored theme mode
      final v = prefs.getString(_key);
      _setModeFromString(v);

      _isLoaded = true;
      _error = null;

      // Schedule notifyListeners AFTER the first frame
      // to avoid `_dirty` error during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } catch (e) {
      debugPrint('ThemeNotifier load error: $e');
      _error = e.toString();
      // Fallback to system theme on error
      _mode = ThemeMode.system;
      _isLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  void _setModeFromString(String? value) {
    switch (value) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
    }
  }

  /// Set the theme mode and persist the change
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        mode == ThemeMode.light
            ? 'light'
            : mode == ThemeMode.dark
            ? 'dark'
            : 'system',
      );

      _mode = mode;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeNotifier save error: $e');
      _error = e.toString();
      // Don't update mode if save fails
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode.
  /// If current mode is system, defaults to light mode first.
  Future<void> toggle() async {
    final next = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  /// Reset to system theme mode
  Future<void> resetToSystem() async {
    await setMode(ThemeMode.system);
  }
}
