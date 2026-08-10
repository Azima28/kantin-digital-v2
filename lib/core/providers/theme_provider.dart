import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'kantin_digital_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  static bool isDark = true;

  @override
  ThemeMode build() {
    // Default to dark; load persisted value asynchronously.
    _loadFromPrefs();
    return ThemeMode.dark;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == 'light') {
      state = ThemeMode.light;
      isDark = false;
    } else {
      state = ThemeMode.dark;
      isDark = true;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    isDark = mode == ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  void toggle() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
