// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import foundation library to check if running on web platform
import 'package:flutter/foundation.dart' show kIsWeb;
// Import authentication service to handle login operations
import '../../services/auth_service.dart';
// Import custom dice loading widget for loading animations
import '../../widgets/dice_loading_widget.dart';

// LoginPage class definition - a stateful widget for user login interface
class LoginPage extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const LoginPage({super.key});

  // Override createState method to return the state class instance
  @override
  _LoginPageState createState() => _LoginPageState();
}

// Private state class that manages the login page's state and functionality
class _LoginPageState extends State<LoginPage> {
  // Form key for form validation and state management
  final _formKey = GlobalKey<FormState>();
  // Text controller for email input field
  final _emailController = TextEditingController();
  // Text controller for password input field
  final _passwordController = TextEditingController();
  // Authentication service instance for handling login operations
  final _authService = AuthService();
  // Boolean flag to track loading state during authentication
  bool _isLoading = false;

  // Async method to handle email/password sign-in process
  Future<void> _signInWithEmail() async {
    // Validate form inputs before proceeding
    if (!_formKey.currentState!.validate()) return;

    // Set loading state to true and update UI
    setState(() => _isLoading = true);
    try {
      // Attempt to sign in with email and password using auth service
      final response = await _authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Extract session and user data from response
      final session = response.session;
      final user = response.user;

      // Check if both session and user are valid
      if (session != null && user != null) {
        // Navigate to scores page on successful login
        Navigator.of(context).pushReplacementNamed('/scores');
      } else {
        // Show error message if login failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in. Please try again.')),
        );
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      // Show error message with detailed error information
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Async method to handle Google sign-in process
  Future<void> _signInWithGoogle() async {
    // Set loading state to true and update UI
    setState(() => _isLoading = true);
    try {
      // Attempt to sign in with Google using auth service
      final response = await _authService.signInWithGoogle();

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      // Handle different behavior for mobile vs web platforms
      if (!kIsWeb) {
        // For mobile platforms, wait for session
        final session = response.session;
        final user = response.user;

        // Check if both session and user are valid
        if (session != null && user != null) {
          // Navigate to scores page on successful login
          Navigator.of(context).pushReplacementNamed('/scores');
        } else {
          // Show error message if login failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to sign in. Please try again.')),
          );
        }
      }
      // For web, the auth state change will handle navigation
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (!mounted) return;

      // Show error message specific to Google sign-in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in with Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to build the Google sign-in button widget
  Widget _buildGoogleSignInButton() {
    // Return outlined button with custom styling
    return OutlinedButton(
      // Set onPressed callback, disabled when loading
      onPressed: _isLoading ? null : _signInWithGoogle,
      // Configure button styling
      style: OutlinedButton.styleFrom(
        // Set minimum button size to fill width
        minimumSize: const Size(double.infinity, 50),
        // Set rounded corners
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Set white border color
        side: const BorderSide(color: Colors.white),
      ),
      // Button content with Google logo and text
      child: Row(
        // Center the row contents
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google logo image asset
          Image.asset('assets/google_logo.png', height: 24),
          // Spacing between logo and text
          const SizedBox(width: 12),
          // Button text
          const Text('Sign in with Google'),
        ],
      ),
    );
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with black background
    return Scaffold(
      backgroundColor: Colors.black,
      // Safe area to avoid system UI overlaps
      body: SafeArea(
        // Scrollable view to handle keyboard overflow
        child: SingleChildScrollView(
          // Padding around the entire content
          padding: const EdgeInsets.all(16),
          // Form widget for input validation
          child: Form(
            key: _formKey,
            // Column to arrange form elements vertically
            child: Column(
              // Center the column contents
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top spacing
                const SizedBox(height: 50),
                // Welcome back title text
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Spacing after title
                const SizedBox(height: 50),
                // Email input field
                TextFormField(
                  // Set text controller for email input
                  controller: _emailController,
                  // Set text color to white
                  style: const TextStyle(color: Colors.white),
                  // Configure field appearance
                  decoration: InputDecoration(
                    // Field label
                    labelText: 'Email',
                    // Label color
                    labelStyle: const TextStyle(color: Colors.grey),
                    // Fill background
                    filled: true,
                    // Background color
                    fillColor: Colors.grey[900],
                    // Border styling
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Validation logic for email field
                  validator: (value) {
                    // Check if email is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    // Check if email contains @ symbol
                    if (!value!.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    // Return null if validation passes
                    return null;
                  },
                ),
                // Spacing between email and password fields
                const SizedBox(height: 16),
                // Password input field
                TextFormField(
                  // Set text controller for password input
                  controller: _passwordController,
                  // Set text color to white
                  style: const TextStyle(color: Colors.white),
                  // Configure field appearance
                  decoration: InputDecoration(
                    // Field label
                    labelText: 'Password',
                    // Label color
                    labelStyle: const TextStyle(color: Colors.grey),
                    // Fill background
                    filled: true,
                    // Background color
                    fillColor: Colors.grey[900],
                    // Border styling
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Hide password text
                  obscureText: true,
                  // Validation logic for password field
                  validator: (value) {
                    // Check if password is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your password';
                    }
                    // Check minimum password length
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    // Return null if validation passes
                    return null;
                  },
                ),
                // Spacing before sign-in button
                const SizedBox(height: 24),
                // Email sign-in button
                ElevatedButton(
                  // Set onPressed callback, disabled when loading
                  onPressed: _isLoading ? null : _signInWithEmail,
                  // Configure button styling
                  style: ElevatedButton.styleFrom(
                    // Set minimum button size to fill width
                    minimumSize: const Size(double.infinity, 50),
                    // Set rounded corners
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Button content - loading indicator or text
                  child: _isLoading
                      ? const DiceLoadingSmall(size: 20)
                      : const Text('Sign In'),
                ),
                // Spacing between buttons
                const SizedBox(height: 16),
                // Google sign-in button
                _buildGoogleSignInButton(),
                // Spacing before register link
                const SizedBox(height: 16),
                // Register navigation button
                TextButton(
                  // Navigate to register page when pressed
                  onPressed: () {
                    Navigator.pushNamed(context, '/auth/register');
                  },
                  // Button text
                  child: const Text(
                    'Don\'t have an account? Sign up',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose email controller to prevent memory leaks
    _emailController.dispose();
    // Dispose password controller to prevent memory leaks
    _passwordController.dispose();
    // Call super dispose to complete cleanup
    super.dispose();
  }
}
