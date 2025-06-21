import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class to handle platform-specific operations
class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.einsteini.ai/settings');
  static const MethodChannel _scraperChannel = MethodChannel('com.einsteini.ai/scraper');

  /// Opens specific system settings pages on Android
  static Future<void> openSystemSettings(String action) async {
    try {
      await _channel.invokeMethod('openSystemSettings', {'action': action});
    } on PlatformException catch (e) {
      print('Failed to open system settings: ${e.message}');
      rethrow;
    }
  }

  /// Opens specific settings pages using Android intent actions
  static Future<void> openOverlayPermissionSettings() async {
    if (Platform.isAndroid) {
      await openSystemSettings('android.settings.MANAGE_OVERLAY_PERMISSION');
    }
  }

  /// Opens accessibility settings directly
  static Future<void> openAccessibilitySettings() async {
    if (Platform.isAndroid) {
      await openSystemSettings('android.settings.ACCESSIBILITY_SETTINGS');
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool isGranted = await _channel.invokeMethod('checkOverlayPermission');
      return isGranted;
    } on PlatformException catch (e) {
      print('Failed to check overlay permission: ${e.message}');
      return false;
    }
  }

  /// Check if accessibility permission is granted
  static Future<bool> checkAccessibilityPermission() async {
    try {
      final bool isGranted = await _channel.invokeMethod('checkAccessibilityPermission');
      return isGranted;
    } on PlatformException catch (e) {
      print('Failed to check accessibility permission: ${e.message}');
      return false;
    }
  }
  
  /// Scrape a LinkedIn post using JSoup on Android
  static Future<Map<String, dynamic>> scrapeLinkedInPost(String url) async {
    if (!Platform.isAndroid) {
      return {
        'content': 'LinkedIn scraping is only supported on Android devices',
        'author': 'System',
        'date': 'Now',
        'likes': 0,
        'comments': 0,
        'images': <String>[],
        'commentsList': <Map<String, String>>[]
      };
    }
    
    try {
      final result = await _scraperChannel.invokeMethod('scrapeLinkedInPost', {'url': url});
      
      // Process the comments list
      List<Map<String, String>> commentsList = [];
      if (result['commentsList'] != null) {
        final rawComments = result['commentsList'] as List<dynamic>;
        commentsList = rawComments.map((comment) {
          return {
            'author': comment['author'] as String? ?? 'Unknown',
            'text': comment['text'] as String? ?? ''
          };
        }).toList();
      }
      
      // Convert the result to the expected format
      return {
        'content': result['content'] ?? 'No content found',
        'author': result['author'] ?? 'Unknown author',
        'date': result['date'] ?? 'Unknown date',
        'likes': result['likes'] ?? 0,
        'comments': result['comments'] ?? 0,
        'images': (result['images'] as List<dynamic>?)?.cast<String>() ?? <String>[],
        'commentsList': commentsList
      };
    } on PlatformException catch (e) {
      print('Failed to scrape LinkedIn post: ${e.message}');
      return {
        'content': 'Failed to scrape LinkedIn post: ${e.message}',
        'author': 'Error',
        'date': 'Now',
        'likes': 0,
        'comments': 0,
        'images': <String>[],
        'commentsList': <Map<String, String>>[]
      };
    }
  }
} 