import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const _key = 'theme_mode';

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);

    if (value == 'light') themeMode.value = ThemeMode.light;
    if (value == 'dark') themeMode.value = ThemeMode.dark;
    if (value == 'system') themeMode.value = ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = mode;

    if (mode == ThemeMode.light) prefs.setString(_key, 'light');
    if (mode == ThemeMode.dark) prefs.setString(_key, 'dark');
    if (mode == ThemeMode.system) prefs.setString(_key, 'system');
  }
}
