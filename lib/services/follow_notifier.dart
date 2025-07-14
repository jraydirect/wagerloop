import 'package:flutter/foundation.dart'; // Import Flutter foundation library for ChangeNotifier functionality

class FollowNotifier extends ChangeNotifier { // Define FollowNotifier as a singleton class extending ChangeNotifier for state management
  static final FollowNotifier _instance = FollowNotifier._internal(); // Create a static instance of FollowNotifier using the private constructor
  factory FollowNotifier() => _instance; // Factory constructor that returns the singleton instance
  FollowNotifier._internal(); // Private constructor to prevent external instantiation

  void notifyFollowChanged() { // Define method to notify listeners when follow status changes
    notifyListeners(); // Notify all listeners that the follow state has changed
  } // End of notifyFollowChanged method
} // End of FollowNotifier class
