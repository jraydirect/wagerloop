import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for authentication state management
import '../services/auth_service.dart'; // Import local authentication service for user authentication operations
import '../pages/auth/login_page.dart'; // Import login page component for user authentication
import '../pages/auth/onboarding_page.dart'; // Import onboarding page component for new user setup
import '../pages/figma_ball_splash.dart'; // Import Figma ball splash screen component for initial loading
import '../layouts/main_layout.dart'; // Import main layout component for authenticated users
import '../widgets/dice_loading_widget.dart'; // Import dice loading widget for loading animations

class AuthWrapper extends StatefulWidget { // Define AuthWrapper as a stateful widget to manage authentication state
  const AuthWrapper({super.key}); // Constructor for AuthWrapper with optional key parameter

  @override // Override the createState method from StatefulWidget
  State<AuthWrapper> createState() => _AuthWrapperState(); // Return the state object for this widget
} // End of AuthWrapper class

class _AuthWrapperState extends State<AuthWrapper> { // Define the state class for AuthWrapper widget
  final _authService = AuthService(); // Create an instance of AuthService to handle authentication operations

  @override // Override the build method from State class
  Widget build(BuildContext context) { // Build method that returns the widget tree based on authentication state
    return StreamBuilder<AuthState>( // Return a StreamBuilder that listens to authentication state changes
      stream: _authService.authStateChanges, // Set the stream to listen to authentication state changes
      builder: (context, snapshot) { // Builder function that rebuilds when authentication state changes
        print('Auth State Connection State: ${snapshot.connectionState}'); // Log the connection state for debugging
        print('Auth State Data: ${snapshot.data}'); // Log the authentication data for debugging
        print('Auth State Error: ${snapshot.error}'); // Log any authentication errors for debugging

        // Handle stream errors
        if (snapshot.hasError) { // Check if there is an error in the authentication stream
          print('Auth Stream Error: ${snapshot.error}'); // Log the authentication stream error for debugging
          return Scaffold( // Return a Scaffold widget to display the error state
            backgroundColor: Colors.black, // Set the background color to black for error display
            body: Center( // Center the error content in the body
              child: Column( // Create a column layout for error content
                mainAxisAlignment: MainAxisAlignment.center, // Center the column content vertically
                children: [ // List of widgets to display in the error state
                  Text( // Display the error message as text
                    'Authentication Error: ${snapshot.error}', // Show the authentication error message
                    style: const TextStyle(color: Colors.white), // Set text color to white for visibility
                    textAlign: TextAlign.center, // Center align the error text
                  ), // End of error message text
                  const SizedBox(height: 16), // Add vertical spacing of 16 pixels
                  ElevatedButton( // Create an elevated button for navigation
                    onPressed: () { // Define the button press handler
                      Navigator.of(context).pushReplacementNamed('/auth/login'); // Navigate to login page replacing current route
                    }, // End of button press handler
                    child: const Text('Return to Login'), // Set button text to "Return to Login"
                  ), // End of elevated button
                ], // End of column children list
              ), // End of column widget
            ), // End of center widget
          ); // End of scaffold widget
        } // End of error handling condition

        // Check current session
        final session = _authService.currentSession; // Get the current user session from authentication service
        print('Checking session: $session'); // Log the current session for debugging

        // If no session, show splash screen for first-time experience
        if (session == null) { // Check if there is no active user session
          print('No session, showing FigmaBallSplash'); // Log that no session exists and splash screen will be shown
          return const FigmaBallSplash(); // Return the Figma ball splash screen for unauthenticated users
        } // End of no session condition

        // For authenticated users, check onboarding status
        return FutureBuilder<Map<String, dynamic>?>( // Return a FutureBuilder to handle async user profile loading
          future: _authService.getCurrentUserProfile(), // Set the future to get the current user profile
          builder: (context, profileSnapshot) { // Builder function that rebuilds when profile data is available
            if (profileSnapshot.connectionState == ConnectionState.waiting) { // Check if profile data is still loading
              return const Scaffold( // Return a Scaffold widget to display the loading state
                backgroundColor: Colors.black, // Set the background color to black for loading display
                body: DiceLoadingWidget( // Display the dice loading widget for visual feedback
                  message: 'Setting up your profile...', // Set the loading message for user feedback
                  size: 100, // Set the size of the loading widget to 100 pixels
                ), // End of dice loading widget
              ); // End of scaffold widget
            } // End of loading state condition

            final hasCompletedOnboarding = // Extract the onboarding completion status from profile data
                profileSnapshot.data?['has_completed_onboarding'] ?? false; // Get onboarding status with default false if null

            if (!hasCompletedOnboarding) { // Check if user has not completed onboarding
              print('Onboarding not completed, showing OnboardingPage'); // Log that onboarding needs to be completed
              return const OnboardingPage(); // Return the onboarding page for new users
            } // End of onboarding check condition

            // User is authenticated and has completed onboarding
            print('Session found and onboarding complete, showing MainLayout'); // Log that user is fully authenticated and onboarded
            return const MainLayout(); // Return the main layout for authenticated and onboarded users
          }, // End of profile builder function
        ); // End of FutureBuilder widget
      }, // End of stream builder function
    ); // End of StreamBuilder widget
  } // End of build method
} // End of _AuthWrapperState class
