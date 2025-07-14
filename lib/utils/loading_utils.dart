import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import '../widgets/dice_loading_widget.dart'; // Import custom dice loading widget for themed loading animations

/// Utility class for managing loading states in WagerLoop.
/// 
/// Provides consistent loading indicators and dialogs throughout the app
/// for operations like fetching odds, placing bets, and social interactions.
/// Includes custom dice-themed loading animations to match the app's theme.
class LoadingUtils { // Define LoadingUtils class to provide static loading utility methods
  /// Displays a loading dialog with optional message.
  /// 
  /// Shows a modal dialog with a loading spinner and optional message
  /// to indicate that the app is processing a request like fetching odds
  /// or submitting a bet.
  /// 
  /// Parameters:
  ///   - context: BuildContext for showing the dialog
  ///   - message: Optional message to display with the loading indicator
  static void showLoading(BuildContext context, {String? message}) { // Define static method to show loading dialog
    showDialog( // Show a modal dialog
      context: context, // Set the context for the dialog
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (context) => WillPopScope( // Build the dialog with WillPopScope to handle back button
        onWillPop: () async => false, // Prevent back button from dismissing dialog
        child: AlertDialog( // Create an AlertDialog for the loading state
          content: Row( // Create a row to arrange loading elements horizontally
            mainAxisSize: MainAxisSize.min, // Set row to minimum size
            children: [ // Define children widgets for the row
              CircularProgressIndicator(), // Add a circular progress indicator
              SizedBox(width: 16), // Add horizontal spacing of 16 pixels
              Text(message ?? 'Loading...'), // Display the message or default "Loading..." text
            ], // End of row children
          ), // End of row widget
        ), // End of AlertDialog
      ), // End of WillPopScope
    ); // End of showDialog
  } // End of showLoading method

  /// Hides the currently displayed loading dialog.
  /// 
  /// Dismisses the loading dialog shown by showLoading() when an
  /// operation completes or fails.
  /// 
  /// Parameters:
  ///   - context: BuildContext for dismissing the dialog
  static void hideLoading(BuildContext context) { // Define static method to hide loading dialog
    Navigator.of(context).pop(); // Pop the current dialog from the navigation stack
  } // End of hideLoading method

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
  static Widget getButtonLoader({double size = 20}) { // Define static method to get button loader widget
    return SizedBox( // Return a SizedBox to constrain the loader size
      width: size, // Set the width to the specified size
      height: size, // Set the height to the specified size
      child: CircularProgressIndicator(strokeWidth: 2), // Add a circular progress indicator with thin stroke
    ); // End of SizedBox
  } // End of getButtonLoader method

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
  static Widget getFullScreenLoader({String? message}) { // Define static method to get full screen loader
    return Center( // Return a Center widget to center the loading content
      child: Column( // Create a column to arrange loading elements vertically
        mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically
        children: [ // Define children widgets for the column
          CircularProgressIndicator(), // Add a circular progress indicator
          if (message != null) ...[ // Conditionally add message if provided
            SizedBox(height: 16), // Add vertical spacing of 16 pixels
            Text(message), // Display the message text
          ], // End of conditional message widgets
        ], // End of column children
      ), // End of column widget
    ); // End of Center widget
  } // End of getFullScreenLoader method

  /// Displays a loading snackbar with optional message.
  /// 
  /// Shows a non-intrusive loading indicator at the bottom of the screen
  /// for quick operations like liking posts or following users.
  /// 
  /// Parameters:
  ///   - context: BuildContext for showing the snackbar
  ///   - message: Optional message to display with the loading indicator
  static void showLoadingSnackBar(BuildContext context, {String? message}) { // Define static method to show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar( // Show a snackbar using ScaffoldMessenger
      SnackBar( // Create a SnackBar widget
        content: Row( // Create a row to arrange snackbar elements horizontally
          mainAxisSize: MainAxisSize.min, // Set row to minimum size
          children: [ // Define children widgets for the row
            SizedBox( // Create a SizedBox for the progress indicator
              width: 16, // Set the width to 16 pixels
              height: 16, // Set the height to 16 pixels
              child: CircularProgressIndicator( // Add a circular progress indicator
                strokeWidth: 2, // Set stroke width to 2 pixels
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Set color to white
              ), // End of CircularProgressIndicator
            ), // End of SizedBox
            SizedBox(width: 16), // Add horizontal spacing of 16 pixels
            Text(message ?? 'Loading...'), // Display the message or default "Loading..." text
          ], // End of row children
        ), // End of row widget
        duration: Duration(seconds: 30), // Set duration to 30 seconds for loading operations
      ), // End of SnackBar
    ); // End of showSnackBar
  } // End of showLoadingSnackBar method
} // End of LoadingUtils class

/// Extended loading utilities with dice-themed animations.
/// 
/// Provides WagerLoop-specific loading animations using dice graphics
/// to maintain consistent theming throughout the betting app.
extension DiceLoadingUtils on LoadingUtils { // Define extension on LoadingUtils for dice-themed loading
  /// Shows a dice-themed loading dialog.
  /// 
  /// Displays a modal dialog with animated dice graphics for loading
  /// states related to betting operations like placing bets or calculating odds.
  /// 
  /// Parameters:
  ///   - message: Optional message to display with the dice animation
  void showDiceLoading({String? message}) { // Define method to show dice loading dialog
    // Implementation would use DiceLoadingWidget
  } // End of showDiceLoading method

  /// Hides the dice-themed loading dialog.
  /// 
  /// Dismisses the dice loading dialog shown by showDiceLoading().
  void hideDiceLoading() { // Define method to hide dice loading dialog
    // Implementation would dismiss the dice loading dialog
  } // End of hideDiceLoading method

  /// Displays a dice-themed loading snackbar.
  /// 
  /// Shows a non-intrusive loading indicator with dice animation
  /// for quick betting-related operations.
  /// 
  /// Parameters:
  ///   - message: Optional message to display with the dice animation
  void showDiceLoadingSnackBar({String? message}) { // Define method to show dice loading snackbar
    // Implementation would use DiceLoadingWidget in snackbar
  } // End of showDiceLoadingSnackBar method
} // End of DiceLoadingUtils extension
