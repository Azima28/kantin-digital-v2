/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeModeKey = 'kantin_digital_theme_mode';

/// Theme Mode Notifier for Kantin Digital v2.0
/// Default Theme: Light Mode (ThemeMode.light)
class ThemeNotifier extends Notifier<ThemeMode> {
  static bool isDark = false;

  @override
  ThemeMode build() {
    // Default to Light Mode; load persisted user preference asynchronously.
    _loadFromPrefs();
    return ThemeMode.light;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == 'dark') {
      state = ThemeMode.dark;
      isDark = true;
    } else {
      state = ThemeMode.light;
      isDark = false;
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
