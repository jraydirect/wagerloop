import 'dart:async'; // Import Dart's async library for StreamSubscription and stream handling
import 'package:flutter/foundation.dart'; // Import Flutter foundation library for ChangeNotifier functionality
import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for real-time database operations
import 'supabase_config.dart'; // Import local Supabase configuration file

/// Service to handle real-time profile updates across the app
class RealTimeProfileService extends ChangeNotifier { // Define RealTimeProfileService as a singleton service extending ChangeNotifier for state management
  static final RealTimeProfileService _instance = RealTimeProfileService._internal(); // Create a static instance using the private constructor
  factory RealTimeProfileService() => _instance; // Factory constructor that returns the singleton instance
  RealTimeProfileService._internal(); // Private constructor to prevent external instantiation

  final _supabase = SupabaseConfig.supabase; // Get Supabase client instance from configuration
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription; // Declare optional stream subscription for profile updates
  
  // Map to store updated profile data
  final Map<String, Map<String, dynamic>> _profileUpdates = {}; // Map to cache profile updates by user ID
  
  // Stream controller for profile updates
  final _profileUpdateController = StreamController<Map<String, dynamic>>.broadcast(); // Broadcast stream controller for profile updates
  
  // Getter for profile update stream
  Stream<Map<String, dynamic>> get profileUpdateStream => _profileUpdateController.stream; // Getter to expose the profile update stream

  /// Initialize real-time profile update listener
  void initializeProfileUpdates() { // Define method to set up real-time profile update listening
    try { // Begin try block for error handling
      _profileSubscription?.cancel(); // Cancel existing subscription if it exists
      
      // Listen to profile changes in real-time
      _profileSubscription = _supabase // Set up new subscription to profiles table
          .from('profiles') // Target the profiles table
          .stream(primaryKey: ['id']) // Create a stream with id as primary key
          .listen( // Listen to the stream
            (List<Map<String, dynamic>> data) { // Handle incoming profile data
              _handleProfileUpdates(data); // Process the profile updates
            }, // End of data handler
            onError: (error) { // Handle stream errors
              print('Profile update subscription error: $error'); // Log the error
              // Retry after delay
              Future.delayed(const Duration(seconds: 5), () { // Wait 5 seconds before retry
                if (mounted) { // Check if service is still mounted
                  initializeProfileUpdates(); // Reinitialize the subscription
                } // End of mounted check
              }); // End of delayed retry
            }, // End of error handler
          ); // End of stream listen
      
      print('Real-time profile updates initialized'); // Log successful initialization
    } catch (e) { // Catch any exceptions during initialization
      print('Error initializing profile updates: $e'); // Log the initialization error
    } // End of try-catch block
  } // End of initializeProfileUpdates method

  /// Handle incoming profile updates
  void _handleProfileUpdates(List<Map<String, dynamic>> profiles) { // Define method to process incoming profile updates
    for (final profile in profiles) { // Iterate through each profile in the update list
      final userId = profile['id']; // Extract the user ID from the profile
      if (userId != null) { // Check if user ID exists
        // Store the updated profile data
        _profileUpdates[userId] = profile; // Cache the profile data in the map
        
        // Emit the update
        _profileUpdateController.add({ // Add update event to the stream
          'type': 'profile_update', // Set event type to profile update
          'user_id': userId, // Include the user ID
          'profile': profile, // Include the complete profile data
          'timestamp': DateTime.now().toIso8601String(), // Add current timestamp
        }); // End of stream event
        
        print('Profile updated for user $userId: ${profile['username']}'); // Log the profile update
        print('New avatar URL: ${profile['avatar_url']}'); // Log the new avatar URL
      } // End of user ID null check
    } // End of profiles iteration
    
    // Notify listeners
    notifyListeners(); // Notify all listeners that the state has changed
  } // End of _handleProfileUpdates method

  /// Get the latest profile data for a user
  Map<String, dynamic>? getLatestProfile(String userId) { // Define method to retrieve cached profile data for a user
    return _profileUpdates[userId]; // Return the cached profile data or null if not found
  } // End of getLatestProfile method

