import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/overlay_permission_screen.dart';
import '../../features/onboarding/screens/accessibility_permission_screen.dart';
import '../../features/onboarding/screens/theme_selection_screen.dart';
import '../../features/onboarding/screens/auth_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/profile_screen.dart';
import '../../features/home/screens/settings_screen.dart';
import '../constants/app_constants.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRoutes {
  static const String welcome = '/welcome';
  static const String accessibilityPermission = '/accessibility-permission';
  static const String overlayPermission = '/overlay-permission';
  static const String themeSelection = '/theme-selection';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        redirect: _checkOnboardingStatus,
      ),
      GoRoute(
        path: AppRoutes.accessibilityPermission,
        builder: (context, state) => const AccessibilityPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.overlayPermission,
        builder: (context, state) => const OverlayPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.themeSelection,
        builder: (context, state) => const ThemeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainAppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'chat',
                builder: (context, state) => const ChatScreen(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      // During development, disable redirection for easier testing
      // return null;
      
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;
      final isLoggedIn = prefs.getBool(AppConstants.userLoggedInKey) ?? false;
      
      // Get permissions state
      final overlayPermissionGranted = prefs.getBool('overlay_permission_granted') ?? false;
      final accessibilityPermissionGranted = prefs.getBool('accessibility_permission_granted') ?? false;
      
      // Handle splash screen
      if (state.matchedLocation == '/splash') {
        await Future.delayed(const Duration(seconds: 1));
        if (!hasCompletedOnboarding) {
          // Start onboarding flow from welcome
          return AppRoutes.welcome;
        } else if (!isLoggedIn) {
          return AppRoutes.auth;
        } else {
          return AppRoutes.home;
        }
      }
      
      // Allow unrestricted navigation through the onboarding flow
      final onboardingPaths = [
        AppRoutes.welcome, 
        AppRoutes.overlayPermission, 
        AppRoutes.accessibilityPermission, 
        AppRoutes.themeSelection
      ];
      
      // If we're in the onboarding flow, allow normal progression
      if (onboardingPaths.contains(state.matchedLocation)) {
        return null;
      }
      
      // If onboarding isn't complete and user is trying to access a protected route
      if (!hasCompletedOnboarding && 
          !onboardingPaths.contains(state.matchedLocation) &&
          state.matchedLocation != AppRoutes.auth) {
        // If overlay permission isn't granted, go there first
        if (!overlayPermissionGranted) {
          return AppRoutes.overlayPermission;
        } 
        // If accessibility permission isn't granted, go there next
        else if (!accessibilityPermissionGranted) {
          return AppRoutes.accessibilityPermission;
        } 
        // Otherwise proceed to theme selection
        else {
          return AppRoutes.themeSelection;
        }
      }
      
      // If user is not logged in and trying to access a protected route
      if (!isLoggedIn && 
          state.matchedLocation != AppRoutes.auth && 
          !onboardingPaths.contains(state.matchedLocation)) {
        return AppRoutes.auth;
      }
      
      // If user is logged in and tries to access auth or onboarding
      if (isLoggedIn && 
          (state.matchedLocation == AppRoutes.auth || 
           onboardingPaths.contains(state.matchedLocation))) {
        return AppRoutes.home;
      }
      
      return null;
    },
  );
}

Future<String?> _checkOnboardingStatus(BuildContext context, GoRouterState state) async {
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;
  final isLoggedIn = prefs.getBool(AppConstants.userLoggedInKey) ?? false;
  
  // Skip onboarding if completed
  if (state.matchedLocation == AppRoutes.welcome && hasCompletedOnboarding) {
    return isLoggedIn ? AppRoutes.home : AppRoutes.auth;
  }
  
  return null;
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'einsteini.ai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class MainAppScaffold extends ConsumerWidget {
  final Widget child;

  const MainAppScaffold({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'einsteini.ai',
          style: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Open drawer
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('${AppRoutes.home}/profile');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'einsteini.ai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your LinkedIn AI companion',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              context.go(AppRoutes.home);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            onTap: () {
              context.go('${AppRoutes.home}/chat');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              context.go('${AppRoutes.home}/settings');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Handle logout
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(AppConstants.userLoggedInKey, false);
              if (context.mounted) {
                context.go(AppRoutes.auth);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chat Screen'),
    );
  }
} 