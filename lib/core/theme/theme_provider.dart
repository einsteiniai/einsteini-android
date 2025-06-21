import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _themePreferenceKey = 'theme_preference';
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePreferenceKey);
    
    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (element) => element.name == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }
  
  Future<void> setTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeMode.name);
    state = themeMode;
  }

  ThemeData getTheme(BuildContext context) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    
    switch (state) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        return platformBrightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
}); 