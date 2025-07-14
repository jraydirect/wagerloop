// Import Flutter foundation library for ChangeNotifier functionality - provides state management capabilities
import 'package:flutter/foundation.dart';

// Class that extends ChangeNotifier to handle follow state changes - manages follow/unfollow state across the app
class FollowNotifier extends ChangeNotifier {
  // Static singleton instance of FollowNotifier - ensures only one instance exists throughout the app
  static final FollowNotifier _instance = FollowNotifier._internal();
  // Factory constructor that returns the singleton instance - provides global access to the same instance
  factory FollowNotifier() => _instance;
  // Private internal constructor for singleton pattern - prevents external instantiation
  FollowNotifier._internal();

  // Method to notify listeners when follow state changes - called when user follows or unfollows someone
  void notifyFollowChanged() {
    // Notify all registered listeners about the state change - triggers UI updates in widgets that are listening
    notifyListeners();
  }
}
