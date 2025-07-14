// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import authentication service to handle user operations
import '../services/auth_service.dart';
// Import follow notifier for real-time follow updates
import '../services/follow_notifier.dart';
// Import timeago library for formatting timestamps
import 'package:timeago/timeago.dart' as timeago;
// Import user profile page for navigation
import 'user_profile_page.dart';

// DiscoverPage class definition - a stateful widget for discovering and searching users
class DiscoverPage extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const DiscoverPage({Key? key}) : super(key: key);

  // Override createState method to return the state class instance
  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

// Private state class that manages the discover page's state and functionality
class _DiscoverPageState extends State<DiscoverPage> {
  // Authentication service instance for handling user operations
  final _authService = AuthService();
  // Text controller for search input
  final _searchController = TextEditingController();
  // Follow notifier instance for real-time follow updates
  final FollowNotifier _followNotifier = FollowNotifier();
  // List to store search results
  List<Map<String, dynamic>> _users = [];
  // Boolean flag to track loading state for search
  bool _isLoading = false;
  // String to store error message if any
  String? _error;

  // For suggested users
  // List to store suggested users
  List<Map<String, dynamic>> _suggestedUsers = [];
  // Boolean flag to track loading state for suggestions
  bool _isLoadingSuggestions = false;

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Load suggested users on initialization
    _loadSuggestedUsers();
  }

  // Async method to search users based on query
  Future<void> _searchUsers(String query) async {
    // Clear results if query is empty
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _error = null;
      });
      return;
    }

    try {
      // Set loading state and clear error
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user ID
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

      // Search for users in profiles table
      final response = await _authService.supabase
          .from('profiles')
          .select('''
            id,
            username,
            full_name,
            avatar_url,
            bio
          ''')
          .neq('id', currentUserId) // Exclude current user
          .or('username.ilike.%$query%,full_name.ilike.%$query%') // Search username OR full_name
          .order('username', ascending: true)
          .limit(20);

      // Update state with search results if widget is still mounted
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Log error and update state if widget is still mounted
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error searching users: ${e.toString()}';
          _isLoading = false;
          _users = [];
        });
      }
    }
  }

  // Async method to load suggested users
  Future<void> _loadSuggestedUsers() async {
    try {
      // Set loading state for suggestions
      setState(() => _isLoadingSuggestions = true);

      // Get current user ID
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        print('No current user ID');
        setState(() => _isLoadingSuggestions = false);
        return;
      }

      // Get current user's profile
      final currentProfile = await _authService.getCurrentUserProfile();
      final favoriteTeams = currentProfile?['favorite_teams'] as List<dynamic>? ?? [];

      // Initialize users list
      List<Map<String, dynamic>> users = [];

      // Try to find users with similar favorite teams if user has favorite teams
      if (favoriteTeams.isNotEmpty) {
        // Try to find users with similar favorite teams
        try {
          // Query profiles with favorite teams
          final response = await _authService.supabase
              .from('profiles')
              .select('''
                id,
                username,
                full_name,
                avatar_url,
                bio,
                favorite_teams
              ''')
              .neq('id', currentUserId)
              .not('favorite_teams', 'is', null)
              .order('username', ascending: true)
              .limit(20);

          // Filter users who have at least one common team
          final allUsers = List<Map<String, dynamic>>.from(response);
          users = allUsers.where((user) {
            final userTeams = user['favorite_teams'] as List<dynamic>? ?? [];
            return favoriteTeams.any((team) => userTeams.contains(team));
          }).take(10).toList();
        } catch (e) {
          print('Error with team-based suggestions: $e');
        }
      }

      // If no team-based suggestions, get general suggestions
      if (users.isEmpty) {
        // Query for general user suggestions
        final response = await _authService.supabase
            .from('profiles')
            .select('''
              id,
              username,
              full_name,
              avatar_url,
              bio
            ''')
            .neq('id', currentUserId)
            .order('username', ascending: true)
            .limit(10);

        users = List<Map<String, dynamic>>.from(response);
      }

      // Update state with suggested users if widget is still mounted
      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      // Log error and update loading state if widget is still mounted
      print('Error loading suggested users: $e');
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  // Method to build user card widget
  Widget _buildUserCard(Map<String, dynamic> user) {
    // Return card with user information
    return Card(
      // Card margin
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Card background color
      color: Colors.grey[700],
      // Card shape and border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[600]!, width: 1),
      ),
      // Inkwell for tap interaction
      child: InkWell(
        // Handle tap to navigate to user profile
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: user['id']),
            ),
          );
        },
        // Border radius for ink effect
        borderRadius: BorderRadius.circular(12),
        // Card content padding
        child: Padding(
          padding: const EdgeInsets.all(16),
          // Row to arrange user info and follow button
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green,
                // Set background image if avatar URL exists
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
                // Show first letter of username if no avatar
                child: user['avatar_url'] == null
                    ? Text(
                        user['username'][0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              // Spacing between avatar and info
              const SizedBox(width: 16),
              // Expanded column for user information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      user['username'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Full name if available
                    if (user['full_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['full_name'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    // Bio if available
                    if (user['bio'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['bio'],
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Spacing before member since text
                    const SizedBox(height: 8),
                    // Member since text
                    Text(
                      'User since ${DateTime.now().year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Follow/unfollow button
              FutureBuilder<bool>(
                // Check if current user is following this user
                future: _authService.isFollowing(user['id']),
                // Builder function for follow button
                builder: (context, snapshot) {
                  // Get following status from snapshot
                  final isFollowing = snapshot.data ?? false;

                  // Return follow/unfollow button
                  return ElevatedButton(
                    // Handle follow/unfollow action
                    onPressed: () async {
                      try {
                        // Perform follow/unfollow action
                        if (isFollowing) {
                          await _authService.unfollowUser(user['id']);
                        } else {
                          await _authService.followUser(user['id']);
                        }
                        
                        // Notify profile page to update counts instantly
                        _followNotifier.notifyFollowChanged();
                        
                        // Refresh UI
                        setState(() {}); // Refresh UI
                      } catch (e) {
                        // Show error message if action fails
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to ${isFollowing ? 'unfollow' : 'follow'} user',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    // Button styling based on follow state
                    style: ElevatedButton.styleFrom(
                      // Grey for unfollow, green for follow
                      backgroundColor:
                          isFollowing ? Colors.grey[600] : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                    ),
                    // Button text based on follow state
                    child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with discover page content
    return Scaffold(
      // Set dark background color
      backgroundColor: Colors.grey[800],
      // App bar with title
      appBar: AppBar(
        // Set app bar background color
        backgroundColor: Colors.grey[800],
        // App bar title
        title: const Text('Discover People',
            style: TextStyle(color: Colors.white)),
      ),
      // Body with search and results
      body: Column(
        children: [
          // Search Bar
          // Padded search input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              // Set text controller for search input
              controller: _searchController,
              // Set text color to white
              style: const TextStyle(color: Colors.white),
              // Configure search field appearance
              decoration: InputDecoration(
                // Placeholder text
                hintText: 'Search users...',
                // Placeholder text color
                hintStyle: const TextStyle(color: Colors.grey),
                // Search icon
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                // Fill background
                filled: true,
                // Background color
                fillColor: Colors.grey[700],
                // Border styling
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                // Content padding
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              // Handle search input changes
              onChanged: _searchUsers,
            ),
          ),

          // Results or Suggestions
          // Expanded area for search results or suggestions
          Expanded(
            // Conditional rendering based on search state
            child: _searchController.text.isEmpty
                // Show suggestions when search is empty
                ? _isLoadingSuggestions
                    // Show loading indicator when loading suggestions
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    // Show suggested users list
                    : ListView(
                        children: [
                          // Suggested users section header
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Suggested Users',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Map suggested users to user cards
                          ..._suggestedUsers.map(_buildUserCard),
                        ],
                      )
                // Show search results when search is active
                : _isLoading
                    // Show loading indicator when searching
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    // Show error message if error occurred
                    : _error != null
                        ? Center(
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red)))
                        // Show search results list
                        : ListView.builder(
                            // Number of search results
                            itemCount: _users.length,
                            // Builder function for each search result
                            itemBuilder: (context, index) =>
                                _buildUserCard(_users[index]),
                          ),
          ),
        ],
      ),
    );
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose search controller to prevent memory leaks
    _searchController.dispose();
    // Call parent dispose
    super.dispose();
  }
}
