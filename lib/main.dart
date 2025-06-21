import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_switcher.dart';
import 'core/services/overlay_service.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style based on theme
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  runApp(
    const ProviderScope(
      child: EinsteinApp(),
    ),
  );
}

class EinsteinApp extends ConsumerWidget {
  const EinsteinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    final themeMode = ref.watch(themeProvider);
    
    // Update system UI overlay style based on theme
    _updateSystemUIOverlayStyle(themeMode, context);
    
    // Update overlay service theme when theme changes
    _updateOverlayTheme(themeMode, context);
    
    return ThemeSwitcher(
      child: MaterialApp.router(
        title: 'einsteini.ai - Effortlessly human.',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
  
  void _updateSystemUIOverlayStyle(ThemeMode themeMode, BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDarkMode ? const Color(0xFF121827) : Colors.white,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }

  void _updateOverlayTheme(ThemeMode themeMode, BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && brightness == Brightness.dark);
    
    // Update the overlay service theme if it's running
    // This is done asynchronously to avoid blocking the UI
    Future.microtask(() async {
      final overlayService = OverlayService();
      await overlayService.updateOverlayTheme(isDarkMode);
    });
  }
}
