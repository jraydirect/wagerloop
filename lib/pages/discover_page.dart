import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/follow_notifier.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'user_profile_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final FollowNotifier _followNotifier = FollowNotifier();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _error;

  // For suggested users
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _error = null;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw 'User not authenticated';
      }

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

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching users: ${e.toString()}';
          _isLoading = false;
          _users = [];
        });
      }
    }
  }

  Future<void> _loadSuggestedUsers() async {
    try {
      setState(() => _isLoadingSuggestions = true);

      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _isLoadingSuggestions = false);
        return;
      }

      // Get current user's profile
      final currentProfile = await _authService.getCurrentUserProfile();
      final favoriteTeams = currentProfile?['favorite_teams'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> users = [];

      if (favoriteTeams.isNotEmpty) {
        // Try to find users with similar favorite teams
        try {
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
        }
      }

      // If no team-based suggestions, get general suggestions
      if (users.isEmpty) {
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

      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[600]!, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: user['id']),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.green,
                backgroundImage: user['avatar_url'] != null
                    ? NetworkImage(user['avatar_url'])
                    : null,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (user['full_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['full_name'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (user['bio'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user['bio'],
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'User since ${DateTime.now().year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FutureBuilder<bool>(
                future: _authService.isFollowing(user['id']),
                builder: (context, snapshot) {
                  final isFollowing = snapshot.data ?? false;

                  return ElevatedButton(
                    onPressed: () async {
                      try {
                        if (isFollowing) {
                          await _authService.unfollowUser(user['id']);
                        } else {
                          await _authService.followUser(user['id']);
                        }
                        
                        // Notify profile page to update counts instantly
                        _followNotifier.notifyFollowChanged();
                        
                        setState(() {}); // Refresh UI
                      } catch (e) {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isFollowing ? Colors.grey[600] : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 36),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('Discover People',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),

          // Results or Suggestions
          Expanded(
            child: _searchController.text.isEmpty
                ? _isLoadingSuggestions
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : ListView(
                        children: [
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
                          ..._suggestedUsers.map(_buildUserCard),
                        ],
                      )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : _error != null
                        ? Center(
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red)))
                        : ListView.builder(
                            itemCount: _users.length,
                            itemBuilder: (context, index) =>
                                _buildUserCard(_users[index]),
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
