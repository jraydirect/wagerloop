// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import authentication service to handle user operations
import '../services/auth_service.dart';
// Import follow notifier for real-time follow updates
import '../services/follow_notifier.dart';
// Import custom profile avatar widget
import '../widgets/profile_avatar.dart';
// Import user profile page for navigation
import 'user_profile_page.dart';

// FollowersListPage class definition - a stateful widget for displaying followers/following lists
class FollowersListPage extends StatefulWidget {
  // User ID whose followers/following to display
  final String userId;
  // Boolean flag to determine if showing followers (true) or following (false)
  final bool isFollowers; // true for followers, false for following

  // Constructor with required parameters
  const FollowersListPage({
    Key? key,
    required this.userId,
    required this.isFollowers,
  }) : super(key: key);

  // Override createState method to return the state class instance
  @override
  _FollowersListPageState createState() => _FollowersListPageState();
}

// Private state class that manages the followers list page's state and functionality
class _FollowersListPageState extends State<FollowersListPage> {
  // Authentication service instance for handling user operations
  final _authService = AuthService();
  // Follow notifier instance for real-time follow updates
  final FollowNotifier _followNotifier = FollowNotifier();
  // List to store user data
  List<Map<String, dynamic>> _users = [];
  // Boolean flag to track loading state
  bool _isLoading = true;
  // String to store error message if any
  String? _error;

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Load users on initialization
    _loadUsers();
  }

  // Async method to load users based on followers/following flag
  Future<void> _loadUsers() async {
    try {
      // Set loading state and clear error
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get users based on whether showing followers or following
      final users = widget.isFollowers
          ? await _authService.getFollowers(widget.userId)
          : await _authService.getFollowing(widget.userId);

      // Update state with loaded users if widget is still mounted
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error if widget is still mounted
      if (mounted) {
        setState(() {
          _error = 'Failed to load users';
          _isLoading = false;
        });
      }
    }
  }

  // Async method to handle follow/unfollow actions
  Future<void> _handleFollowAction(
      String userId, bool currentlyFollowing) async {
    try {
      // Perform follow/unfollow action based on current state
      if (currentlyFollowing) {
        await _authService.unfollowUser(userId);
      } else {
        await _authService.followUser(userId);
      }

      // Notify profile page to update counts instantly
      _followNotifier.notifyFollowChanged();

      // Refresh the list
      await _loadUsers();
    } catch (e) {
      // Show error snackbar if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to ${currentlyFollowing ? 'unfollow' : 'follow'} user')),
        );
      }
    }
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with followers/following list
    return Scaffold(
      // Set dark background color
      backgroundColor: Colors.grey[800],
      // App bar with title and back button
      appBar: AppBar(
        // Set app bar background color
        backgroundColor: Colors.grey[800],
        // Set title based on followers/following flag
        title: Text(
          widget.isFollowers ? 'Followers' : 'Following',
          style: const TextStyle(color: Colors.white),
        ),
        // Back button to navigate back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Body with conditional rendering based on loading state
      body: _isLoading
          // Show loading indicator when loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          // Show error message if error occurred
          : _error != null
              ? Center(
                  child: Column(
                    // Center error message and retry button
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Error message text
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      // Retry button
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              // Show empty state message if no users
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        // Different message based on followers/following
                        widget.isFollowers
                            ? 'No followers yet'
                            : 'Not following anyone',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  // Show users list if users exist
                  : ListView.builder(
                      // Number of users in the list
                      itemCount: _users.length,
                      // Builder function for each user item
                      itemBuilder: (context, index) {
                        // Get user data at current index
                        final user = _users[index];
                        // Future builder to check if current user is following this user
                        return FutureBuilder<bool>(
                          // Check if current user is following this user
                          future: _authService.isFollowing(user['id']),
                          // Builder function for follow status
                          builder: (context, snapshot) {
                            // Get following status from snapshot
                            final isFollowing = snapshot.data ?? false;

                            // Return list tile for user
                            return ListTile(
                              // Profile avatar as leading widget
                              leading: ProfileAvatar(
                                // User's avatar URL
                                avatarUrl: user['avatar_url'],
                                // User's username or fallback
                                username: user['username'] ?? 'Anonymous',
                                // Avatar radius
                                radius: 20,
                                // Background color for avatar
                                backgroundColor: Colors.blue,
                                // Handle tap to navigate to user profile
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfilePage(userId: user['id']),
                                    ),
                                  );
                                },
                              ),
                              // Username as title
                              title: Text(
                                user['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Full name as subtitle
                              subtitle: Text(
                                user['full_name'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              // Follow/unfollow button as trailing widget (if not current user)
                              trailing:
                                  user['id'] != _authService.currentUser?.id
                                      ? ElevatedButton(
                                          // Handle follow/unfollow action
                                          onPressed: () => _handleFollowAction(
                                            user['id'],
                                            isFollowing,
                                          ),
                                          // Button styling based on follow state
                                          style: ElevatedButton.styleFrom(
                                            // Grey for unfollow, blue for follow
                                            backgroundColor: isFollowing
                                                ? Colors.grey[800]
                                                : Colors.blue,
                                            // Minimum button size
                                            minimumSize: const Size(100, 36),
                                          ),
                                          // Button text based on follow state
                                          child: Text(
                                            isFollowing ? 'Unfollow' : 'Follow',
                                          ),
                                        )
                                      // No trailing widget for current user
                                      : null,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
