import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Service to manage the floating overlay window
class OverlayService {
  static const MethodChannel _channel = MethodChannel('com.einsteini.ai/overlay');
  static final OverlayService _instance = OverlayService._internal();

  // Stream controllers for overlay events
  final StreamController<bool> _overlayExpandedController = StreamController<bool>.broadcast();
  final StreamController<bool> _overlayCollapsedController = StreamController<bool>.broadcast();

  /// Singleton instance
  factory OverlayService() {
    return _instance;
  }

  OverlayService._internal() {
    // Setup method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Stream to listen for overlay expanded events
  Stream<bool> get onOverlayExpanded => _overlayExpandedController.stream;

  /// Stream to listen for overlay collapsed events
  Stream<bool> get onOverlayCollapsed => _overlayCollapsedController.stream;

  /// Handle method calls from the native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayExpanded':
        _overlayExpandedController.add(true);
        break;
      case 'onOverlayCollapsed':
        _overlayCollapsedController.add(true);
        break;
    }
    return null;
  }

  /// Start the overlay service
  ///
  /// Returns true if the service was started successfully
  Future<bool> startOverlayService() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod('startOverlayService') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to start overlay service: ${e.message}');
      return false;
    }
  }
  
  /// Update the theme of the overlay
  Future<bool> updateOverlayTheme(bool isDarkTheme) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod('updateOverlayTheme') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to update overlay theme: ${e.message}');
      return false;
    }
  }

  /// Stop the overlay service
  ///
  /// Returns true if the service was stopped successfully
  Future<bool> stopOverlayService() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod('stopOverlayService') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop overlay service: ${e.message}');
      return false;
    }
  }

  /// Check if the overlay service is running
  ///
  /// Returns true if the service is running
  Future<bool> isOverlayServiceRunning() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod('isOverlayServiceRunning') ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check if overlay service is running: ${e.message}');
      return false;
    }
  }

  /// Resize the expanded overlay view
  ///
  /// [width] and [height] must be greater than 0
  /// Returns true if the resize was successful
  Future<bool> resizeExpandedView(int width, int height) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod('resizeExpandedView', {
        'width': width,
        'height': height,
      }) ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to resize expanded view: ${e.message}');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _overlayExpandedController.close();
    _overlayCollapsedController.close();
  }
} 