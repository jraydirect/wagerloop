import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/follow_notifier.dart';
import '../widgets/profile_avatar.dart';

class FollowersListPage extends StatefulWidget {
  final String userId;
  final bool isFollowers; // true for followers, false for following

  const FollowersListPage({
    Key? key,
    required this.userId,
    required this.isFollowers,
  }) : super(key: key);

  @override
  _FollowersListPageState createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  final _authService = AuthService();
  final FollowNotifier _followNotifier = FollowNotifier();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = widget.isFollowers
          ? await _authService.getFollowers(widget.userId)
          : await _authService.getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load users';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollowAction(
      String userId, bool currentlyFollowing) async {
    try {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to ${currentlyFollowing ? 'unfollow' : 'follow'} user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: Text(
          widget.isFollowers ? 'Followers' : 'Following',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        widget.isFollowers
                            ? 'No followers yet'
                            : 'Not following anyone',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return FutureBuilder<bool>(
                          future: _authService.isFollowing(user['id']),
                          builder: (context, snapshot) {
                            final isFollowing = snapshot.data ?? false;

                            return ListTile(
                              leading: ProfileAvatar(
                                avatarUrl: user['avatar_url'],
                                username: user['username'] ?? 'Anonymous',
                                radius: 20,
                                backgroundColor: Colors.blue,
                              ),
                              title: Text(
                                user['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                user['full_name'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing:
                                  user['id'] != _authService.currentUser?.id
                                      ? ElevatedButton(
                                          onPressed: () => _handleFollowAction(
                                            user['id'],
                                            isFollowing,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFollowing
                                                ? Colors.grey[800]
                                                : Colors.blue,
                                            minimumSize: const Size(100, 36),
                                          ),
                                          child: Text(
                                            isFollowing ? 'Unfollow' : 'Follow',
                                          ),
                                        )
                                      : null,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
