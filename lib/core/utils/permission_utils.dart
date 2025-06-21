import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_channel.dart';

enum AppPermission {
  overlay,
  accessibility,
}

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
  
  static Future<void> openOverlaySettings() async {
    if (Platform.isAndroid) {
      // Direct way to open "Display over other apps" settings
      await PlatformChannel.openOverlayPermissionSettings();
    } else if (Platform.isIOS) {
      await openAppSettings();
    }
  }
  
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
  
  static Future<void> setPermissionGranted(AppPermission permission, bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    switch (permission) {
      case AppPermission.overlay:
        await prefs.setBool('overlay_granted', granted);
        break;
      case AppPermission.accessibility:
        await prefs.setBool('accessibility_granted', granted);
        break;
    }
  }
  
  static Future<bool> checkPermissionGranted(AppPermission permission) async {
    final prefs = await SharedPreferences.getInstance();
    switch (permission) {
      case AppPermission.overlay:
        return prefs.getBool('overlay_granted') ?? false;
      case AppPermission.accessibility:
        return prefs.getBool('accessibility_granted') ?? false;
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