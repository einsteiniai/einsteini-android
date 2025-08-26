import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFFBD79FF);
  static const Color _primaryDarkColor = Color(0xFFBD79FF);
  
  static const Color _lightBackgroundColor = Colors.white;
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightTextColor = Color(0xFF1A1D24);
  static const Color _lightSecondaryTextColor = Color(0xFF6C727F);
  
  static const Color _darkBackgroundColor = Color(0xFF121827);
  static const Color _darkSurfaceColor = Color(0xFF1A2235);
  static const Color _darkTextColor = Colors.white;
  static const Color _darkSecondaryTextColor = Color(0xFFB4B7BD);
  
  
  // Font families
  static const String _primaryFontFamily = 'TikTokSans';
  static const String _secondaryFontFamily = 'DMSans';
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _primaryColor.withOpacity(0.8),
      onSecondary: Colors.white,
      surface: _lightSurfaceColor,
      onSurface: _lightTextColor,
      error: Colors.red,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    fontFamily: _secondaryFontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackgroundColor,
      foregroundColor: _lightTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _lightTextColor,
        fontFamily: _primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _lightTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: _lightTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      headlineSmall: TextStyle(
        color: _lightTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleLarge: TextStyle(
        color: _lightTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: _lightTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: _lightTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(
        color: _lightTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: _lightTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: _lightSecondaryTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _primaryColor.withOpacity(0.5);
          }
          return _primaryColor;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        iconColor: WidgetStateProperty.all(Colors.white),
        textStyle: WidgetStateProperty.all(const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: _primaryFontFamily,
        )),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: BorderSide(color: _primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _lightSurfaceColor,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
      thickness: 1,
      space: 24,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: Color(0x1ABD79FF),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: _secondaryFontFamily,
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _primaryDarkColor,
      onPrimary: Colors.white,
      secondary: _primaryDarkColor.withOpacity(0.8),
      onSecondary: Colors.white,
      surface: _darkSurfaceColor,
      onSurface: _darkTextColor,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    fontFamily: _secondaryFontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackgroundColor,
      foregroundColor: _darkTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _darkTextColor,
        fontFamily: _primaryFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _darkTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: _darkTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      headlineSmall: TextStyle(
        color: _darkTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      titleLarge: TextStyle(
        color: _darkTextColor,
        fontFamily: _primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        color: _darkTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: _darkTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(
        color: _darkTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: _darkTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: _darkSecondaryTextColor,
        fontFamily: _secondaryFontFamily,
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return _primaryDarkColor.withOpacity(0.5);
          }
          return _primaryDarkColor;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        iconColor: WidgetStateProperty.all(Colors.white),
        textStyle: WidgetStateProperty.all(const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: _primaryFontFamily,
        )),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryDarkColor,
        side: BorderSide(color: _primaryDarkColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryDarkColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryDarkColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _darkSurfaceColor,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D3748),
      thickness: 1,
      space: 24,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _primaryDarkColor.withOpacity(0.2),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: _secondaryFontFamily,
        ),
      ),
    ),
  );
} 