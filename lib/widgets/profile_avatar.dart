// Import Flutter material library for UI components - provides widgets and styling
import 'package:flutter/material.dart';
// Import HTTP library for network requests - provides HTTP client for URL testing
import 'package:http/http.dart' as http;
// Import Dart async library for timer functionality - provides Timer for debouncing
import 'dart:async';

// Widget that displays a user's profile avatar with fallback to initials - handles avatar image loading and error states
class ProfileAvatar extends StatefulWidget {
  // URL of the user's avatar image - the image to display
  final String? avatarUrl;
  // Username for generating fallback initials - used when avatar image fails to load
  final String username;
  // Size of the avatar circle - controls the visual size of the avatar
  final double radius;
  // Background color for the avatar circle - used when no image is available
  final Color? backgroundColor;
  // Callback function for tap events - handles user interaction with avatar
  final VoidCallback? onTap;

  // Constructor that initializes all avatar properties - creates new ProfileAvatar widget
  const ProfileAvatar({
    Key? key,
    required this.avatarUrl,
    required this.username,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  // Override createState to return the state class - creates the widget's state
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

// State class for ProfileAvatar widget - manages avatar loading, error handling, and UI updates
class _ProfileAvatarState extends State<ProfileAvatar> {
  // Flag indicating if the avatar image failed to load - tracks image loading errors
  bool _hasImageError = false;
  // Flag indicating if URL accessibility test is in progress - prevents multiple simultaneous tests
  bool _isLoading = false;
  // Stores the last tested URL to avoid redundant tests - tracks URL changes
  String? _lastUrl;
  // Timer for debouncing URL accessibility tests - prevents excessive network requests
  Timer? _debounceTimer;

  // Initialize state when widget is created - sets up initial URL tracking
  @override
  void initState() {
    // Call parent initState - ensures proper widget initialization
    super.initState();
    // Store initial avatar URL for tracking changes - records the starting URL
    _lastUrl = widget.avatarUrl;
  }

  // Handle widget updates when properties change - responds to avatar URL changes
  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    // Call parent didUpdateWidget - ensures proper widget update handling
    super.didUpdateWidget(oldWidget);
    // Reset error state if avatar URL changes - clears previous error when URL updates
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      // Clear image error flag - allows retry with new URL
      _hasImageError = false;
      // Update last URL reference - tracks the new URL
      _lastUrl = widget.avatarUrl;
      // Test accessibility of the new URL - validates the new avatar URL
      _testUrlAccessibility();
    }
  }

  // Clean up resources when widget is disposed - prevents memory leaks
  @override
  void dispose() {
    // Cancel any pending URL test timer - prevents timer callback after disposal
    _debounceTimer?.cancel();
    // Call parent dispose - ensures proper cleanup
    super.dispose();
  }

  // Build the widget UI - creates the visual representation of the avatar
  @override
  Widget build(BuildContext context) {
    // Determine if we have a valid URL for the avatar - checks URL validity
    final hasValidUrl = widget.avatarUrl != null && 
                       widget.avatarUrl!.isNotEmpty && 
                       !_hasImageError;
    
    // Debug logging for troubleshooting - provides detailed state information
    print('ProfileAvatar Debug:');
    print('- Avatar URL: ${widget.avatarUrl}');
    print('- Username: ${widget.username}');
    print('- Has valid URL: $hasValidUrl');
    print('- Has image error: $_hasImageError');
    print('- Is loading: $_isLoading');
    
    // Return the avatar widget with tap handling - creates the final widget tree
    return GestureDetector(
      // Handle tap events on the avatar - provides user interaction capability
      onTap: widget.onTap,
      // Create circular avatar widget - displays the actual avatar
      child: CircleAvatar(
        // Set the size of the avatar circle - controls visual dimensions
        radius: widget.radius,
        // Set background color for fallback display - provides visual background
        backgroundColor: widget.backgroundColor ?? Colors.green,
        // Set background image if URL is valid - displays the avatar image
        backgroundImage: hasValidUrl
            ? NetworkImage(
                widget.avatarUrl!,
                headers: {
                  'Cache-Control': 'no-cache', // Prevent caching for fresh images
                  'Pragma': 'no-cache', // Additional cache prevention
                },
              )
            : null,
        // Handle image loading errors - manages failed image loads
        onBackgroundImageError: hasValidUrl
            ? (exception, stackTrace) {
                // Log error details for debugging - provides error information
                print('Error loading avatar image: $exception');
                print('Stack trace: $stackTrace');
                print('Failed URL: ${widget.avatarUrl}');
                // Update state if widget is still mounted - prevents setState on disposed widget
                if (mounted) {
                  setState(() {
                    _hasImageError = true; // Mark image as failed
                  });
                }
              }
            : null,
        // Display initials when no valid image - provides fallback content
        child: !hasValidUrl
            ? Text(
                _getInitials(widget.username), // Generate initials from username
                style: TextStyle(
                  fontSize: widget.radius * 0.6, // Scale font size to avatar size
                  color: Colors.white, // White text for contrast
                  fontWeight: FontWeight.bold, // Bold text for visibility
                ),
              )
            : null,
      ),
    );
  }
  
  // Test URL accessibility with debouncing - validates avatar URL without excessive requests
  void _testUrlAccessibility() {
    // Cancel any existing timer to debounce requests - prevents multiple simultaneous tests
    _debounceTimer?.cancel();
    // Set new timer for delayed URL test - waits before testing to avoid spam
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Only test if URL exists and is not empty - validates URL before testing
      if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
        _performUrlTest(widget.avatarUrl!); // Perform the actual URL test
      }
    });
  }

  // Perform actual URL accessibility test - makes HTTP request to validate URL
  Future<void> _performUrlTest(String url) async {
    // Skip if already testing - prevents multiple simultaneous tests
    if (_isLoading) return;
    
    // Set loading state - indicates test is in progress
    setState(() => _isLoading = true);
    
    try {
      // Log URL test attempt - provides debugging information
      print('Testing URL accessibility: $url');
      // Make HTTP HEAD request to test URL - checks if URL is accessible
      final response = await http.head(
        Uri.parse(url), // Parse URL string to URI
        headers: {
          'Cache-Control': 'no-cache', // Prevent caching
          'Pragma': 'no-cache', // Additional cache prevention
        },
      ).timeout(const Duration(seconds: 10)); // Set timeout to prevent hanging
      
      // Log response details - provides debugging information
      print('URL test response: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      
      // Check if response indicates success - validates HTTP status
      if (response.statusCode != 200) {
        // Log warning for non-200 status - indicates potential issues
        print('Warning: URL returned status code ${response.statusCode}');
        // Update error state if widget is still mounted - marks URL as invalid
        if (mounted && !_hasImageError) {
          setState(() {
            _hasImageError = true; // Mark image as failed
          });
        }
      }
    } catch (e) {
      // Log error if URL test fails - provides error information
      print('URL accessibility test failed: $e');
      // Update error state if widget is still mounted - marks URL as invalid
      if (mounted && !_hasImageError) {
        setState(() {
          _hasImageError = true; // Mark image as failed
        });
      }
    } finally {
      // Clear loading state if widget is still mounted - resets loading flag
      if (mounted) {
        setState(() => _isLoading = false); // Clear loading state
      }
    }
  }

  // Generate initials from username - creates fallback text for avatar display
  String _getInitials(String username) {
    // Return default initial if username is empty - provides fallback for empty names
    if (username.isEmpty) return 'A';
    
    // Split username into words - handles multi-word names
    final words = username.trim().split(' ');
    // If multiple words, use first letter of first two words - creates two-letter initials
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase(); // Combine first letters
    } else {
      // If single word, use first letter - creates single-letter initial
      return username[0].toUpperCase(); // Use first character
    }
  }
}
