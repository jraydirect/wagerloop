import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import 'package:device_preview/device_preview.dart'; // Import device preview package for testing on different screen sizes
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for backend database and authentication
import 'services/supabase_config.dart'; // Import local configuration file for Supabase connection settings
import 'wrappers/auth_wrapper.dart'; // Import authentication wrapper to handle user authentication state
import 'pages/auth/login_page.dart'; // Import login page component for user authentication
import 'pages/auth/register_page.dart'; // Import registration page component for new user signup
import 'pages/auth/onboarding_page.dart'; // Import onboarding page component for new user introduction
import 'pages/splash_screen.dart'; // Import splash screen component for app startup
import 'pages/bouncy_splash_screen.dart'; // Import bouncy splash screen component with animation
import 'pages/dice_bouncy_splash_screen.dart'; // Import dice-themed bouncy splash screen component
import 'pages/figma_bouncy_loader.dart'; // Import Figma-designed bouncy loader component
import 'pages/figma_ball_splash.dart'; // Import Figma-designed ball splash screen component
import 'layouts/main_layout.dart'; // Import main layout component that contains the app's primary structure
import 'package:flutter/foundation.dart' show kIsWeb; // Import foundation library specifically for web platform detection
import 'dart:io' show Platform; // Import Dart IO library specifically for platform detection

void main() async { // Define the main function as asynchronous to handle initialization tasks
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter widget binding is initialized before running async operations

  await Supabase.initialize( // Initialize Supabase client with configuration settings
    url: SupabaseConfig.supaBaseURL, // Set the Supabase project URL from configuration
    anonKey: SupabaseConfig.supaBaseAnonKey, // Set the anonymous key for Supabase authentication
    authFlowType: AuthFlowType.pkce, // Set authentication flow type to PKCE for enhanced security
  ); // End of Supabase initialization

  runApp( // Start the Flutter application with the specified widget
    DevicePreview( // Wrap the app in DevicePreview for multi-device testing
      enabled: kIsWeb && !const bool.fromEnvironment('dart.vm.product'), // Enable device preview only in web debug mode
      builder: (context) => const MyApp(), // Build the MyApp widget as the root of the application
    ), // End of DevicePreview wrapper
  ); // End of runApp function call
} // End of main function

