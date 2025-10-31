import 'package:flutter/material.dart';

/// Utility class for showing consistent snackbars across the app
class SnackbarUtils {
  /// Show a snackbar with a message
  /// 
  /// [context] - BuildContext to show the snackbar in
  /// [message] - Message to display
  /// [isError] - Whether this is an error message (red) or success message (green)
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

