/// Application general constants
class AppConstants {
  // App Info
  static const String appName = 'einsteini.ai';
  static const String appDescription = 'LinkedIn engagement assistant powered by AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Effortlessly human.';
  
  // Routes
  static const String onboardingRoute = '/onboarding';
  static const String permissionsRoute = '/permissions';
  static const String themeSelectionRoute = '/theme-selection';
  static const String authRoute = '/auth';
  static const String homeRoute = '/home';
  static const String chatRoute = '/chat';
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/profile';
  
  // Shared Preferences Keys
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String permissionsGrantedKey = 'permissions_granted';
  static const String userLoggedInKey = 'user_logged_in';
  static const String userIdKey = 'user_id';
  static const String userTokenKey = 'user_token';
  static const String userProfileKey = 'user_profile';
  static const String themePreferenceKey = 'theme_preference';
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding';
  
  // API Constants
  static const String apiBaseUrl = 'https://api.einsteini.ai';
  static const int apiTimeoutSeconds = 30;
  
  // Feature Flags
  static const bool enableVoiceInput = true;
  static const bool enableNotifications = true;
  static const bool enableBiometricAuth = true;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // Error Messages
  static const String defaultErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  
  // Terms and Conditions
  static const String termsUrl = 'https://einsteini.ai/terms';
  static const String privacyUrl = 'https://einsteini.ai/privacy';
  static const String termsText = 'By continuing, you agree to our Terms of Service and Privacy Policy.';
  
  // Platform channel names
  static const String platformChannelName = 'com.example.einsteiniapp/platform';
  static const String accessibilityServiceMethod = 'checkAccessibilityService';
  static const String overlayPermissionMethod = 'checkOverlayPermission';
  static const String requestOverlayPermissionMethod = 'requestOverlayPermission';
  
  // Routes
  static const String welcomeRoute = '/welcome';
  static const String accessibilityPermissionRoute = '/accessibility-permission';
  static const String overlayPermissionRoute = '/overlay-permission';
}

/// Application routes for navigation
class AppRoutes {
  // Onboarding flow
  static const String welcome = '/welcome';
  static const String overlayPermission = '/overlay-permission';
  static const String accessibilityPermission = '/accessibility-permission';
  static const String themeSelection = '/theme-selection';
  
  // Authentication
  static const String auth = '/auth';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Main app screens
  static const String home = '/home';
  static const String settings = '/settings';
  static const String profile = '/profile';
}

/// Application permission types
enum AppPermission {
  overlay,
  accessibility
} 