class MyApp extends StatelessWidget { // Define MyApp as a stateless widget that represents the entire application
  const MyApp({super.key}); // Constructor for MyApp with optional key parameter

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the application
    return MaterialApp( // Return a MaterialApp widget that provides material design structure
      useInheritedMediaQuery: true, // Use inherited media query for responsive design
      locale: DevicePreview.locale(context), // Set locale based on device preview settings
      builder: DevicePreview.appBuilder, // Use device preview's app builder for consistent testing
      debugShowCheckedModeBanner: false, // Hide the debug banner in debug mode
      title: 'Sports App', // Set the application title shown in task switcher
      theme: ThemeData.light().copyWith( // Create a light theme and customize it with copyWith
        platform: Theme.of(context).platform, // Set platform-specific theme adjustments
        scaffoldBackgroundColor: Colors.grey[800], // Set dark gray background for all scaffold widgets
        primaryColor: Colors.green, // Set primary color theme to green
        colorScheme: ColorScheme.light( // Define a light color scheme with custom colors
          primary: Colors.green, // Set primary color to green
          secondary: Colors.greenAccent, // Set secondary color to green accent
          surface: Colors.white, // Set surface color to white
          background: Colors.grey[800], // Set background color to dark gray
          onPrimary: Colors.white, // Set text color on primary surfaces to white
          onSecondary: Colors.white, // Set text color on secondary surfaces to white
          onSurface: Colors.black87, // Set text color on surface to dark black
          onBackground: Colors.white, // Set text color on background to white
        ), // End of ColorScheme definition
        inputDecorationTheme: InputDecorationTheme( // Define theme for input field decorations
          filled: true, // Enable filled background for input fields
          fillColor: Colors.white.withOpacity(0.1), // Set semi-transparent white fill color
          border: OutlineInputBorder( // Define default border style for input fields
            borderRadius: BorderRadius.circular(12), // Set border radius to 12 pixels
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // Set border color to semi-transparent white
          ), // End of default border definition
          enabledBorder: OutlineInputBorder( // Define border style for enabled input fields
            borderRadius: BorderRadius.circular(12), // Set border radius to 12 pixels
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // Set border color to semi-transparent white
          ), // End of enabled border definition
          labelStyle: const TextStyle(color: Colors.white), // Set label text color to white
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)), // Set hint text color to semi-transparent white
          focusedBorder: OutlineInputBorder( // Define border style for focused input fields
            borderRadius: BorderRadius.circular(12), // Set border radius to 12 pixels
            borderSide: const BorderSide(color: Colors.white, width: 2), // Set focused border to solid white with 2px width
          ), // End of focused border definition
        ), // End of InputDecorationTheme
        elevatedButtonTheme: ElevatedButtonThemeData( // Define theme for elevated buttons
          style: ElevatedButton.styleFrom( // Create elevated button style
            minimumSize: const Size(double.infinity, 50), // Set minimum button size to full width and 50px height
            shape: RoundedRectangleBorder( // Define button shape as rounded rectangle
              borderRadius: BorderRadius.circular(12), // Set border radius to 12 pixels
            ), // End of button shape definition
            backgroundColor: Colors.white, // Set button background color to white
            foregroundColor: Colors.green, // Set button text color to green
          ), // End of ElevatedButton style definition
        ), // End of ElevatedButtonThemeData
        appBarTheme: AppBarTheme( // Define theme for app bars
          backgroundColor: Colors.grey[800], // Set app bar background color to dark gray
          elevation: 0, // Remove shadow elevation from app bar
          centerTitle: true, // Center the title text in app bar
          titleTextStyle: const TextStyle( // Define text style for app bar title
            color: Colors.white, // Set title text color to white
            fontSize: 20, // Set title font size to 20 pixels
            fontWeight: FontWeight.bold, // Set title font weight to bold
          ), // End of title text style definition
          iconTheme: const IconThemeData(color: Colors.white), // Set app bar icon color to white
        ), // End of AppBarTheme
        bottomNavigationBarTheme: BottomNavigationBarThemeData( // Define theme for bottom navigation bar
          backgroundColor: Colors.grey[800], // Set bottom navigation background color to dark gray
          selectedItemColor: Colors.white, // Set selected item color to white
          unselectedItemColor: Colors.white54, // Set unselected item color to semi-transparent white
          showSelectedLabels: true, // Show labels for selected navigation items
          showUnselectedLabels: true, // Show labels for unselected navigation items
          type: BottomNavigationBarType.fixed, // Set navigation bar type to fixed layout
        ), // End of BottomNavigationBarThemeData
        chipTheme: ChipThemeData( // Define theme for chip widgets
          backgroundColor: Colors.grey[700], // Set chip background color to dark gray
          selectedColor: Colors.green, // Set selected chip color to green
          labelStyle: const TextStyle(color: Colors.green), // Set unselected chip text color to green
          secondaryLabelStyle: const TextStyle(color: Colors.white), // Set selected chip text color to white
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Set chip padding to 12px horizontal and 8px vertical
        ), // End of ChipThemeData
      ), // End of theme definition
      initialRoute: '/', // Set the initial route to root path for authentication check
      routes: { // Define named routes for navigation throughout the app
        '/splash': (context) => const FigmaBallSplash(), // Route to Figma ball splash screen with bouncing animation
        '/': (context) => const AuthWrapper(), // Root route to authentication wrapper for login state management
        '/auth/login': (context) => const LoginPage(), // Route to login page for user authentication
        '/auth/register': (context) => const RegisterPage(), // Route to registration page for new user signup
        '/auth/onboarding': (context) => OnboardingPage(), // Route to onboarding page for new user introduction
        '/main': (context) => const MainLayout(), // Route to main layout containing the primary app interface
      }, // End of routes definition
    ); // End of MaterialApp widget
  } // End of build method
} // End of MyApp class
