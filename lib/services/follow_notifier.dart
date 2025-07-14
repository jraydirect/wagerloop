import 'package:flutter/foundation.dart';

class FollowNotifier extends ChangeNotifier {
  static final FollowNotifier _instance = FollowNotifier._internal();
  factory FollowNotifier() => _instance;
  FollowNotifier._internal();

  void notifyFollowChanged() {
    notifyListeners();
  }
}
