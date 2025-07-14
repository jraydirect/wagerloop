// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import authentication service to handle user operations
import '../services/auth_service.dart';
// Import Supabase configuration for database operations
import '../services/supabase_config.dart';
// Import follow notifier for real-time follow updates
import '../services/follow_notifier.dart';
// Import Post model for post data
import '../models/post.dart';
// Import PickPost model for pick post data
import '../models/pick_post.dart';
// Import custom profile avatar widget
import '../widgets/profile_avatar.dart';
// Import picks display widget for betting picks
import '../widgets/picks_display_widget.dart';
// Import timeago library for formatting timestamps
import 'package:timeago/timeago.dart' as timeago;
// Import followers list page for navigation
import 'followers_list_page.dart';
// Import dart:convert for JSON parsing
import 'dart:convert';

// UserProfilePage class definition - a stateful widget for displaying user profiles
class UserProfilePage extends StatefulWidget {
  // User ID whose profile to display
  final String userId;

  // Constructor with required userId parameter
  const UserProfilePage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  // Override createState method to return the state class instance
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

// Private state class that manages the user profile page's state and functionality
class _UserProfilePageState extends State<UserProfilePage> {
  // Authentication service instance for handling user operations
  final _authService = AuthService();
  // Social feed service instance for fetching posts
  final _socialFeedService = SupabaseConfig.socialFeedService;
  // Boolean flag to track loading state
  bool _isLoading = true;
  // String to store error message if any
  String? _error;

  // User data
  // Map to store user profile data
  Map<String, dynamic>? _userData;
  
  // Follower counts
  // Count of followers for the profile user
  int _followersCount = 0;
  // Count of users the profile user is following
  int _followingCount = 0;
  // Follow notifier instance for real-time follow updates
  final FollowNotifier _followNotifier = FollowNotifier();

  // Posts data
  // List to store user posts (can contain both Post and PickPost objects)
  List<dynamic> _userPosts = [];
  // Boolean flag to track posts loading state
  bool _isLoadingPosts = false;

  // Add state for liked posts
  // List to store posts liked by the user
  List<dynamic> _likedPosts = [];
  // Boolean flag to track liked posts loading state
  bool _isLoadingLikedPosts = false;

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Load user profile data
    _loadUserProfile();
    // Load user posts
    _loadUserPosts();
    // Load follower counts
    _loadFollowerCounts();
    // Load liked posts
    _loadLikedPosts();
    // Listen for follow events to update counts instantly
    _followNotifier.addListener(_onFollowChanged);
  }

  // Method to handle follow count changes
  void _onFollowChanged() {
    // Reload follower counts when someone is followed/unfollowed
    _loadFollowerCounts();
  }

  // Override didUpdateWidget to handle widget updates
  @override
  void didUpdateWidget(UserProfilePage oldWidget) {
    // Call parent didUpdateWidget
    super.didUpdateWidget(oldWidget);
    // Check if user ID changed
    if (oldWidget.userId != widget.userId) {
      // User ID changed, reload data
      _loadUserProfile();
      _loadUserPosts();
      _loadFollowerCounts();
    }
  }

  // Async method to load follower counts
  Future<void> _loadFollowerCounts() async {
    try {
      // Load followers and following counts for the target user
      final followers = await _authService.getFollowers(widget.userId);
      final following = await _authService.getFollowing(widget.userId);

      // Update state with follower counts
      setState(() {
        _followersCount = followers.length;
        _followingCount = following.length;
      });
    } catch (e) {
      print('Error loading follower counts: $e');
      // Keep counts as 0 if there's an error
    }
  }

  // Async method to refresh profile data
  Future<void> _refreshProfile() async {
    // Wait for all data to load
    await Future.wait([
      _loadUserProfile(),
      _loadUserPosts(),
      _loadFollowerCounts(),
    ]);
  }

