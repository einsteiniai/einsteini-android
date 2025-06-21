import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Utility class for showing toast messages
class ToastUtils {
  /// Shows a toast message with customizable options
  static void showToast(
    String message, {
    Toast? length,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    int? timeInSecForIosWeb,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length ?? Toast.LENGTH_SHORT,
      gravity: gravity ?? ToastGravity.BOTTOM,
      timeInSecForIosWeb: timeInSecForIosWeb ?? 1,
      backgroundColor: backgroundColor ?? Colors.black,
      textColor: textColor ?? Colors.white,
      fontSize: fontSize ?? 16.0,
    );
  }
  
  /// Shows a long toast message
  static void showLongToast(String message) {
    showToast(
      message,
      length: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 3,
    );
  }
  
  /// Shows a toast with a custom background color
  static void showColoredToast(String message, Color backgroundColor) {
    showToast(
      message,
      backgroundColor: backgroundColor,
    );
  }
  
  /// Shows a success toast message with green background
  static void showSuccessToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.green[700],
    );
  }
  
  /// Shows an error toast message with red background
  static void showErrorToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.red[700],
      length: Toast.LENGTH_LONG,
    );
  }
  
  /// Shows an info toast message with blue background
  static void showInfoToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.blue[700],
    );
  }
} 