import 'package:flutter/material.dart';
import '../widgets/dice_loading_widget.dart';

/// Utility class for managing loading states in WagerLoop.
/// 
/// Provides consistent loading indicators and dialogs throughout the app
/// for operations like fetching odds, placing bets, and social interactions.
/// Includes custom dice-themed loading animations to match the app's theme.
class LoadingUtils {
  /// Displays a loading dialog with optional message.
  /// 
  /// Shows a modal dialog with a loading spinner and optional message
  /// to indicate that the app is processing a request like fetching odds
  /// or submitting a bet.
  /// 
  /// Parameters:
  ///   - context: BuildContext for showing the dialog
  ///   - message: Optional message to display with the loading indicator
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  /// Hides the currently displayed loading dialog.
  /// 
  /// Dismisses the loading dialog shown by showLoading() when an
  /// operation completes or fails.
  /// 
  /// Parameters:
  ///   - context: BuildContext for dismissing the dialog
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Returns a standardized loading widget for buttons.
  /// 
  /// Provides a consistent loading spinner for use in buttons during
  /// actions like submitting bets or posting picks.
  /// 
  /// Parameters:
  ///   - size: Size of the loading spinner (default: 20)
  /// 
  /// Returns:
  ///   Widget containing a circular progress indicator
  static Widget getButtonLoader({double size = 20}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  /// Creates a full-screen loading widget with optional message.
  /// 
  /// Used for initial app loading, authentication, or major data fetching
  /// operations that require the entire screen to be in a loading state.
  /// 
  /// Parameters:
  ///   - message: Optional message to display with the loading indicator
  /// 
  /// Returns:
  ///   Widget containing a centered loading indicator and message
  static Widget getFullScreenLoader({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }

  /// Displays a loading snackbar with optional message.
  /// 
  /// Shows a non-intrusive loading indicator at the bottom of the screen
  /// for quick operations like liking posts or following users.
  /// 
  /// Parameters:
  ///   - context: BuildContext for showing the snackbar
  ///   - message: Optional message to display with the loading indicator
  static void showLoadingSnackBar(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
        duration: Duration(seconds: 30), // Long duration for loading
      ),
    );
  }
}

/// Extended loading utilities with dice-themed animations.
/// 
/// Provides WagerLoop-specific loading animations using dice graphics
/// to maintain consistent theming throughout the betting app.
extension DiceLoadingUtils on LoadingUtils {
  /// Shows a dice-themed loading dialog.
  /// 
  /// Displays a modal dialog with animated dice graphics for loading
  /// states related to betting operations like placing bets or calculating odds.
  /// 
  /// Parameters:
  ///   - message: Optional message to display with the dice animation
  void showDiceLoading({String? message}) {
    // Implementation would use DiceLoadingWidget
  }

  /// Hides the dice-themed loading dialog.
  /// 
  /// Dismisses the dice loading dialog shown by showDiceLoading().
  void hideDiceLoading() {
    // Implementation would dismiss the dice loading dialog
  }

  /// Displays a dice-themed loading snackbar.
  /// 
  /// Shows a non-intrusive loading indicator with dice animation
  /// for quick betting-related operations.
  /// 
  /// Parameters:
  ///   - message: Optional message to display with the dice animation
  void showDiceLoadingSnackBar({String? message}) {
    // Implementation would use DiceLoadingWidget in snackbar
  }
}
