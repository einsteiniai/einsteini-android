import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'platform_channel.dart';

class PermissionUtils {
  static Future<bool> checkOverlayPermission() async {
    if (Platform.isAndroid) {
      return await Permission.systemAlertWindow.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't have the same concept of overlay permissions
      // but we can check for notifications as a proxy
      return await Permission.notification.isGranted;
    }
    return false;
  }
  
  static Future<bool> requestOverlayPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.systemAlertWindow.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }
  
  static Future<void> openOverlaySettings(BuildContext context) async {
    if (Platform.isAndroid) {
      // Use MethodChannel to launch native OverlayPermissionActivity
      await PlatformChannel.openOverlayPermissionActivity();
    } else if (Platform.isIOS) {
      await openAppSettings();
    }
  }
  
  // Show a dialog explaining how to enable the overlay permission if the settings don't open directly
  static void showOverlayPermissionInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Display Over Other Apps'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If settings don\'t open automatically, please follow these steps:'),
            SizedBox(height: 8),
            Text('1. Open your device Settings'),
            Text('2. Go to Apps or Application Manager'),
            Text('3. Find and tap on einsteini.ai'),
            Text('4. Tap on "Display over other apps"'),
            Text('5. Enable the permission for einsteini.ai'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  
  /*
  static Future<bool> checkAccessibilityPermission() async {
    // This is more complex and platform-specific
    // Usually requires the user to manually enable in settings
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('accessibility_granted') ?? false;
  }
  
  static Future<void> openAccessibilitySettings() async {
    // Open accessibility settings directly on the device
    if (Platform.isAndroid) {
      // This opens the specific Accessibility settings page
      await PlatformChannel.openAccessibilitySettings();
    } else {
      // For iOS
      await openAppSettings();
    }
  }
  
  // Show a dialog explaining the accessibility permission similar to Grammarly
  static void showAccessibilityPermissionExplanation(BuildContext context, {
    required VoidCallback onAgree,
    required VoidCallback onDisagree,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'einsteini.ai - LinkedIn Assistant',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'einsteini.ai uses the Android Accessibility service to process LinkedIn content and provide you with AI-powered writing suggestions. To provide you with an optimized product, we also access some additional information, such as the type of content you\'re viewing. We don\'t and will not sell your data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'einsteini.ai uses the following Accessibility capabilities:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Retrieve LinkedIn content:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'This is required for einsteini.ai to provide intelligent content suggestions for LinkedIn posts and comments.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Detect window changed:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'This is required to turn einsteini.ai on or off when you\'re browsing different sections of LinkedIn.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Enabling the shortcut toggle on this screen is NOT required.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDisagree,
                    child: Text(
                      'Disagree',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: onAgree,
                    child: Text(
                      'Agree',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
  
  static Future<void> setPermissionGranted(AppPermission permission, bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    switch (permission) {
      case AppPermission.overlay:
        await prefs.setBool('overlay_granted', granted);
        break;
      case AppPermission.location:
        await prefs.setBool('location_granted', granted);
        break;
      case AppPermission.accessibility:
        await prefs.setBool('accessibility_granted', granted);
        break;
    }
  }
  
  static Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }
  
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  static Future<void> openLocationSettings() async {
    await openAppSettings();
  }
  
  static Future<void> openAccessibilitySettings() async {
    await openAppSettings();
  }
  
  static Future<bool> checkPermissionGranted(AppPermission permission) async {
    switch (permission) {
      case AppPermission.overlay:
        return await checkOverlayPermission();
      case AppPermission.location:
        return await checkLocationPermission();
      case AppPermission.accessibility:
        return false; // Can't check accessibility permission programmatically
    }
  }
  
  static Future<bool> requestPermission(BuildContext context, AppPermission permission) async {
    switch (permission) {
      case AppPermission.overlay:
        final isGranted = await requestOverlayPermission();
        if (!isGranted) {
          await openOverlaySettings(context);
          showOverlayPermissionInstructions(context);
          return false;
        }
        return true;
        
      case AppPermission.location:
        final isGranted = await requestLocationPermission();
        if (!isGranted) {
          await openLocationSettings();
          return false;
        }
        return true;
        
      case AppPermission.accessibility:
        await openAccessibilitySettings();
        return false; // We can't programmatically determine if accessibility was granted
    }
  }
  
  static Future<bool> toggleOverlay(bool enable) async {
    try {
      if (enable) {
        // Start the overlay service
        await PlatformChannel.showOverlay();
      } else {
        // Stop the overlay service
        await PlatformChannel.hideOverlay();
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling overlay: $e');
      return false;
    }
  }
  
  static void showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Function onActionPressed,
    required String actionText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onActionPressed();
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}