  /// Check if a user's profile has been recently updated
  bool hasRecentUpdate(String userId, {Duration? since}) { // Define method to check if profile was recently updated
    final profile = _profileUpdates[userId]; // Get the cached profile data
    if (profile == null) return false; // Return false if no profile data exists
    
    final updateTime = DateTime.tryParse(profile['updated_at'] ?? ''); // Parse the update timestamp
    if (updateTime == null) return false; // Return false if timestamp is invalid
    
    final threshold = since ?? const Duration(minutes: 5); // Set threshold to provided duration or default 5 minutes
    return DateTime.now().difference(updateTime) < threshold; // Return true if update is within threshold
  } // End of hasRecentUpdate method

  /// Manually trigger a profile refresh for immediate updates
  Future<void> refreshProfile(String userId) async { // Define async method to manually refresh a user's profile
    try { // Begin try block for error handling
      final profile = await _supabase // Fetch profile data from database
          .from('profiles') // Query the profiles table
          .select() // Select all columns
          .eq('id', userId) // Filter by user ID
          .single(); // Get single result
      
      _profileUpdates[userId] = profile; // Cache the refreshed profile data
      
      _profileUpdateController.add({ // Add manual refresh event to the stream
        'type': 'manual_refresh', // Set event type to manual refresh
        'user_id': userId, // Include the user ID
        'profile': profile, // Include the complete profile data
        'timestamp': DateTime.now().toIso8601String(), // Add current timestamp
      }); // End of stream event
      
      notifyListeners(); // Notify all listeners that the state has changed
    } catch (e) { // Catch any exceptions during profile refresh
      print('Error refreshing profile for $userId: $e'); // Log the refresh error
    } // End of try-catch block
  } // End of refreshProfile method

  /// Clear cached profile data
  void clearProfileCache([String? userId]) { // Define method to clear profile cache with optional user ID
    if (userId != null) { // Check if specific user ID is provided
      _profileUpdates.remove(userId); // Remove specific user's profile from cache
    } else { // If no user ID provided
      _profileUpdates.clear(); // Clear all cached profiles
    } // End of user ID check
    notifyListeners(); // Notify all listeners that the state has changed
  } // End of clearProfileCache method

  /// Check if mounted (for ChangeNotifier)
  bool get mounted => hasListeners; // Define getter to check if service has listeners (is mounted)

  /// Dispose of resources
  @override // Override the dispose method from ChangeNotifier
  void dispose() { // Define method to clean up resources when service is disposed
    _profileSubscription?.cancel(); // Cancel the profile subscription if it exists
    _profileUpdateController.close(); // Close the stream controller
    super.dispose(); // Call parent dispose method
  } // End of dispose method
} // End of RealTimeProfileService class

/// Mixin to easily integrate real-time profile updates into widgets
mixin RealTimeProfileMixin<T extends StatefulWidget> on State<T> { // Define mixin for easy integration of real-time profile updates
  StreamSubscription<Map<String, dynamic>>? _profileUpdateSubscription; // Declare optional stream subscription for profile updates
  final _profileService = RealTimeProfileService(); // Get instance of the profile service

  /// Override this method to handle profile updates
  void onProfileUpdate(Map<String, dynamic> update); // Define abstract method that must be implemented by mixing widgets

  @override // Override the initState method from State class
  void initState() { // Initialize the state when widget is created
    super.initState(); // Call parent initState method
    _initializeProfileListener(); // Set up the profile update listener
  } // End of initState method

  void _initializeProfileListener() { // Define method to set up profile update listener
    _profileUpdateSubscription = _profileService.profileUpdateStream.listen( // Subscribe to profile update stream
      onProfileUpdate, // Handle updates with the abstract method
      onError: (error) { // Handle stream errors
        print('Profile update listener error: $error'); // Log the listener error
      }, // End of error handler
    ); // End of stream subscription
  } // End of _initializeProfileListener method

  @override // Override the dispose method from State class
  void dispose() { // Clean up resources when widget is disposed
    _profileUpdateSubscription?.cancel(); // Cancel the profile update subscription if it exists
    super.dispose(); // Call parent dispose method
  } // End of dispose method
} // End of RealTimeProfileMixin
