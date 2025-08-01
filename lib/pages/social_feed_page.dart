import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../models/comment.dart';
import '../services/supabase_config.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/picks_display_widget.dart';
import '../widgets/threaded_comments_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/auth_service.dart';
import '../widgets/dice_loading_widget.dart';
import '../utils/loading_utils.dart';
import 'picks/create_pick_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/realtime_profile_service.dart';
import 'user_profile_page.dart';
import '../services/scan_service.dart';
import 'scan_results_page.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> with TickerProviderStateMixin, RealTimeProfileMixin<SocialFeedPage> {
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _postController = TextEditingController();
  final _commentController = TextEditingController();
  final _authService = AuthService();

  final List<dynamic> _posts = []; // Can contain both Post and PickPost objects
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? _postsSubscription;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _cloudsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _cloudsAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _cloudsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _cloudsAnimation = Tween<double>(
      begin: -30.0,
      end: 30.0,
    ).animate(CurvedAnimation(
      parent: _cloudsController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _backgroundController.repeat();
    _floatingController.repeat(reverse: true);
    _cloudsController.repeat(reverse: true);
    
    _loadPosts();
    _scrollController.addListener(_onScroll);
    _setupRealTimeUpdates();
    RealTimeProfileService().initializeProfileUpdates();
  }

  void _setupRealTimeUpdates() {
    try {
      // Listen to real-time updates for new posts
      // Listen to all posts to catch new ones immediately
      _postsSubscription = SupabaseConfig.supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (List<Map<String, dynamic>> data) {
              _handleRealTimeUpdate(data);
            },
            onError: (error) {
              // Optionally retry the subscription after a delay
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  _setupRealTimeUpdates();
                }
              });
            },
          );
    } catch (e) {
      // print('Error setting up real-time updates: $e');
    }
  }

  void _handleRealTimeUpdate(List<Map<String, dynamic>> data) async {
    if (data.isEmpty || !mounted) return;
    
    // Process only new posts that aren't already in our list
    final newPosts = <dynamic>[];
    final currentUserId = _authService.currentUser?.id;
    
    for (final postData in data) {
      final postId = postData['id'];
      final postUserId = postData['user_id'] ?? postData['profile_id'];
      
      // Check if this post is already in our list
      bool postExists = _posts.any((post) {
        final id = post is Post ? post.id : (post as PickPost).id;
        return id == postId;
      });
      
      if (!postExists) {
        // Only add posts that are newer than our current load time and not from current user
        // (current user posts are handled immediately in _createPost)
        final postCreatedAt = DateTime.parse(postData['created_at']).toLocal();
        final shouldAdd = postUserId != currentUserId && 
                          (_posts.isEmpty || postCreatedAt.isAfter(_getPostTimestamp(_posts.first)));
        
        if (shouldAdd) {
          try {
            // Use the data we already have instead of fetching again
            final newPost = await _mapSinglePostFromRealTimeData(postData);
            newPosts.add(newPost);
          } catch (e) {
            // print('Error mapping real-time post $postId: $e');
          }
        }
      }
    }
    
    // Add all new posts at once if we have any
    if (newPosts.isNotEmpty && mounted) {
      setState(() {
        // Sort new posts by timestamp (newest first)
        newPosts.sort((a, b) => _getPostTimestamp(b).compareTo(_getPostTimestamp(a)));
        
        // Insert all new posts at the beginning
        for (final newPost in newPosts.reversed) {
          _posts.insert(0, newPost);
          _offset++;
        }
      });
      
      // Debug log
      // print('Added ${newPosts.length} new posts via real-time update');
    }
  }

  DateTime _getPostTimestamp(dynamic post) {
    return post is Post ? post.timestamp : (post as PickPost).timestamp;
  }

  Future<dynamic> _mapSinglePost(Map<String, dynamic> postData) async {
    final postType = postData['post_type'] ?? 'text';
    final postId = postData['id'];
    
    // Get accurate comment count for this post
    int commentsCount = 0;
    try {
      final commentsCountResponse = await SupabaseConfig.supabase
          .from('comments')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);
      commentsCount = commentsCountResponse.count ?? 0;
    } catch (e) {
      // print('Error fetching comment count: $e');
    }
    
    if (postType == 'pick' && postData['picks_data'] != null) {
      // Parse picks data
      List<Pick> picks = [];
      try {
        final picksJson = jsonDecode(postData['picks_data']);
        picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
      } catch (e) {
        // print('Error parsing picks data: $e');
      }
      
      return PickPost(
        id: postData['id'],
        userId: postData['user_id'] ?? postData['profile_id'] ?? '',
        username: postData['profile']['username'] ?? 'Anonymous',
        content: postData['content'],
        timestamp: DateTime.parse(postData['created_at']).toLocal(),
        likes: 0,
        comments: List.generate(commentsCount, (index) => Comment(
          id: 'placeholder_$index',
          username: 'placeholder',
          content: 'placeholder',
          timestamp: DateTime.now(),
        )),
        reposts: 0,
        isLiked: false,
        isReposted: false,
        avatarUrl: postData['profile']['avatar_url'],
        picks: picks,
      );
    } else {
      return Post(
        id: postData['id'],
        userId: postData['user_id'] ?? postData['profile_id'] ?? '',
        username: postData['profile']['username'] ?? 'Anonymous',
        content: postData['content'],
        timestamp: DateTime.parse(postData['created_at']).toLocal(),
        likes: 0,
        comments: List.generate(commentsCount, (index) => Comment(
          id: 'placeholder_$index',
          username: 'placeholder',
          content: 'placeholder',
          timestamp: DateTime.now(),
        )),
        reposts: 0,
        isLiked: false,
        isReposted: false,
        avatarUrl: postData['profile']['avatar_url'],
      );
    }
  }

  Future<dynamic> _mapSinglePostFromRealTimeData(Map<String, dynamic> postData) async {
    final postType = postData['post_type'] ?? 'text';
    final postId = postData['id'];
    
    // Get profile data - we need to fetch this since it's not in the real-time data
    String username = 'Anonymous';
    String? avatarUrl;
    
    try {
      final profileData = await SupabaseConfig.supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', postData['user_id'] ?? postData['profile_id'] ?? '')
          .single();
      
      username = profileData['username'] ?? 'Anonymous';
      avatarUrl = profileData['avatar_url'];
    } catch (e) {
      // print('Error fetching profile for real-time post: $e');
    }
    
    // Get accurate comment count for this post
    int commentsCount = 0;
    try {
      final commentsCountResponse = await SupabaseConfig.supabase
          .from('comments')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);
      commentsCount = commentsCountResponse.count ?? 0;
    } catch (e) {
      // print('Error fetching comment count for real-time post: $e');
    }
    
    if (postType == 'pick' && postData['picks_data'] != null) {
      // Parse picks data
      List<Pick> picks = [];
      try {
        final picksJson = jsonDecode(postData['picks_data']);
        picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
      } catch (e) {
        // print('Error parsing picks data: $e');
      }
      
      return PickPost(
        id: postData['id'],
        userId: postData['user_id'] ?? postData['profile_id'] ?? '',
        username: username,
        content: postData['content'],
        timestamp: DateTime.parse(postData['created_at']).toLocal(),
        likes: 0,
        comments: List.generate(commentsCount, (index) => Comment(
          id: 'placeholder_$index',
          username: 'placeholder',
          content: 'placeholder',
          timestamp: DateTime.now(),
        )),
        reposts: 0,
        isLiked: false,
        isReposted: false,
        avatarUrl: avatarUrl,
        picks: picks,
      );
    } else {
      return Post(
        id: postData['id'],
        userId: postData['user_id'] ?? postData['profile_id'] ?? '',
        username: username,
        content: postData['content'],
        timestamp: DateTime.parse(postData['created_at']).toLocal(),
        likes: 0,
        comments: List.generate(commentsCount, (index) => Comment(
          id: 'placeholder_$index',
          username: 'placeholder',
          content: 'placeholder',
          timestamp: DateTime.now(),
        )),
        reposts: 0,
        isLiked: false,
        isReposted: false,
        avatarUrl: avatarUrl,
      );
    }
  }



  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _offset = 0;
    });

    try {
      final posts =
          await _socialFeedService.fetchPosts(limit: _limit, offset: 0);
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _hasMore = posts.length == _limit;
        _offset = posts.length;
      });
    } catch (e) {
      setState(() => _error = 'Could not load posts. Please try again.');
      // print('Error loading posts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final posts = await _socialFeedService.fetchPosts(
        limit: _limit,
        offset: _offset,
      );

      if (posts.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }

      setState(() {
        _posts.addAll(posts);
        _offset += posts.length;
        _hasMore = posts.length == _limit;
      });
    } catch (e) {
      // print('Error loading more posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load more posts. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newPost = await _socialFeedService.createPost(content);
      _postController.clear();

      // Add the post immediately to the local state for instant feedback
      setState(() {
        _posts.insert(0, newPost);
        _offset++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      // print('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create post. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
      // print('Error toggling like: $e');
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
      // print('Error toggling repost: $e');
    }
  }

  Future<void> _handleScanButton() async {
    // print('Scan button pressed');
    final scanService = ScanService();
    
    try {
      // Show image source selection dialog
      // print('Showing image source dialog...');
      final imageFile = await scanService.showImageSourceDialog(context);
      // print('Image file result: ${imageFile?.path ?? 'null'}');
      
      if (imageFile != null && mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    'Processing betting slip...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );

        // Process the image
        // print('Processing betting slip...');
        final scanResult = await scanService.processBettingSlip(imageFile);
        // print('Scan result: ${scanResult?.success ?? 'null'}');
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (scanResult != null && scanResult.success && mounted) {
          // Navigate to scan results page
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanResultsPage(scanResult: scanResult),
            ),
          );
          
          // If a pick post was created, add it instantly to the feed
          if (result != null && result is PickPost) {
            setState(() {
              _posts.insert(0, result);
              _offset++;
            });
          }
        } else if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(scanResult?.error ?? 'Failed to process betting slip'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // print('Error handling scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning betting slip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(dynamic post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final postId = post is Post ? post.id : (post as PickPost).id;
        await _socialFeedService.deletePost(postId);
        
        setState(() {
          _posts.removeWhere((p) {
            final id = p is Post ? p.id : (p as PickPost).id;
            return id == postId;
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInteractions(dynamic post) async {
    final postId = post is Post ? post.id : (post as PickPost).id;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Post Interactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(text: 'Likes'),
                        Tab(text: 'Reposts'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildInteractionsList(postId, 'likes'),
                          _buildInteractionsList(postId, 'reposts'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsList(String postId, String type) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getInteractions(postId, type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load interactions',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final interactions = snapshot.data ?? [];

        if (interactions.isEmpty) {
          return Center(
            child: Text(
              'No ${type} yet',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: interactions.length,
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return ListTile(
              leading: ProfileAvatar(
                avatarUrl: interaction['avatar_url'],
                username: interaction['username'] ?? 'Anonymous',
                radius: 20,
                backgroundColor: Colors.blue,
                onTap: () {
                  // Note: We don't have user ID in interactions, so we can't navigate to profile
                  // This would need to be updated if we want to include user IDs in interactions
                },
              ),
              title: Text(
                interaction['username'] ?? 'Anonymous',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                timeago.format(DateTime.parse(interaction['created_at'])),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getInteractions(String postId, String type) async {
    try {
      final response = await SupabaseConfig.supabase
          .from(type)
          .select('''
            *,
            profile:profiles!${type}_user_id_fkey (
              username,
              avatar_url
            )
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => {
        'username': item['profile']['username'],
        'avatar_url': item['profile']['avatar_url'],
        'created_at': item['created_at'],
      }).toList();
    } catch (e) {
      // print('Error getting $type: $e');
      return [];
    }
  }

  void _showComments(dynamic post) async {
    final postId = post is Post ? post.id : (post as PickPost).id;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Comment>>(
                    future: _socialFeedService.fetchComments(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Failed to load comments',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final comments = snapshot.data ?? [];

                      return ThreadedCommentsWidget(
                        postId: postId,
                        comments: comments,
                        onCommentAdded: () {
                          // Refresh the main feed to update comment counts
                          setState(() {});
                          // Also refresh the comments list in the modal
                          Navigator.pop(context);
                          _showComments(post);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Utility functions for odds conversion (copied from create_pick_page.dart)

  // Animated background methods
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            _buildPrimaryOrbitalSystem(),
            _buildSecondaryAmbientLayer(),
            _buildTertiaryDetailLayer(),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryOrbitalSystem() {
    return Positioned.fill(
      child: CustomPaint(
        painter: OrbitalPainter(
          animation: _backgroundAnimation.value,
          color: Colors.green.withOpacity(0.03),
          strokeWidth: 1.5,
          radius: 120,
        ),
      ),
    );
  }

  Widget _buildSecondaryAmbientLayer() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlePainter(
          animation: _backgroundAnimation.value,
          particleCount: 25,
          color: Colors.white.withOpacity(0.02),
        ),
      ),
    );
  }

  Widget _buildTertiaryDetailLayer() {
    return Positioned.fill(
      child: CustomPaint(
        painter: FlowingLinesPainter(
          animation: _backgroundAnimation.value,
          color: Colors.green.withOpacity(0.015),
          lineCount: 3,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 120, // Fixed height to control the overlap
      child: Stack(
        children: [
          // Turf background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/turfBackground.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          // Football laces bar positioned to overlap header turf bottom
          Positioned(
            bottom: 0, // Moved down just a tiny bit more
            left: -10, // Extended slightly to the left
            right: -10, // Extended slightly to the right
            child: Opacity(
              opacity: 0.65, // More transparent while still visible
              child: Container(
                height: 28, // Increased height slightly
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/lacesbar.png'),
                    fit: BoxFit.fitWidth,
                    repeat: ImageRepeat.repeatX,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    // Extract common properties
    final id = post is Post ? post.id : (post as PickPost).id;
    final userId = post is Post ? post.userId : (post as PickPost).userId;
    final username = post is Post ? post.username : (post as PickPost).username;
    final content = post is Post ? post.content : (post as PickPost).content;
    final timestamp = post is Post ? post.timestamp : (post as PickPost).timestamp;
    final likes = post is Post ? post.likes : (post as PickPost).likes;
    final comments = post is Post ? post.comments : (post as PickPost).comments;
    final reposts = post is Post ? post.reposts : (post as PickPost).reposts;
    final isLiked = post is Post ? post.isLiked : (post as PickPost).isLiked;
    final isReposted = post is Post ? post.isReposted : (post as PickPost).isReposted;
    final avatarUrl = post is Post ? post.avatarUrl : (post as PickPost).avatarUrl;
    
    // Check if this post belongs to the current user
    final currentUserId = _authService.currentUser?.id;
    final isOwnPost = currentUserId != null && userId == currentUserId;

    // Show picks if this is a PickPost
    if (post is PickPost && post.hasPicks) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileAvatar(
                    avatarUrl: avatarUrl,
                    username: username,
                    radius: 24,
                    backgroundColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(userId: userId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(timestamp),
                          style: TextStyle(
                            color: Colors.grey[400], 
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
              const SizedBox(height: 16),
              // Content
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Picks display using the new widget
              PicksDisplayWidget(
                picks: post.picks,
                showParlayBadge: true, // Show parlay badge in the widget
                compact: false,
              ),
              const SizedBox(height: 16),
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
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
                    onTap: () => _showComments(post),
                  ),
                  _buildActionButton(
                    icon: Icons.repeat,
                    label: reposts.toString(),
                    onTap: () => _toggleRepost(post),
                    color: isReposted ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      );
    }
    // For regular posts, use the existing _buildPostCard logic
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatar(
                  avatarUrl: avatarUrl,
                  username: username,
                  radius: 24,
                  backgroundColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: userId),
                      ),
                    );
                  },
                ),
                              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(timestamp),
                      style: TextStyle(
                        color: Colors.grey[400], 
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
                if (isOwnPost)
                  PopupMenuButton<String>(
                    onSelected: (String choice) async {
                      switch (choice) {
                        case 'delete':
                          _showDeleteConfirmation(post);
                          break;
                        case 'interactions':
                          _showInteractions(post);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Post'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'interactions',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('View Interactions'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
                  )
                else
                  FutureBuilder<bool>(
                    future: _authService.isFollowing(userId),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;
                      return TextButton(
                        onPressed: () async {
                          try {
                            if (isFollowing) {
                              await _authService.unfollowUser(userId);
                            } else {
                              await _authService.followUser(userId);
                            }
                            setState(() {});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update follow status')),
                            );
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            isFollowing ? Colors.grey : Colors.green,
                          ),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            
            // Show picks if this is a PickPost
            if (post is PickPost && post.hasPicks) ...[
              const SizedBox(height: 12),
              PicksDisplayWidget(
                picks: post.picks,
                showParlayBadge: false, // Already shown in header
                compact: false,
              ),
            ],
            
            const SizedBox(height: 16),
            // Actions
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF374151).withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
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
                  onTap: () => _showComments(post),
                ),
                _buildActionButton(
                  icon: Icons.repeat,
                  label: reposts.toString(),
                  onTap: () => _toggleRepost(post),
                  color: isReposted ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePost() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _authService.getCurrentUserProfile(),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      return ProfileAvatar(
                        avatarUrl: profile?['avatar_url'],
                        username: profile?['username'] ?? 'You',
                        radius: 24,
                        backgroundColor: Colors.green,
                        // No onTap for current user's avatar in create post section
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Modern button layout
              Row(
                children: [
                  // Scan button with Flexible wrapper
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _handleScanButton();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.withOpacity(0.7)),
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Picks button with Flexible wrapper
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreatePickPage(),
                          ),
                        );
                        // If a pick post was created, add it instantly to the feed
                        if (result != null && result is PickPost) {
                          setState(() {
                            _posts.insert(0, result);
                            _offset++;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.withOpacity(0.7)),
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.green.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.sports_basketball, size: 18),
                      label: const Text('Pick', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Regular post button with Flexible wrapper
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Post', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onProfileUpdate(Map<String, dynamic> update) {
    if (!mounted) return;
    if (update['type'] == 'profile_update' && update['user_id'] != null) {
      final updatedUserId = update['user_id'];
      final updatedProfile = update['profile'];
      final newAvatarUrl = updatedProfile['avatar_url'];
      setState(() {
        for (var post in _posts) {
          if ((post is Post && post.userId == updatedUserId) ||
              (post is PickPost && post.userId == updatedUserId)) {
            post.avatarUrl = newAvatarUrl;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/turfBackground.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned.fill(
              child: _buildAnimatedBackground(),
            ),
            // Main content
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),
                        
                        // Create Post Section
                        SliverToBoxAdapter(
                          child: _buildCreatePost(),
                        ),
                        
                        // Posts Content
                        _error != null
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(20),
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F2937).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Unable to load posts',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (index == _posts.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(color: Colors.green),
                                          ),
                                        );
                                      }
                                      return _buildPostCard(_posts[index]);
                                    },
                                    childCount: _posts.length + (_hasMore ? 1 : 0),
                                  ),
                                ),
                              ),
                              
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Clouds positioned higher up with side-to-side animation
            Positioned(
              top: -40, // Moved up much higher
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _cloudsAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_cloudsAnimation.value, 0),
                    child: Opacity(
                      opacity: 0.9, // Less transparent, more visible
                      child: Image.asset(
                        'assets/clouds.png',
                        fit: BoxFit.cover,
                        height: 120, // Increased height further to compensate
                      ),
                    ),
                  );
                },
              ),
            ),
            // WagerLoop logo floating above clouds with animation
            Positioned(
              top: 50, // Same position as in header
              left: 24,
              right: 24,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Center(
                      child: Image.asset(
                        'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _postsSubscription?.cancel();
    
    // Dispose animation controllers
    _fadeController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _cloudsController.dispose();
    
    super.dispose();
  }
}

// Custom Painters for animated background
class OrbitalPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;
  final double radius;

  OrbitalPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw orbital circles
    for (int i = 0; i < 3; i++) {
      final orbitalRadius = radius + (i * 80);
      canvas.drawCircle(center, orbitalRadius, paint);
      
      // Draw orbiting dots
      final angle = animation + (i * pi / 2);
      final dotX = center.dx + cos(angle) * orbitalRadius;
      final dotY = center.dy + sin(angle) * orbitalRadius;
      
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = color.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(OrbitalPainter oldDelegate) => animation != oldDelegate.animation;
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final int particleCount;
  final Color color;

  ParticlePainter({
    required this.animation,
    required this.particleCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Add floating motion
      final floatX = x + sin(animation + i) * 20;
      final floatY = y + cos(animation + i * 0.7) * 15;
      
      canvas.drawCircle(
        Offset(floatX, floatY),
        random.nextDouble() * 3 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => animation != oldDelegate.animation;
}

class FlowingLinesPainter extends CustomPainter {
  final double animation;
  final Color color;
  final int lineCount;

  FlowingLinesPainter({
    required this.animation,
    required this.color,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < lineCount; i++) {
      final path = Path();
      final startY = (size.height / lineCount) * i + 50;
      
      path.moveTo(-50, startY);
      
      for (double x = -50; x < size.width + 50; x += 20) {
        final y = startY + sin((x / 100) + animation + (i * pi / 3)) * 30;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FlowingLinesPainter oldDelegate) => animation != oldDelegate.animation;
}
