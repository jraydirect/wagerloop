// Import Dart async library for stream operations - provides StreamSubscription and StreamController
import 'dart:async';
// Import Flutter foundation library for ChangeNotifier - provides state management capabilities
import 'package:flutter/foundation.dart';
// Import Flutter material library for widgets - provides StatefulWidget and State
import 'package:flutter/material.dart';
// Import Supabase Flutter SDK for real-time operations - provides real-time database subscriptions
import 'package:supabase_flutter/supabase_flutter.dart';
// Import local Supabase configuration - provides access to Supabase client
import 'supabase_config.dart';

/// Service to handle real-time profile updates across the app - manages live profile data updates
class RealTimeProfileService extends ChangeNotifier {
  // Static singleton instance of RealTimeProfileService - ensures only one instance exists
  static final RealTimeProfileService _instance = RealTimeProfileService._internal();
  // Factory constructor that returns the singleton instance - provides global access to the same instance
  factory RealTimeProfileService() => _instance;
  // Private internal constructor for singleton pattern - prevents external instantiation
  RealTimeProfileService._internal();

  // Get the Supabase client instance from configuration - provides access to real-time database
  final _supabase = SupabaseConfig.supabase;
  // Stream subscription for profile updates - manages real-time database subscription
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  
  // Map to store updated profile data with user ID as key - caches profile updates in memory
  final Map<String, Map<String, dynamic>> _profileUpdates = {};
  
  // Stream controller for broadcasting profile updates - enables multiple widgets to listen for updates
  final _profileUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Getter for profile update stream - provides access to profile update events
  Stream<Map<String, dynamic>> get profileUpdateStream => _profileUpdateController.stream;

  /// Initialize real-time profile update listener - sets up database subscription for profile changes
  void initializeProfileUpdates() {
    try {
      // Cancel existing subscription if any - prevents multiple subscriptions
      _profileSubscription?.cancel();
      
      // Listen to profile changes in real-time - subscribes to database changes
      _profileSubscription = _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .listen(
            // Handle incoming profile updates - processes real-time database changes
            (List<Map<String, dynamic>> data) {
              _handleProfileUpdates(data);
            },
            // Handle subscription errors - manages subscription failures
            onError: (error) {
              // Print error message - logs subscription errors for debugging
              print('Profile update subscription error: $error');
              // Retry after delay - attempts to reconnect after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                // Check if still mounted before retrying - prevents retry if service is disposed
                if (mounted) {
                  initializeProfileUpdates();
                }
              });
            },
          );
      
