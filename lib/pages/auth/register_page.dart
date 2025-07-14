// Ignore linting warnings for unused imports
// ignore_for_file: unused_import

// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import GoTrue client for authentication operations
import 'package:gotrue/src/gotrue_client.dart';
// Import Supabase Flutter library for backend operations
import 'package:supabase_flutter/supabase_flutter.dart';
// Import authentication service to handle registration operations
import '../../services/auth_service.dart';
// Import foundation library to check if running on web platform
import 'package:flutter/foundation.dart' show kIsWeb;
// Import Supabase configuration for database operations
import '../../services/supabase_config.dart';
// Import custom dice loading widget for loading animations
import '../../widgets/dice_loading_widget.dart';

// RegisterPage class definition - a stateful widget for user registration interface
class RegisterPage extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const RegisterPage({super.key});

  // Override createState method to return the state class instance
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

// Private state class that manages the registration page's state and functionality
class _RegisterPageState extends State<RegisterPage> {
  // Form key for form validation and state management
  final _formKey = GlobalKey<FormState>();
  // Text controller for email input field
  final _emailController = TextEditingController();
  // Text controller for password input field
  final _passwordController = TextEditingController();
  // Text controller for confirm password input field
  final _confirmPasswordController = TextEditingController();
  // Text controller for username input field
  final _usernameController = TextEditingController();
  // Authentication service instance for handling registration operations
  final _authService = AuthService();
  // Boolean flag to track loading state during registration
  bool _isLoading = false;
  // Boolean flag to control password visibility
  bool _obscurePassword = true;
  // Boolean flag to control confirm password visibility
  bool _obscureConfirmPassword = true;

