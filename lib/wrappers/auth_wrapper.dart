// Import Flutter material library for UI components - provides widgets and styling
import 'package:flutter/material.dart';
// Import Supabase Flutter SDK for authentication - provides auth state management
import 'package:supabase_flutter/supabase_flutter.dart';
// Import authentication service for user management - provides auth operations
import '../services/auth_service.dart';
// Import login page for authentication - provides login interface
import '../pages/auth/login_page.dart';
// Import onboarding page for user setup - provides initial user configuration
import '../pages/auth/onboarding_page.dart';
// Import Figma ball splash screen - provides animated splash experience
import '../pages/figma_ball_splash.dart';
// Import main layout for authenticated users - provides main app interface
import '../layouts/main_layout.dart';
// Import dice loading widget for themed loading - provides branded loading animation
import '../widgets/dice_loading_widget.dart';

// Widget that manages authentication state and routing - determines which screen to show based on auth status
class AuthWrapper extends StatefulWidget {
  // Constructor with optional key parameter - creates new AuthWrapper widget
  const AuthWrapper({super.key});

  // Override createState to return the state class - creates the widget's state
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// State class for AuthWrapper widget - manages authentication state and UI routing
class _AuthWrapperState extends State<AuthWrapper> {
  // Instance of authentication service - provides access to auth operations
  final _authService = AuthService();

  // Build the widget UI - creates the authentication flow interface
  @override
  Widget build(BuildContext context) {
    // Return StreamBuilder to listen to authentication state changes - monitors auth state in real-time
    return StreamBuilder<AuthState>(
      // Listen to auth state changes from the service - receives real-time auth updates
      stream: _authService.authStateChanges,
      // Builder function that creates UI based on auth state - determines which screen to show
      builder: (context, snapshot) {
        // Print debug information for troubleshooting - logs auth state details
        print('Auth State Connection State: ${snapshot.connectionState}');
        print('Auth State Data: ${snapshot.data}');
        print('Auth State Error: ${snapshot.error}');

        // Handle stream errors - manages authentication stream failures
        if (snapshot.hasError) {
          // Print error details for debugging - logs stream error information
          print('Auth Stream Error: ${snapshot.error}');
          // Return error screen with manual login option - provides fallback UI
          return Scaffold(
            backgroundColor: Colors.black, // Dark background for error state
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Authentication Error: ${snapshot.error}', // Display error message
                    style: const TextStyle(color: Colors.white), // White text for visibility
                    textAlign: TextAlign.center, // Center align text
                  ),
                  const SizedBox(height: 16), // Spacing between elements
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to login page when button pressed - provides manual login option
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                    child: const Text('Return to Login'), // Button text
                  ),
                ],
              ),
            ),
          );
        }

        // Check current session - retrieves current authentication session
        final session = _authService.currentSession;
        // Print session information for debugging - logs session details
        print('Checking session: $session');

        // If no session, show splash screen for first-time experience - handles unauthenticated users
        if (session == null) {
          // Print debug message - logs splash screen display
          print('No session, showing FigmaBallSplash');
          // Return animated splash screen - provides branded first-time experience
          return const FigmaBallSplash();
        }

        // For authenticated users, check onboarding status - determines if user setup is complete
        return FutureBuilder<Map<String, dynamic>?>(
          // Get current user profile to check onboarding status - retrieves user setup information
          future: _authService.getCurrentUserProfile(),
          // Builder function that creates UI based on profile data - handles onboarding flow
          builder: (context, profileSnapshot) {
            // Show loading screen while fetching profile - provides loading feedback
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black, // Dark background for loading
                body: DiceLoadingWidget(
                  message: 'Setting up your profile...', // Loading message
                  size: 100, // Loading widget size
                ),
              );
            }

            // Check if user has completed onboarding - determines onboarding status
            final hasCompletedOnboarding =
                profileSnapshot.data?['has_completed_onboarding'] ?? false;

            // If onboarding not completed, show onboarding page - guides user through setup
            if (!hasCompletedOnboarding) {
              // Print debug message - logs onboarding page display
              print('Onboarding not completed, showing OnboardingPage');
              // Return onboarding page for user setup - provides initial configuration interface
              return const OnboardingPage();
            }

            // User is authenticated and has completed onboarding - user is ready for main app
            // Print debug message - logs main layout display
            print('Session found and onboarding complete, showing MainLayout');
            // Return main app layout for authenticated users - provides full app interface
            return const MainLayout();
          },
        );
      },
    );
  }
}
