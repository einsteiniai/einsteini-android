import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/overlay_service.dart';
import 'app_theme.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _themePreferenceKey = 'theme_preference';
  final OverlayService _overlayService = OverlayService();
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePreferenceKey);
    
    if (themeString != null) {
      state = ThemeMode.values.firstWhere(
        (element) => element.name == themeString,
        orElse: () => ThemeMode.system,
      );
      
      // Ensure overlay service is synced with app theme on load
      _updateOverlayTheme(state);
    }
  }
  
  // Update the overlay service with the current theme
  Future<void> _updateOverlayTheme(ThemeMode themeMode) async {
    await _overlayService.setThemeMode(themeMode);
  }
  
  Future<void> setTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeMode.name);
    state = themeMode;
    
    // Sync overlay service with the new theme
    await _updateOverlayTheme(themeMode);
  }
  
  // Show a dialog confirming theme change and app restart
  Future<bool> showThemeChangeDialog(BuildContext context, ThemeMode newThemeMode) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Theme'),
        content: const Text('Changing the theme will restart the app. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await setTheme(newThemeMode);
      return true;
    }
    return false;
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