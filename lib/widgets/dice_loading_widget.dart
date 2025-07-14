import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework

class DiceLoadingWidget extends StatelessWidget { // Define DiceLoadingWidget as a stateless widget for displaying dice loading animation
  final String? message; // Declare optional message field to display with the loading animation
  final double size; // Declare size field to control the size of the dice animation
  final Color? backgroundColor; // Declare optional background color field
  final bool showMessage; // Declare boolean field to control whether to show the message

  const DiceLoadingWidget({ // Constructor for DiceLoadingWidget with optional parameters
    super.key, // Pass key to parent StatelessWidget
    this.message, // Initialize optional message parameter
    this.size = 80.0, // Initialize size parameter with default value of 80.0
    this.backgroundColor, // Initialize optional backgroundColor parameter
    this.showMessage = true, // Initialize showMessage parameter with default value of true
  }); // End of constructor

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the dice loading widget
    return Container( // Return a Container widget to wrap the loading content
      color: backgroundColor ?? Colors.transparent, // Set background color to provided color or transparent
      child: Center( // Center the loading content
        child: Column( // Create a column to arrange loading elements vertically
          mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically
          children: [ // Define children widgets for the column
            // Dice rolling GIF
            Image.asset( // Display the dice rolling GIF image
              'assets/dice-roll-dice.gif', // Set the path to the dice rolling GIF asset
              width: size, // Set the width to the specified size
              height: size, // Set the height to the specified size
              fit: BoxFit.contain, // Set the fit to contain the image within bounds
            ), // End of Image.asset
            
            if (showMessage && message != null) ...[ // Conditionally add message widgets if showMessage is true and message is not null
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              Text( // Display the message text
                message!, // Set the text to the provided message (non-null assertion)
                style: const TextStyle( // Define text style for the message
                  color: Colors.white, // Set text color to white
                  fontSize: 16, // Set font size to 16 pixels
                  fontWeight: FontWeight.w500, // Set font weight to medium
                ), // End of TextStyle
                textAlign: TextAlign.center, // Center align the text
              ), // End of Text widget
            ], // End of conditional message widgets
          ], // End of column children
        ), // End of column widget
      ), // End of center widget
    ); // End of container widget
  } // End of build method
} // End of DiceLoadingWidget class

// Fullscreen loading overlay
class DiceLoadingOverlay extends StatelessWidget { // Define DiceLoadingOverlay as a stateless widget for fullscreen loading
  final String? message; // Declare optional message field to display with the loading overlay
  final bool isVisible; // Declare boolean field to control overlay visibility

  const DiceLoadingOverlay({ // Constructor for DiceLoadingOverlay with optional parameters
    super.key, // Pass key to parent StatelessWidget
    this.message, // Initialize optional message parameter
    required this.isVisible, // Initialize required isVisible parameter
  }); // End of constructor

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the loading overlay
    if (!isVisible) return const SizedBox.shrink(); // Return an empty widget if overlay is not visible

    return Positioned.fill( // Return a Positioned widget that fills the entire screen
      child: Container( // Create a Container for the overlay background
        color: Colors.black.withOpacity(0.7), // Set background color to semi-transparent black
        child: DiceLoadingWidget( // Display the DiceLoadingWidget inside the overlay
          message: message, // Pass the message to the dice loading widget
          size: 100.0, // Set the size to 100.0 pixels
        ), // End of DiceLoadingWidget
      ), // End of Container
    ); // End of Positioned.fill
  } // End of build method
} // End of DiceLoadingOverlay class

// Small inline dice loader
class DiceLoadingSmall extends StatelessWidget { // Define DiceLoadingSmall as a stateless widget for small dice loading animation
  final double size; // Declare size field to control the size of the small dice animation

  const DiceLoadingSmall({ // Constructor for DiceLoadingSmall with optional parameters
    super.key, // Pass key to parent StatelessWidget
    this.size = 24.0, // Initialize size parameter with default value of 24.0
  }); // End of constructor

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the small dice loading widget
    return Image.asset( // Return an Image widget displaying the dice rolling GIF
      'assets/dice-roll-dice.gif', // Set the path to the dice rolling GIF asset
      width: size, // Set the width to the specified size
      height: size, // Set the height to the specified size
      fit: BoxFit.contain, // Set the fit to contain the image within bounds
    ); // End of Image.asset
  } // End of build method
} // End of DiceLoadingSmall class

// Loading dialog with dice animation
class DiceLoadingDialog extends StatelessWidget { // Define DiceLoadingDialog as a stateless widget for modal loading dialog
  final String? message; // Declare optional message field to display with the loading dialog

  const DiceLoadingDialog({ // Constructor for DiceLoadingDialog with optional parameters
    super.key, // Pass key to parent StatelessWidget
    this.message, // Initialize optional message parameter
  }); // End of constructor

  static void show(BuildContext context, {String? message}) { // Define static method to show the dice loading dialog
    showDialog( // Show a modal dialog
      context: context, // Set the context for the dialog
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder: (context) => DiceLoadingDialog(message: message), // Build the DiceLoadingDialog with the provided message
    ); // End of showDialog
  } // End of show method

  static void hide(BuildContext context) { // Define static method to hide the dice loading dialog
    Navigator.of(context).pop(); // Pop the current dialog from the navigation stack
  } // End of hide method

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the loading dialog
    return Dialog( // Return a Dialog widget
      backgroundColor: Colors.transparent, // Set dialog background to transparent
      child: Container( // Create a Container for the dialog content
        padding: const EdgeInsets.all(32), // Set padding to 32 pixels on all sides
        decoration: BoxDecoration( // Define decoration for the container
          color: Colors.grey[900], // Set background color to dark gray
          borderRadius: BorderRadius.circular(16), // Set border radius to 16 pixels
        ), // End of BoxDecoration
        child: DiceLoadingWidget( // Display the DiceLoadingWidget inside the dialog
          message: message ?? 'Loading...', // Set message to provided message or default "Loading..."
          size: 80.0, // Set the size to 80.0 pixels
          showMessage: true, // Set showMessage to true to display the message
        ), // End of DiceLoadingWidget
      ), // End of Container
    ); // End of Dialog
  } // End of build method
} // End of DiceLoadingDialog class