      // Print success message - logs successful subscription initialization
      print('Real-time profile updates initialized');
    } catch (e) {
      // Print error if initialization fails - logs initialization errors
      print('Error initializing profile updates: $e');
    }
  }

  /// Handle incoming profile updates - processes real-time profile changes from database
  void _handleProfileUpdates(List<Map<String, dynamic>> profiles) {
    // Loop through all updated profiles - processes each profile update
    for (final profile in profiles) {
      // Extract user ID from profile - gets the unique user identifier
      final userId = profile['id'];
      // Check if user ID exists - validates profile data
      if (userId != null) {
        // Store the updated profile data in cache - saves profile to memory cache
        _profileUpdates[userId] = profile;
        
        // Emit the update through stream controller - broadcasts update to all listeners
        _profileUpdateController.add({
          'type': 'profile_update',
          'user_id': userId,
          'profile': profile,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Print debug information - logs profile update details
        print('Profile updated for user $userId: ${profile['username']}');
        print('New avatar URL: ${profile['avatar_url']}');
      }
    }
    
    // Notify all listeners about the update - triggers UI updates in listening widgets
    notifyListeners();
  }

  /// Get the latest profile data for a user - retrieves cached profile information
  Map<String, dynamic>? getLatestProfile(String userId) {
    // Return cached profile data for the user - provides fast access to profile data
    return _profileUpdates[userId];
  }

  /// Check if a user's profile has been recently updated - determines if profile is fresh
  bool hasRecentUpdate(String userId, {Duration? since}) {
    // Get cached profile data for the user - retrieves profile from cache
    final profile = _profileUpdates[userId];
    // Return false if no profile data exists - handles missing profile data
    if (profile == null) return false;
    
    // Parse the update timestamp - converts string timestamp to DateTime
    final updateTime = DateTime.tryParse(profile['updated_at'] ?? '');
    // Return false if timestamp is invalid - handles invalid timestamp data
    if (updateTime == null) return false;
    
    // Set threshold for recent updates (default 5 minutes) - defines what "recent" means
    final threshold = since ?? const Duration(minutes: 5);
    // Return true if update is within threshold - determines if update is recent
    return DateTime.now().difference(updateTime) < threshold;
  }

  /// Manually trigger a profile refresh for immediate updates - forces profile data refresh
  Future<void> refreshProfile(String userId) async {
    try {
      // Fetch latest profile data from database - retrieves fresh data from database
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Update cached profile data - stores fresh data in memory cache
      _profileUpdates[userId] = profile;
      
      // Emit manual refresh event - broadcasts manual refresh to listeners
      _profileUpdateController.add({
        'type': 'manual_refresh',
        'user_id': userId,
        'profile': profile,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Notify all listeners - triggers UI updates in listening widgets
      notifyListeners();
    } catch (e) {
      // Print error if profile refresh fails - logs refresh errors
      print('Error refreshing profile for $userId: $e');
    }
  }

  /// Clear cached profile data - removes profile data from memory cache
  void clearProfileCache([String? userId]) {
    // If specific user ID provided, remove only that user's data - selective cache clearing
    if (userId != null) {
      _profileUpdates.remove(userId);
    } else {
      // Otherwise clear all cached data - full cache clearing
      _profileUpdates.clear();
    }
    // Notify all listeners about cache clearing - triggers UI updates
    notifyListeners();
  }

  /// Check if mounted (for ChangeNotifier) - determines if service has active listeners
  bool get mounted => hasListeners;

  /// Dispose of resources - cleans up subscriptions and controllers
  @override
  void dispose() {
    // Cancel profile subscription - stops real-time database subscription
    _profileSubscription?.cancel();
    // Close stream controller - stops broadcasting profile updates
    _profileUpdateController.close();
    // Call parent dispose method - ensures proper cleanup
    super.dispose();
  }
}

/// Mixin to easily integrate real-time profile updates into widgets - provides easy widget integration
mixin RealTimeProfileMixin<T extends StatefulWidget> on State<T> {
  // Stream subscription for profile updates - manages widget-specific profile subscription
  StreamSubscription<Map<String, dynamic>>? _profileUpdateSubscription;
  // Instance of real-time profile service - provides access to profile service
  final _profileService = RealTimeProfileService();

  /// Override this method to handle profile updates - defines how widget responds to updates
  void onProfileUpdate(Map<String, dynamic> update);

  @override
  void initState() {
    // Call parent initState - ensures proper widget initialization
    super.initState();
    // Initialize profile listener - sets up profile update listening
    _initializeProfileListener();
  }

  // Initialize profile update listener - sets up widget-specific profile subscription
  void _initializeProfileListener() {
    // Subscribe to profile update stream - listens for profile changes
    _profileUpdateSubscription = _profileService.profileUpdateStream.listen(
      // Handle profile updates - processes profile update events
      onProfileUpdate,
      // Handle listener errors - manages subscription errors
      onError: (error) {
        // Print error message - logs listener errors for debugging
        print('Profile update listener error: $error');
      },
    );
  }

  @override
  void dispose() {
    // Cancel profile update subscription - stops listening for profile updates
    _profileUpdateSubscription?.cancel();
    // Call parent dispose method - ensures proper widget cleanup
    super.dispose();
  }
}
