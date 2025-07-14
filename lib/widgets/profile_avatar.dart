import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import 'package:http/http.dart' as http; // Import HTTP package for making network requests
import 'dart:async'; // Import Dart's async library for Timer functionality

class ProfileAvatar extends StatefulWidget { // Define ProfileAvatar as a stateful widget for user avatar display
  final String? avatarUrl; // Declare optional string field for the avatar image URL
  final String username; // Declare string field for the username to generate initials
  final double radius; // Declare double field for the radius of the circular avatar
  final Color? backgroundColor; // Declare optional color field for the background color
  final VoidCallback? onTap; // Declare optional callback for tap handling

  const ProfileAvatar({ // Constructor for ProfileAvatar with required and optional parameters
    Key? key, // Optional key parameter for widget identification
    required this.avatarUrl, // Initialize required avatarUrl parameter
    required this.username, // Initialize required username parameter
    this.radius = 20, // Initialize radius parameter with default value of 20
    this.backgroundColor, // Initialize optional backgroundColor parameter
    this.onTap, // Initialize optional onTap parameter
  }) : super(key: key); // Call parent constructor with key

  @override // Override the createState method from StatefulWidget
  State<ProfileAvatar> createState() => _ProfileAvatarState(); // Return the state object for this widget
} // End of ProfileAvatar class

class _ProfileAvatarState extends State<ProfileAvatar> { // Define the state class for ProfileAvatar widget
  bool _hasImageError = false; // Boolean flag to track if image loading has failed
  bool _isLoading = false; // Boolean flag to track if URL test is in progress
  String? _lastUrl; // String to store the last URL for comparison
  Timer? _debounceTimer; // Timer for debouncing URL accessibility tests

  @override // Override the initState method from State class
  void initState() { // Initialize the state when widget is created
    super.initState(); // Call parent initState method
    _lastUrl = widget.avatarUrl; // Set the last URL to the current avatar URL
  } // End of initState method

  @override // Override the didUpdateWidget method from State class
  void didUpdateWidget(ProfileAvatar oldWidget) { // Handle widget updates when properties change
    super.didUpdateWidget(oldWidget); // Call parent didUpdateWidget method
    // Reset error state if avatar URL changes
    if (oldWidget.avatarUrl != widget.avatarUrl) { // Check if avatar URL has changed
      _hasImageError = false; // Reset the image error flag
      _lastUrl = widget.avatarUrl; // Update the last URL
      _testUrlAccessibility(); // Test the new URL accessibility
    } // End of URL change check
  } // End of didUpdateWidget method

  @override // Override the dispose method from State class
  void dispose() { // Clean up resources when widget is disposed
    _debounceTimer?.cancel(); // Cancel the debounce timer if it exists
    super.dispose(); // Call parent dispose method
  } // End of dispose method

  @override // Override the build method from State class
  Widget build(BuildContext context) { // Build method that returns the widget tree for the avatar
    final hasValidUrl = widget.avatarUrl != null && // Check if avatar URL is not null
                       widget.avatarUrl!.isNotEmpty && // Check if avatar URL is not empty
                       !_hasImageError; // Check if there's no image error
    
    // Debug logging
    print('ProfileAvatar Debug:'); // Print debug header
    print('- Avatar URL: ${widget.avatarUrl}'); // Log the avatar URL
    print('- Username: ${widget.username}'); // Log the username
    print('- Has valid URL: $hasValidUrl'); // Log the URL validity status
    print('- Has image error: $_hasImageError'); // Log the image error status
    print('- Is loading: $_isLoading'); // Log the loading status
    
    return GestureDetector( // Return a GestureDetector to handle tap events
      onTap: widget.onTap, // Set the tap callback to the provided onTap function
      child: CircleAvatar( // Create a circular avatar widget
        radius: widget.radius, // Set the radius to the provided radius value
        backgroundColor: widget.backgroundColor ?? Colors.green, // Set background color to provided color or default green
        backgroundImage: hasValidUrl // Conditionally set background image based on URL validity
            ? NetworkImage( // Use NetworkImage for valid URLs
                widget.avatarUrl!, // Set the image URL (non-null assertion)
                headers: { // Set HTTP headers for the image request
                  'Cache-Control': 'no-cache', // Disable caching
                  'Pragma': 'no-cache', // Disable pragma caching
                }, // End of headers map
              ) // End of NetworkImage
            : null, // Use null if URL is not valid
        onBackgroundImageError: hasValidUrl // Set error handler only for valid URLs
            ? (exception, stackTrace) { // Define error handling callback
                print('Error loading avatar image: $exception'); // Log the exception
                print('Stack trace: $stackTrace'); // Log the stack trace
                print('Failed URL: ${widget.avatarUrl}'); // Log the failed URL
                if (mounted) { // Check if widget is still mounted
                  setState(() { // Update the state
                    _hasImageError = true; // Set image error flag to true
                  }); // End of setState
                } // End of mounted check
              } // End of error handling callback
            : null, // Use null error handler if URL is not valid
        child: !hasValidUrl // Conditionally show child widget for invalid URLs
            ? Text( // Display text for initials when no valid image URL
                _getInitials(widget.username), // Get initials from username
                style: TextStyle( // Define text style for initials
                  fontSize: widget.radius * 0.6, // Set font size relative to radius
                  color: Colors.white, // Set text color to white
                  fontWeight: FontWeight.bold, // Set font weight to bold
                ), // End of TextStyle
              ) // End of Text widget
            : null, // Show no child if valid image URL exists
      ), // End of CircleAvatar
    ); // End of GestureDetector
  } // End of build method
  
