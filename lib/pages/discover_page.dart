import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _authService = AuthService();
  final _searchController = TextEditingController();
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
      setState(() => _users = []);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await _authService.supabase
          .from('profiles')
          .select('''
            id,
            username,
            full_name,
            avatar_url,
            bio,
            followers_count,
            following_count
          ''')
          .ilike('username', '%$query%')
          .order('followers_count', ascending: false)
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
          _error = 'Error searching users';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSuggestedUsers() async {
    try {
      setState(() => _isLoadingSuggestions = true);

      // Get current user's favorite teams
      final currentProfile = await _authService.getCurrentUserProfile();
      final favoriteTeams =
          currentProfile?['favorite_teams'] as List<dynamic>? ?? [];

      // Find users who follow the same teams
      final response = await _authService.supabase
          .from('profiles')
          .select('''
            id,
            username,
            full_name,
            avatar_url,
            bio,
            followers_count,
            following_count,
            favorite_teams
          ''')
          .neq('id', _authService.currentUser?.id)
          .overlaps('favorite_teams', favoriteTeams)
          .order('followers_count', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _suggestedUsers = List<Map<String, dynamic>>.from(response);
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('Error loading suggested users: $e');
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
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
                  Row(
                    children: [
                      Text(
                        '${user['followers_count'] ?? 0} followers',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${user['following_count'] ?? 0} following',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
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
                      setState(() {}); // Refresh UI
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to ${isFollowing ? 'unfollow' : 'follow'} user',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFollowing ? Colors.grey[800] : Colors.blue,
                    minimumSize: const Size(100, 36),
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                fillColor: Colors.grey[900],
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
                    ? const Center(child: CircularProgressIndicator())
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
                    ? const Center(child: CircularProgressIndicator())
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