  // Async method to handle user registration process
  Future<void> _register() async {
    // Validate form inputs before proceeding
    if (!_formKey.currentState!.validate()) return;

    // Set loading state to true and update UI
    setState(() => _isLoading = true);
    try {
      // Check username uniqueness
      final existingUsername = await SupabaseConfig.supabase
          .from('profiles')
          .select('username')
          .eq('username', _usernameController.text)
          .maybeSingle();

      // Throw error if username already exists
      if (existingUsername != null) {
        throw 'Username is already taken';
      }

      // Attempt signup (this should handle profile creation)
      final response = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );

      // Check if user was successfully created
      if (response.user != null) {
        // Navigate to onboarding
        Navigator.of(context).pushReplacementNamed('/auth/onboarding');
      }
    } catch (e) {
      // Show error message if registration failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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

  // Async method to handle Google sign-up process
  Future<void> _signUpWithGoogle() async {
    // Set loading state to true and update UI
    setState(() => _isLoading = true);
    try {
      // Attempt to sign in with Google using auth service
      final response = await _authService.signInWithGoogle();
      // Check if user was successfully created
      if (response.user != null) {
        // Check if widget is still mounted before proceeding
        if (mounted) {
          // Check if user has completed onboarding
          final profile = await _authService.getCurrentUserProfile();
          final hasCompletedOnboarding =
              profile?['has_completed_onboarding'] ?? false;

          // Check if widget is still mounted before navigation
          if (mounted) {
            // Navigate based on onboarding completion status
            if (hasCompletedOnboarding) {
              // Navigate to main app if onboarding completed
              Navigator.of(context).pushReplacementNamed('/main');
            } else {
              // Navigate to onboarding if not completed
              Navigator.of(context).pushReplacementNamed('/auth/onboarding');
            }
          }
        }
      }
    } catch (e) {
      // Check if widget is still mounted before showing error
      if (mounted) {
        // Show error message specific to Google sign-up
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing up with Google: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to build the Google sign-up button widget
  Widget _buildGoogleSignUpButton() {
    // Return outlined button with custom styling
    return OutlinedButton(
      // Set onPressed callback, disabled when loading
      onPressed: _isLoading ? null : _signUpWithGoogle,
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
          const Text('Sign up with Google'),
        ],
      ),
    );
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with black background and app bar
    return Scaffold(
      backgroundColor: Colors.black,
      // App bar with back button
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Back button configuration
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
              // Left align the column contents
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Create account title text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Small spacing after title
                const SizedBox(height: 8),
                // Subtitle text
                const Text(
                  'Join the community of sports fans',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                // Spacing after subtitle
                const SizedBox(height: 32),

                // Email & Password Form
                // Username input field
                TextFormField(
                  // Set text controller for username input
                  controller: _usernameController,
                  // Set text color to white
                  style: const TextStyle(color: Colors.white),
                  // Configure field appearance
                  decoration: const InputDecoration(
                    // Field label
                    labelText: 'Username',
                    // Label color
                    labelStyle: TextStyle(color: Colors.grey),
                    // Prefix icon
                    prefixIcon: Icon(Icons.person, color: Colors.grey),
                  ),
                  // Validation logic for username field
                  validator: (value) {
                    // Check if username is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a username';
                    }
                    // Check minimum username length
                    if (value!.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    // Return null if validation passes
                    return null;
                  },
                ),
                // Spacing between username and email fields
                const SizedBox(height: 16),
                // Email input field
                TextFormField(
                  // Set text controller for email input
                  controller: _emailController,
                  // Set text color to white
                  style: const TextStyle(color: Colors.white),
                  // Configure field appearance
                  decoration: const InputDecoration(
                    // Field label
                    labelText: 'Email',
                    // Label color
                    labelStyle: TextStyle(color: Colors.grey),
                    // Prefix icon
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                  ),
                  // Validation logic for email field
                  validator: (value) {
                    // Check if email is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your email';
                    }
                    // Check if email format is valid using regex
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value!)) {
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
                  // Control password visibility
                  obscureText: _obscurePassword,
                  // Configure field appearance
                  decoration: InputDecoration(
                    // Field label
                    labelText: 'Password',
                    // Label color
                    labelStyle: const TextStyle(color: Colors.grey),
                    // Prefix icon
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    // Suffix icon for password visibility toggle
                    suffixIcon: IconButton(
                      // Icon changes based on password visibility state
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      // Toggle password visibility when pressed
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  // Validation logic for password field
                  validator: (value) {
                    // Check if password is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a password';
                    }
                    // Check minimum password length
                    if (value!.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    // Return null if validation passes
                    return null;
                  },
                ),
                // Spacing between password and confirm password fields
                const SizedBox(height: 16),
                // Confirm password input field
                TextFormField(
                  // Set text controller for confirm password input
                  controller: _confirmPasswordController,
                  // Set text color to white
                  style: const TextStyle(color: Colors.white),
                  // Control confirm password visibility
                  obscureText: _obscureConfirmPassword,
                  // Configure field appearance
                  decoration: InputDecoration(
                    // Field label
                    labelText: 'Confirm Password',
                    // Label color
                    labelStyle: const TextStyle(color: Colors.grey),
                    // Prefix icon
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: Colors.grey),
                    // Suffix icon for confirm password visibility toggle
                    suffixIcon: IconButton(
                      // Icon changes based on confirm password visibility state
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      // Toggle confirm password visibility when pressed
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  // Validation logic for confirm password field
                  validator: (value) {
                    // Check if confirm password is empty
                    if (value?.isEmpty ?? true) {
                      return 'Please confirm your password';
                    }
                    // Check if passwords match
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    // Return null if validation passes
                    return null;
                  },
                ),
                // Spacing before sign-up button
                const SizedBox(height: 24),

                // Sign Up Button
                // Create account button
                ElevatedButton(
                  // Set onPressed callback, disabled when loading
                  onPressed: _isLoading ? null : _register,
                  // Configure button styling
                  style: ElevatedButton.styleFrom(
                    // Set minimum button size to fill width
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  // Button content - loading indicator or text
                  child: _isLoading
                      ? const DiceLoadingSmall(size: 20)
                      : const Text('Create Account'),
                ),

                // Spacing before divider
                const SizedBox(height: 16),
                // Divider row with "OR" text
                Row(
                  children: const [
                    // Left divider line
                    Expanded(child: Divider(color: Colors.grey)),
                    // "OR" text with padding
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    // Right divider line
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                // Spacing after divider
                const SizedBox(height: 16),

                // Google Sign Up Button
                // Google sign-up button
                _buildGoogleSignUpButton(),

                // Spacing before sign-in link
                const SizedBox(height: 16),
                // Sign-in navigation row
                Row(
                  // Center the row contents
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "Already have an account" text
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    // Sign-in navigation button
                    TextButton(
                      // Navigate back to login page when pressed
                      onPressed: () => Navigator.of(context).pop(),
                      // Button text
                      child: const Text('Sign In'),
                    ),
                  ],
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
    // Dispose confirm password controller to prevent memory leaks
    _confirmPasswordController.dispose();
    // Dispose username controller to prevent memory leaks
    _usernameController.dispose();
    // Call super dispose to complete cleanup
    super.dispose();
  }
}

// Extension on GoTrueClient to add user retrieval functionality
extension on GoTrueClient {
  // Method to retrieve user by email address
  Future<User?> retrieveUserByEmail(String email) async {
    try {
      // Use Supabase's method to check if user exists
      final users = await SupabaseConfig.supabase.auth.admin.listUsers();
      // Filter users by matching email
      final matchingUsers = users.where((user) => user.email == email);

      // Return first matching user or null if not found
      return matchingUsers.isNotEmpty ? matchingUsers.first : null;
    } catch (e) {
      // Log error checking user email
      print('Error checking user email: $e');
      // Return null if error occurs
      return null;
    }
  }
}