  void _testUrlAccessibility() { // Define method to test URL accessibility
    // Debounce the URL test to avoid too many requests
    _debounceTimer?.cancel(); // Cancel existing timer if it exists
    _debounceTimer = Timer(const Duration(milliseconds: 500), () { // Create new timer with 500ms delay
      if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) { // Check if avatar URL is valid
        _performUrlTest(widget.avatarUrl!); // Perform URL test with non-null assertion
      } // End of URL validity check
    }); // End of Timer callback
  } // End of _testUrlAccessibility method

  Future<void> _performUrlTest(String url) async { // Define async method to perform URL test
    if (_isLoading) return; // Return early if already loading
    
    setState(() => _isLoading = true); // Set loading state to true
    
    try { // Begin try block for URL testing
      print('Testing URL accessibility: $url'); // Log the URL being tested
      final response = await http.head( // Make HEAD request to test URL
        Uri.parse(url), // Parse the URL string to Uri
        headers: { // Set HTTP headers for the request
          'Cache-Control': 'no-cache', // Disable caching
          'Pragma': 'no-cache', // Disable pragma caching
        }, // End of headers map
      ).timeout(const Duration(seconds: 10)); // Set timeout to 10 seconds
      
      print('URL test response: ${response.statusCode}'); // Log the response status code
      print('Content-Type: ${response.headers['content-type']}'); // Log the content type
      
      if (response.statusCode != 200) { // Check if response is not OK (200)
        print('Warning: URL returned status code ${response.statusCode}'); // Log warning for non-200 status
        if (mounted && !_hasImageError) { // Check if widget is mounted and no previous error
          setState(() { // Update the state
            _hasImageError = true; // Set image error flag to true
          }); // End of setState
        } // End of mounted and error check
      } // End of status code check
    } catch (e) { // Catch any exceptions during URL testing
      print('URL accessibility test failed: $e'); // Log the exception
      if (mounted && !_hasImageError) { // Check if widget is mounted and no previous error
        setState(() { // Update the state
          _hasImageError = true; // Set image error flag to true
        }); // End of setState
      } // End of mounted and error check
    } finally { // Finally block to clean up regardless of success or failure
      if (mounted) { // Check if widget is still mounted
        setState(() => _isLoading = false); // Set loading state to false
      } // End of mounted check
    } // End of finally block
  } // End of _performUrlTest method

  String _getInitials(String username) { // Define method to generate initials from username
    if (username.isEmpty) return 'A'; // Return 'A' if username is empty
    
    final words = username.trim().split(' '); // Split username into words and trim whitespace
    if (words.length >= 2) { // Check if there are at least 2 words
      return '${words[0][0]}${words[1][0]}'.toUpperCase(); // Return first letter of first two words in uppercase
    } else { // If there's only one word
      return username[0].toUpperCase(); // Return first letter of username in uppercase
    } // End of word count check
  } // End of _getInitials method
} // End of _ProfileAvatarState class
