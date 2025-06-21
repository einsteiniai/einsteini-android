import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';
import 'app_theme.dart';

class ThemeSwitcher extends ConsumerStatefulWidget {
  final Widget child;
  
  const ThemeSwitcher({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends ConsumerState<ThemeSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ThemeData _newTheme;
  late ThemeData _oldTheme;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    // Initialize themes
    final themeMode = ref.read(themeProvider);
    _newTheme = _getThemeData(themeMode);
    _oldTheme = _newTheme;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  ThemeData _getThemeData(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final newTheme = _getThemeData(themeMode);
    
    // If the theme has changed, start the animation
    if (_newTheme != newTheme) {
      _oldTheme = _newTheme;
      _newTheme = newTheme;
      _controller.reset();
      _controller.forward();
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Theme(
          data: ThemeData.lerp(_oldTheme, _newTheme, _animation.value),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
} 