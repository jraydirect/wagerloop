import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';
import '../services/follow_notifier.dart';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/picks_display_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'followers_list_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _authService = AuthService();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  bool _isLoading = true;
  String? _error;

  // User data
  Map<String, dynamic>? _userData;
  
  // Follower counts
  int _followersCount = 0;
  int _followingCount = 0;
  final FollowNotifier _followNotifier = FollowNotifier();

  // Posts data
  List<dynamic> _userPosts = []; // Can contain both Post and PickPost objects
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserPosts();
    _loadFollowerCounts();
    
    // Listen for follow events to update counts instantly
    _followNotifier.addListener(_onFollowChanged);
  }

  void _onFollowChanged() {
    // Reload follower counts when someone is followed/unfollowed
    _loadFollowerCounts();
  }

  @override
  void didUpdateWidget(UserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // User ID changed, reload data
      _loadUserProfile();
      _loadUserPosts();
      _loadFollowerCounts();
    }
  }

  Future<void> _loadFollowerCounts() async {
    try {
      // Load followers and following counts for the target user
      final followers = await _authService.getFollowers(widget.userId);
      final following = await _authService.getFollowing(widget.userId);

      setState(() {
        _followersCount = followers.length;
        _followingCount = following.length;
      });
    } catch (e) {
      print('Error loading follower counts: $e');
      // Keep counts as 0 if there's an error
    }
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadUserProfile(),
      _loadUserPosts(),
      _loadFollowerCounts(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the target user's profile
      final response = await _authService.supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _socialFeedService.fetchUserPosts(widget.userId);
      
      // Update like and repost status for current user
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        for (final post in posts) {
          final postId = post is Post ? post.id : (post as PickPost).id;
          try {
            // Check if user liked this post
            final likeExists = await _authService.supabase
                .from('likes')
                .select()
                .eq('post_id', postId)
                .eq('user_id', currentUserId)
                .maybeSingle();
            
            if (post is Post) {
              post.isLiked = likeExists != null;
            } else if (post is PickPost) {
              post.isLiked = likeExists != null;
            }

            // Check if user reposted this post
            final repostExists = await _authService.supabase
                .from('reposts')
                .select()
                .eq('post_id', postId)
                .eq('user_id', currentUserId)
                .maybeSingle();
            
            if (post is Post) {
              post.isReposted = repostExists != null;
            } else if (post is PickPost) {
              post.isReposted = repostExists != null;
            }
          } catch (e) {
            print('Error fetching post stats for $postId: $e');
          }
        }
      }
      
      if (mounted) {
        setState(() => _userPosts = posts);
      }
    } catch (e) {
      print('Error loading user posts: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  Future<void> _toggleLike(dynamic post) async {
    // Optimistically update UI
    setState(() {
      if (post is Post) {
        post.isLiked = !post.isLiked;
        post.likes += post.isLiked ? 1 : -1;
      } else if (post is PickPost) {
        post.isLiked = !post.isLiked;
        post.likes += post.isLiked ? 1 : -1;
      }
    });

    try {
      final postId = post is Post ? post.id : (post as PickPost).id;
      await _socialFeedService.toggleLike(postId);
    } catch (e) {
      // Revert on error
      setState(() {
        if (post is Post) {
          post.isLiked = !post.isLiked;
          post.likes += post.isLiked ? 1 : -1;
        } else if (post is PickPost) {
          post.isLiked = !post.isLiked;
          post.likes += post.isLiked ? 1 : -1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like. Please try again.')),
      );
      print('Error toggling like: $e');
    }
  }

  Future<void> _toggleRepost(dynamic post) async {
    // Optimistically update UI
    setState(() {
      if (post is Post) {
        post.isReposted = !post.isReposted;
        post.reposts += post.isReposted ? 1 : -1;
      } else if (post is PickPost) {
        post.isReposted = !post.isReposted;
        post.reposts += post.isReposted ? 1 : -1;
      }
    });

    try {
      final postId = post is Post ? post.id : (post as PickPost).id;
      await _socialFeedService.toggleRepost(postId);
    } catch (e) {
      // Revert on error
      setState(() {
        if (post is Post) {
          post.isReposted = !post.isReposted;
          post.reposts += post.isReposted ? 1 : -1;
        } else if (post is PickPost) {
          post.isReposted = !post.isReposted;
          post.reposts += post.isReposted ? 1 : -1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update repost. Please try again.')),
      );
      print('Error toggling repost: $e');
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList() {
    final favoriteTeams = _userData?['favorite_teams'] as List<dynamic>? ?? [];
    
    if (favoriteTeams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorite Teams',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: favoriteTeams.map<Widget>((team) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                team.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Text(
          'No posts yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        
        // Extract common properties
        final content = post is Post ? post.content : (post as PickPost).content;
        final timestamp = post is Post ? post.timestamp : (post as PickPost).timestamp;
        final likes = post is Post ? post.likes : (post as PickPost).likes;
        final comments = post is Post ? post.comments : (post as PickPost).comments;
        final reposts = post is Post ? post.reposts : (post as PickPost).reposts;
        final isLiked = post is Post ? post.isLiked : (post as PickPost).isLiked;
        final isReposted = post is Post ? post.isReposted : (post as PickPost).isReposted;
        
        return Card(
          color: Colors.grey[700],
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(color: Colors.white),
                ),
                
                // Show picks if this is a PickPost
                if (post is PickPost && post.hasPicks) ...[
                  const SizedBox(height: 12),
                  PicksDisplayWidget(
                    picks: post.picks,
                    showParlayBadge: true,
                    compact: true, // Use compact version for profile page
                  ),
                ],
                
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      timeago.format(timestamp, locale: 'en'),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      label: likes.toString(),
                      onTap: () => _toggleLike(post),
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    _buildActionButton(
                      icon: Icons.comment_outlined,
                      label: comments.length.toString(),
                      onTap: () {
                        // TODO: Implement comment functionality
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.repeat,
                      label: reposts.toString(),
                      onTap: () => _toggleRepost(post),
                      color: isReposted ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const Text('Profile', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const Text('Profile', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = _authService.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: Text(
          _userData?['username'] ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        avatarUrl: _userData?['avatar_url'],
                        username: _userData?['username'] ?? 'Anonymous',
                        radius: 50,
                        backgroundColor: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData?['username'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userData?['full_name'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _userData?['full_name'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (_userData?['bio'] != null && _userData?['bio'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _userData?['bio'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Follow/Unfollow Button (only if not own profile)
                if (!isOwnProfile) ...[
                  Center(
                    child: FutureBuilder<bool>(
                      future: _authService.isFollowing(widget.userId),
                      builder: (context, snapshot) {
                        final isFollowing = snapshot.data ?? false;
                        return ElevatedButton(
                          onPressed: () async {
                            try {
                              if (isFollowing) {
                                await _authService.unfollowUser(widget.userId);
                              } else {
                                await _authService.followUser(widget.userId);
                              }
                              
                              // Notify to update counts instantly
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
                            backgroundColor: isFollowing ? Colors.grey[600] : Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 40),
                          ),
                          child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Follower/Following counts
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersListPage(
                                userId: widget.userId,
                                isFollowers: true,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              _followersCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Followers',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Following count
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersListPage(
                                userId: widget.userId,
                                isFollowers: false,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              _followingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Following',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Favorite Teams
                _buildTeamsList(),

                const SizedBox(height: 24),
                Text(
                  'Posts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPostsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _followNotifier.removeListener(_onFollowChanged);
    super.dispose();
  }
} 