  // Async method to load user profile data
  Future<void> _loadUserProfile() async {
    // Set loading state and clear error
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

      // Update state with user data if widget is still mounted
      if (mounted) {
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error if widget is still mounted
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _isLoading = false;
        });
      }
      print('Error loading user profile: $e');
    }
  }

  // Async method to load user posts
  Future<void> _loadUserPosts() async {
    // Set loading state for posts
    setState(() => _isLoadingPosts = true);
    try {
      // Fetch user posts from social feed service
      final posts = await _socialFeedService.fetchUserPosts(widget.userId);
      
      // Update like and repost status for current user
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId != null) {
        // Check like and repost status for each post
        for (final post in posts) {
          // Get post ID based on post type
          final postId = post is Post ? post.id : (post as PickPost).id;
          try {
            // Check if user liked this post
            final likeExists = await _authService.supabase
                .from('likes')
                .select()
                .eq('post_id', postId)
                .eq('user_id', currentUserId)
                .maybeSingle();
            
            // Update like status based on post type
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
            
            // Update repost status based on post type
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
      
      // Update state with user posts if widget is still mounted
      if (mounted) {
        setState(() => _userPosts = posts);
      }
    } catch (e) {
      print('Error loading user posts: $e');
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  // Fetch liked posts for the profile user
  Future<void> _loadLikedPosts() async {
    // Set loading state for liked posts
    setState(() => _isLoadingLikedPosts = true);
    try {
      // Query posts that the profile user has liked
      final response = await _authService.supabase
          .from('likes')
          .select('post_id, post:posts(*)')
          .eq('user_id', widget.userId);
      final likedPostsRaw = response as List<dynamic>;
      final posts = <dynamic>[];
      
      // Process each liked post
      for (final item in likedPostsRaw) {
        final postData = item['post'];
        if (postData == null) continue;
        final postType = postData['post_type'] ?? 'text';
        
        // Fetch counts for this post
        final postId = postData['id'];
        final likesCountResp = await _authService.supabase
            .from('likes')
            .select('id')
            .eq('post_id', postId);
        final repostsCountResp = await _authService.supabase
            .from('reposts')
            .select('id')
            .eq('post_id', postId);
        final commentsCountResp = await _authService.supabase
            .from('comments')
            .select('id')
            .eq('post_id', postId);
        
        // Calculate counts
        final likesCount = likesCountResp.length;
        final repostsCount = repostsCountResp.length;
        final commentsCount = commentsCountResp.length;
        
        // Create post object based on type
        if (postType == 'pick' && postData['picks_data'] != null) {
          List<Pick> picks = [];
          try {
            final picksJson = jsonDecode(postData['picks_data']);
            picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
          } catch (e) {
            print('Error parsing picks data: $e');
          }
          
          // Add PickPost to liked posts
          posts.add(PickPost(
            id: postData['id'],
            userId: postData['profile_id'] ?? postData['user_id'] ?? '',
            username: postData['username'] ?? 'Anonymous',
            content: postData['content'],
            timestamp: DateTime.parse(postData['created_at']).toLocal(),
            likes: likesCount,
            comments: const [],
            reposts: repostsCount,
            isLiked: true,
            isReposted: false,
            avatarUrl: postData['avatar_url'],
            picks: picks,
          ));
        } else {
          // Add regular Post to liked posts
          posts.add(Post(
            id: postData['id'],
            userId: postData['profile_id'] ?? postData['user_id'] ?? '',
            username: postData['username'] ?? 'Anonymous',
            content: postData['content'],
            timestamp: DateTime.parse(postData['created_at']).toLocal(),
            likes: likesCount,
            comments: const [],
            reposts: repostsCount,
            isLiked: true,
            isReposted: false,
            avatarUrl: postData['avatar_url'],
          ));
        }
      }
      
      // Update state with liked posts if widget is still mounted
      if (mounted) {
        setState(() => _likedPosts = posts);
      }
    } catch (e) {
      print('Error loading liked posts: $e');
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoadingLikedPosts = false);
      }
    }
  }

  // Method to handle follow/unfollow actions
  Future<void> _handleFollowAction() async {
    try {
      // Get current user ID
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) return;

      // Check if current user is following the profile user
      final isFollowing = await _authService.isFollowing(widget.userId);
      
      // Perform follow/unfollow action
      if (isFollowing) {
        await _authService.unfollowUser(widget.userId);
      } else {
        await _authService.followUser(widget.userId);
      }

      // Notify for real-time updates
      _followNotifier.notifyFollowChanged();
      
      // Reload follower counts
      _loadFollowerCounts();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to build follow button widget
  Widget _buildFollowButton() {
    // Get current user ID
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null || currentUserId == widget.userId) {
      // Don't show follow button for own profile or if not logged in
      return const SizedBox.shrink();
    }

    // Future builder to check follow status
    return FutureBuilder<bool>(
      future: _authService.isFollowing(widget.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        
        // Return styled follow button
        return ElevatedButton(
          onPressed: _handleFollowAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[700] : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  // Method to build favorite teams list widget
  Widget _buildTeamsList() {
    // Check if user data exists and has favorite teams
    if (_userData == null || _userData!['favorite_teams'] == null) {
      return const SizedBox.shrink();
    }

    // Get favorite teams list
    final favoriteTeams = _userData!['favorite_teams'] as List<dynamic>;
    if (favoriteTeams.isEmpty) {
      return const SizedBox.shrink();
    }

    // Return column with favorite teams
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorite teams title
        const Text(
          'Favorite Teams',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Wrap widget for team chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: favoriteTeams.map<Widget>((team) {
            // Return team chip
            return Chip(
              label: Text(
                team.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Method to build posts list widget
  Widget _buildPostsList() {
    // Show loading indicator when loading posts
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    // Show empty state if no posts
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.post_add,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Return column with posts
    return Column(
      children: _userPosts.map<Widget>((post) {
        // Build post card based on post type
        if (post is PickPost) {
          return _buildPickPostCard(post);
        } else if (post is Post) {
          return _buildPostCard(post);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  // Method to build liked posts list widget
  Widget _buildLikedPostsList() {
    // Show loading indicator when loading liked posts
    if (_isLoadingLikedPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    // Show empty state if no liked posts
    if (_likedPosts.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.favorite_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No liked posts yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Return column with liked posts
    return Column(
      children: _likedPosts.map<Widget>((post) {
        // Build post card based on post type
        if (post is PickPost) {
          return _buildPickPostCard(post);
        } else if (post is Post) {
          return _buildPostCard(post);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  // Method to build regular post card widget
  Widget _buildPostCard(Post post) {
    // Return card with post content
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with avatar and username
            Row(
              children: [
                ProfileAvatar(
                  avatarUrl: post.avatarUrl,
                  username: post.username,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeago.format(post.timestamp),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Post actions (like, comment, repost)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button
                Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.likes.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Comment button
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      post.comments.length.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Repost button
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: post.isReposted ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.reposts.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method to build pick post card widget
  Widget _buildPickPostCard(PickPost post) {
    // Return card with pick post content
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with avatar and username
            Row(
              children: [
                ProfileAvatar(
                  avatarUrl: post.avatarUrl,
                  username: post.username,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeago.format(post.timestamp),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Picks display
            PicksDisplayWidget(picks: post.picks),
            const SizedBox(height: 12),
            // Post actions (like, comment, repost)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Like button
                Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.likes.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Comment button
                Row(
                  children: [
                    const Icon(Icons.comment_outlined, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      post.comments.length.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                // Repost button
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: post.isReposted ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.reposts.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Show loading indicator when loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    // Show error state if error occurred
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no user data
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'User not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    // Return scaffold with user profile content
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _userData!['username'] ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                // Profile header
                Row(
                  children: [
                    // Profile avatar
                    ProfileAvatar(
                      avatarUrl: _userData!['avatar_url'],
                      username: _userData!['username'] ?? 'Anonymous',
                      radius: 40,
                    ),
                    const SizedBox(width: 16),
                    // Profile info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          Text(
                            _userData!['username'] ?? 'Anonymous',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Full name if available
                          if (_userData!['full_name'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _userData!['full_name'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          // Bio if available
                          if (_userData!['bio'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _userData!['bio'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Follow button
                _buildFollowButton(),
                const SizedBox(height: 16),
                // Follower counts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Followers count
                    GestureDetector(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                    GestureDetector(
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                // Posts section title
                Text(
                  'Posts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Posts list
                _buildPostsList(),

                const SizedBox(height: 32),
                // Liked posts section title
                Text(
                  'Liked Posts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Liked posts list
                _buildLikedPostsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    _followNotifier.removeListener(_onFollowChanged);
    // Call parent dispose
    super.dispose();
  }
} 