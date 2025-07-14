// Import Flutter's material design library for UI components
import 'package:flutter/material.dart';
// Import device preview package for responsive design testing
import 'package:device_preview/device_preview.dart';
// Import Supabase Flutter SDK for backend services
import 'package:supabase_flutter/supabase_flutter.dart';
// Import local Supabase configuration file
import 'services/supabase_config.dart';
// Import authentication wrapper component
import 'wrappers/auth_wrapper.dart';
// Import login page component
import 'pages/auth/login_page.dart';
// Import registration page component
import 'pages/auth/register_page.dart';
// Import onboarding page component
import 'pages/auth/onboarding_page.dart';
// Import splash screen component
import 'pages/splash_screen.dart';
// Import bouncy splash screen component
import 'pages/bouncy_splash_screen.dart';
// Import dice bouncy splash screen component
import 'pages/dice_bouncy_splash_screen.dart';
// Import Figma bouncy loader component
import 'pages/figma_bouncy_loader.dart';
// Import Figma ball splash component
import 'pages/figma_ball_splash.dart';
// Import main layout component
import 'layouts/main_layout.dart';
// Import Flutter foundation library for web platform detection
import 'package:flutter/foundation.dart' show kIsWeb;
// Import Dart IO library for platform detection
import 'dart:io' show Platform;

// Main entry point of the application - async function to handle initialization
void main() async {
  // Ensure Flutter bindings are initialized before any UI operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with configuration from supabase_config.dart
  await Supabase.initialize(
    // Set the Supabase project URL
    url: SupabaseConfig.supaBaseURL,
    // Set the anonymous key for client-side operations
    anonKey: SupabaseConfig.supaBaseAnonKey,
    // Use PKCE authentication flow for enhanced security
    authFlowType: AuthFlowType.pkce,
  );

  // Run the Flutter application with device preview wrapper
  runApp(
    // Wrap the app with DevicePreview for responsive design testing
    DevicePreview(
      // Enable device preview only on web and not in production
      enabled: kIsWeb && !const bool.fromEnvironment('dart.vm.product'),
      // Builder function that creates the main app widget
      builder: (context) => const MyApp(),
    ),
  );
}

// Main application widget class that extends StatelessWidget
class MyApp extends StatelessWidget {
  // Constructor with optional key parameter
  const MyApp({super.key});

  // Override the build method to create the app's widget tree
  @override
  Widget build(BuildContext context) {
    // Return MaterialApp widget which is the root of the application
    return MaterialApp(
      // Use inherited media query for responsive design
      useInheritedMediaQuery: true,
      // Set locale from device preview
      locale: DevicePreview.locale(context),
      // Use device preview's app builder for responsive testing
      builder: DevicePreview.appBuilder,
      // Hide the debug banner in the top right corner
      debugShowCheckedModeBanner: false,
      // Set the app title
      title: 'Sports App',
      // Define the app's theme with custom styling
      theme: ThemeData.light().copyWith(
        // Set the platform-specific design
        platform: Theme.of(context).platform,
        // Set the scaffold background color to gray
        scaffoldBackgroundColor: Colors.grey[800], // Changed to gray background
        // Set the primary color to green
        primaryColor: Colors.green,
        // Define the color scheme for the app
        colorScheme: ColorScheme.light(
          // Set primary color to green
          primary: Colors.green,
          // Set secondary color to green accent
          secondary: Colors.greenAccent,
          // Set surface color to white
          surface: Colors.white,
          // Set background color to gray
          background: Colors.grey[800],
          // Set text color on primary to white
          onPrimary: Colors.white,
          // Set text color on secondary to white
          onSecondary: Colors.white,
          // Set text color on surface to dark gray
          onSurface: Colors.black87,
          // Set text color on background to white
          onBackground: Colors.white,
        ),
        // Define input decoration theme for text fields
        inputDecorationTheme: InputDecorationTheme(
          // Enable filled background for input fields
          filled: true,
          // Set fill color with transparency
          fillColor: Colors.white.withOpacity(0.1),
          // Define border style for input fields
          border: OutlineInputBorder(
            // Set border radius for rounded corners
            borderRadius: BorderRadius.circular(12),
            // Set border color with transparency
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          // Define enabled border style
          enabledBorder: OutlineInputBorder(
            // Set border radius for enabled state
            borderRadius: BorderRadius.circular(12),
            // Set border color for enabled state
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          // Set label text style to white
          labelStyle: const TextStyle(color: Colors.white),
          // Set hint text style with transparency
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          // Define focused border style
          focusedBorder: OutlineInputBorder(
            // Set border radius for focused state
            borderRadius: BorderRadius.circular(12),
            // Set border color and width for focused state
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        // Define elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          // Set button style
          style: ElevatedButton.styleFrom(
            // Set minimum button size
            minimumSize: const Size(double.infinity, 50),
            // Define button shape with rounded corners
            shape: RoundedRectangleBorder(
              // Set border radius for button
              borderRadius: BorderRadius.circular(12),
            ),
            // Set button background color to white
            backgroundColor: Colors.white,
            // Set button text color to green
            foregroundColor: Colors.green,
          ),
        ),
        // Define app bar theme
        appBarTheme: AppBarTheme(
          // Set app bar background color to gray
          backgroundColor: Colors.grey[800], // Changed to gray
          // Remove app bar elevation (shadow)
          elevation: 0,
          // Center the app bar title
          centerTitle: true,
          // Define app bar title text style
          titleTextStyle: const TextStyle(
            // Set title color to white
            color: Colors.white,
            // Set title font size
            fontSize: 20,
            // Set title font weight to bold
            fontWeight: FontWeight.bold,
          ),
          // Set app bar icon color to white
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Define bottom navigation bar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          // Set bottom navigation background color to gray
          backgroundColor: Colors.grey[800], // Changed to gray
          // Set selected item color to white
          selectedItemColor: Colors.white,
          // Set unselected item color to semi-transparent white
          unselectedItemColor: Colors.white54,
          // Show labels for selected items
          showSelectedLabels: true,
          // Show labels for unselected items
          showUnselectedLabels: true,
          // Use fixed type for bottom navigation
          type: BottomNavigationBarType.fixed,
        ),
        // Define chip theme for filter chips
        chipTheme: ChipThemeData(
          // Set chip background color to dark gray
          backgroundColor: Colors.grey[700], // Dark gray background
          // Set selected chip color to green
          selectedColor: Colors.green, // Green when selected
          // Set unselected chip label color to green
          labelStyle: const TextStyle(color: Colors.green), // Green text for unselected
          // Set selected chip label color to white
          secondaryLabelStyle: const TextStyle(color: Colors.white), // White text when selected
          // Set chip padding
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      // Set the initial route to root path
      initialRoute: '/', // Start with AuthWrapper to check authentication state
      // Define all available routes in the app
      routes: {
        // Route for splash screen with Figma ball animation
        '/splash': (context) => const FigmaBallSplash(), // Exact Figma recreation: bouncing ball → blue fill → text
        // Root route that shows authentication wrapper
        '/': (context) => const AuthWrapper(),
        // Route for login page
        '/auth/login': (context) => const LoginPage(),
        // Route for registration page
        '/auth/register': (context) => const RegisterPage(),
        // Route for onboarding page
        '/auth/onboarding': (context) => OnboardingPage(),
        // Route for main app layout after authentication
        '/main': (context) => const MainLayout(),
      },
    );
  }
}
