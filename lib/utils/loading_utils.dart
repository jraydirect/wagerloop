import 'package:flutter/material.dart';
import '../widgets/dice_loading_widget.dart';

/// Utility class for showing loading states with dice animation
class LoadingUtils {
  /// Show a loading dialog with dice animation
  static void showLoading(BuildContext context, {String? message}) {
    DiceLoadingDialog.show(context, message: message);
  }

  /// Hide the loading dialog
  static void hideLoading(BuildContext context) {
    DiceLoadingDialog.hide(context);
  }

  /// Show loading overlay on top of current screen
  static Widget buildLoadingOverlay({
    required bool isLoading,
    String? message,
    required Widget child,
  }) {
    return Stack(
      children: [
        child,
        DiceLoadingOverlay(
          isVisible: isLoading,
          message: message,
        ),
      ],
    );
  }

  /// Get a small dice loading widget for buttons
  static Widget getButtonLoader({double size = 20}) {
    return DiceLoadingSmall(size: size);
  }

  /// Get a full screen loading widget
  static Widget getFullScreenLoader({String? message}) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DiceLoadingWidget(
        message: message ?? 'Loading...',
        size: 100,
      ),
    );
  }

  /// Show loading snackbar with dice animation
  static void showLoadingSnackBar(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const DiceLoadingSmall(size: 20),
            const SizedBox(width: 12),
            Text(message ?? 'Loading...'),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Extension methods for easy loading state management
extension LoadingContext on BuildContext {
  void showDiceLoading({String? message}) {
    LoadingUtils.showLoading(this, message: message);
  }

  void hideDiceLoading() {
    LoadingUtils.hideLoading(this);
  }

  void showDiceLoadingSnackBar({String? message}) {
    LoadingUtils.showLoadingSnackBar(this, message: message);
  }
}
