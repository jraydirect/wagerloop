import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Service to handle real-time profile updates across the app
class RealTimeProfileService extends ChangeNotifier {
  static final RealTimeProfileService _instance = RealTimeProfileService._internal();
  factory RealTimeProfileService() => _instance;
  RealTimeProfileService._internal();

  final _supabase = SupabaseConfig.supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;
  
  // Map to store updated profile data
  final Map<String, Map<String, dynamic>> _profileUpdates = {};
  
  // Stream controller for profile updates
  final _profileUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Getter for profile update stream
  Stream<Map<String, dynamic>> get profileUpdateStream => _profileUpdateController.stream;

  /// Initialize real-time profile update listener
  void initializeProfileUpdates() {
    try {
      _profileSubscription?.cancel();
      
      // Listen to profile changes in real-time
      _profileSubscription = _supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .listen(
            (List<Map<String, dynamic>> data) {
              _handleProfileUpdates(data);
            },
            onError: (error) {
              print('Profile update subscription error: $error');
              // Retry after delay
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  initializeProfileUpdates();
                }
              });
            },
          );
      
      print('Real-time profile updates initialized');
    } catch (e) {
      print('Error initializing profile updates: $e');
    }
  }

  /// Handle incoming profile updates
  void _handleProfileUpdates(List<Map<String, dynamic>> profiles) {
    for (final profile in profiles) {
      final userId = profile['id'];
      if (userId != null) {
        // Store the updated profile data
        _profileUpdates[userId] = profile;
        
        // Emit the update
        _profileUpdateController.add({
          'type': 'profile_update',
          'user_id': userId,
          'profile': profile,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        print('Profile updated for user $userId: ${profile['username']}');
        print('New avatar URL: ${profile['avatar_url']}');
      }
    }
    
    // Notify listeners
    notifyListeners();
  }

  /// Get the latest profile data for a user
  Map<String, dynamic>? getLatestProfile(String userId) {
    return _profileUpdates[userId];
  }

  /// Check if a user's profile has been recently updated
  bool hasRecentUpdate(String userId, {Duration? since}) {
    final profile = _profileUpdates[userId];
    if (profile == null) return false;
    
    final updateTime = DateTime.tryParse(profile['updated_at'] ?? '');
    if (updateTime == null) return false;
    
    final threshold = since ?? const Duration(minutes: 5);
    return DateTime.now().difference(updateTime) < threshold;
  }

  /// Manually trigger a profile refresh for immediate updates
  Future<void> refreshProfile(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      _profileUpdates[userId] = profile;
      
      _profileUpdateController.add({
        'type': 'manual_refresh',
        'user_id': userId,
        'profile': profile,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      notifyListeners();
    } catch (e) {
      print('Error refreshing profile for $userId: $e');
    }
  }

  /// Clear cached profile data
  void clearProfileCache([String? userId]) {
    if (userId != null) {
      _profileUpdates.remove(userId);
    } else {
      _profileUpdates.clear();
    }
    notifyListeners();
  }

  /// Check if mounted (for ChangeNotifier)
  bool get mounted => hasListeners;

  /// Dispose of resources
  @override
  void dispose() {
    _profileSubscription?.cancel();
    _profileUpdateController.close();
    super.dispose();
  }
}

/// Mixin to easily integrate real-time profile updates into widgets
mixin RealTimeProfileMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<Map<String, dynamic>>? _profileUpdateSubscription;
  final _profileService = RealTimeProfileService();

  /// Override this method to handle profile updates
  void onProfileUpdate(Map<String, dynamic> update);

  @override
  void initState() {
    super.initState();
    _initializeProfileListener();
  }

  void _initializeProfileListener() {
    _profileUpdateSubscription = _profileService.profileUpdateStream.listen(
      onProfileUpdate,
      onError: (error) {
        print('Profile update listener error: $error');
      },
    );
  }

  @override
  void dispose() {
    _profileUpdateSubscription?.cancel();
    super.dispose();
  }
}
