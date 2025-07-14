// Example usage of Dice Loading Animations in WagerLoop
// This file demonstrates all the different ways to use the dice loading animations

import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import '../widgets/dice_loading_widget.dart'; // Import custom dice loading widget components
import '../utils/loading_utils.dart'; // Import loading utility functions

class LoadingExamplesPage extends StatefulWidget { // Define LoadingExamplesPage as a stateful widget to demonstrate loading patterns
  const LoadingExamplesPage({super.key}); // Constructor for LoadingExamplesPage with optional key parameter

  @override // Override the createState method from StatefulWidget
  State<LoadingExamplesPage> createState() => _LoadingExamplesPageState(); // Return the state object for this widget
} // End of LoadingExamplesPage class

class _LoadingExamplesPageState extends State<LoadingExamplesPage> { // Define the state class for LoadingExamplesPage widget
  bool _isLoading = false; // Boolean flag to track button loading state
  bool _showOverlay = false; // Boolean flag to track overlay loading state

  @override // Override the build method from State class
  Widget build(BuildContext context) { // Build method that returns the widget tree for the examples page
    return Scaffold( // Return a Scaffold widget that provides the basic page structure
      backgroundColor: Colors.black, // Set the background color to black
      appBar: AppBar( // Create an app bar for the page
        title: const Text('Dice Loading Examples'), // Set the title text for the app bar
        backgroundColor: Colors.black, // Set the app bar background color to black
      ), // End of AppBar
      body: LoadingUtils.buildLoadingOverlay( // Use LoadingUtils to build a loading overlay wrapper
        isLoading: _showOverlay, // Pass the overlay loading state
        message: 'Processing your request...', // Set the loading message
        child: SingleChildScrollView( // Create a scrollable view for the page content
          padding: const EdgeInsets.all(16), // Add padding of 16 pixels on all sides
          child: Column( // Create a column layout for the examples
            crossAxisAlignment: CrossAxisAlignment.start, // Align column children to the start (left)
            children: [ // List of widgets to display in the column
              const Text( // Display a section header for button loading states
                'Button Loading States', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 1: Button with dice loading
              ElevatedButton( // Create an elevated button to demonstrate button loading
                onPressed: _isLoading ? null : () => _simulateButtonLoading(), // Set button callback to null when loading, otherwise call simulation method
                child: _isLoading // Conditionally display button content based on loading state
                    ? const DiceLoadingSmall(size: 20) // Show small dice loading widget when loading
                    : const Text('Sign In'), // Show "Sign In" text when not loading
              ), // End of ElevatedButton
              
              const SizedBox(height: 32), // Add vertical spacing of 32 pixels
              const Text( // Display a section header for dialog loading
                'Dialog Loading', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 2: Loading dialog
              ElevatedButton( // Create an elevated button to demonstrate dialog loading
                onPressed: () => _showLoadingDialog(), // Set button callback to show loading dialog
                child: const Text('Show Loading Dialog'), // Set button text to "Show Loading Dialog"
              ), // End of ElevatedButton
              
              const SizedBox(height: 32), // Add vertical spacing of 32 pixels
              const Text( // Display a section header for overlay loading
                'Overlay Loading', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 3: Overlay loading
              ElevatedButton( // Create an elevated button to demonstrate overlay loading
                onPressed: () => _showLoadingOverlay(), // Set button callback to show loading overlay
                child: const Text('Show Overlay Loading'), // Set button text to "Show Overlay Loading"
              ), // End of ElevatedButton
              
              const SizedBox(height: 32), // Add vertical spacing of 32 pixels
              const Text( // Display a section header for snackbar loading
                'SnackBar Loading', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 4: SnackBar loading
              ElevatedButton( // Create an elevated button to demonstrate snackbar loading
                onPressed: () => LoadingUtils.showLoadingSnackBar(context, message: 'Loading data...'), // Set button callback to show loading snackbar
                child: const Text('Show Loading SnackBar'), // Set button text to "Show Loading SnackBar"
              ), // End of ElevatedButton
              
              const SizedBox(height: 32), // Add vertical spacing of 32 pixels
              const Text( // Display a section header for inline loading widget
                'Inline Loading Widget', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 5: Inline loading widget
              Container( // Create a container to demonstrate inline loading widget
                padding: const EdgeInsets.all(16), // Add padding of 16 pixels on all sides
                decoration: BoxDecoration( // Define decoration for the container
                  color: Colors.grey[900], // Set background color to dark gray
                  borderRadius: BorderRadius.circular(12), // Set border radius to 12 pixels
                ), // End of BoxDecoration
                child: const DiceLoadingWidget( // Display the dice loading widget inside the container
                  message: 'Loading your favorite teams...', // Set the loading message
                  size: 60, // Set the loading widget size to 60 pixels
                ), // End of DiceLoadingWidget
              ), // End of Container
              
              const SizedBox(height: 32), // Add vertical spacing of 32 pixels
              const Text( // Display a section header for small inline loader
                'Small Inline Loader', // Set the text content
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), // Set text style with white color, 18px font size, and bold weight
              ), // End of section header text
              const SizedBox(height: 16), // Add vertical spacing of 16 pixels
              
              // Example 6: Small inline loader
              Row( // Create a row to demonstrate small inline loader
                children: [ // List of widgets to display in the row
                  const Text('Processing', style: TextStyle(color: Colors.white)), // Display "Processing" text with white color
                  const SizedBox(width: 8), // Add horizontal spacing of 8 pixels
                  const DiceLoadingSmall(size: 16), // Display small dice loading widget with 16px size
                ], // End of row children
              ), // End of Row
            ], // End of column children
          ), // End of Column
        ), // End of SingleChildScrollView
      ), // End of LoadingUtils.buildLoadingOverlay
    ); // End of Scaffold
  } // End of build method

  Future<void> _simulateButtonLoading() async { // Define async method to simulate button loading
    setState(() => _isLoading = true); // Set loading state to true and trigger rebuild
    await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds to simulate loading
    setState(() => _isLoading = false); // Set loading state to false and trigger rebuild
  } // End of _simulateButtonLoading method

  Future<void> _showLoadingDialog() async { // Define async method to show loading dialog
    LoadingUtils.showLoading(context, message: 'Authenticating user...'); // Show loading dialog with authentication message
    await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds to simulate loading
    LoadingUtils.hideLoading(context); // Hide the loading dialog
  } // End of _showLoadingDialog method

  Future<void> _showLoadingOverlay() async { // Define async method to show loading overlay
    setState(() => _showOverlay = true); // Set overlay state to true and trigger rebuild
    await Future.delayed(const Duration(seconds: 3)); // Wait for 3 seconds to simulate loading
    setState(() => _showOverlay = false); // Set overlay state to false and trigger rebuild
  } // End of _showLoadingOverlay method
} // End of _LoadingExamplesPageState class

// HOW TO USE IN YOUR EXISTING PAGES:
//
// 1. Import the widgets:
// import '../widgets/dice_loading_widget.dart';
// import '../utils/loading_utils.dart';
//
// 2. For button loading:
// child: _isLoading ? const DiceLoadingSmall(size: 20) : const Text('Button Text')
//
// 3. For dialog loading:
// LoadingUtils.showLoading(context, message: 'Loading...');
// // do async work
// LoadingUtils.hideLoading(context);
//
// 4. For full screen loading:
// if (_isLoading) {
//   return LoadingUtils.getFullScreenLoader(message: 'Loading data...');
// }
//
// 5. For overlay loading:
// return LoadingUtils.buildLoadingOverlay(
//   isLoading: _isLoading,
//   message: 'Processing...',
//   child: YourMainWidget(),
// );