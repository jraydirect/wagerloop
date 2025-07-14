import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../models/comment.dart';
import '../services/supabase_config.dart';
import '../widgets/profile_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/auth_service.dart';
import '../widgets/dice_loading_widget.dart';
import '../utils/loading_utils.dart';
import 'picks/create_pick_page.dart';
import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialFeedPage extends StatefulWidget {
  const SocialFeedPage({Key? key}) : super(key: key);

  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage> {
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

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
    _setupRealTimeUpdates();
  }

  void _setupRealTimeUpdates() {
    try {
      // Listen to real-time updates for new posts
      // Only listen for posts created in the last hour to avoid loading too much data
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String();
      
      _postsSubscription = SupabaseConfig.supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .gte('created_at', oneHourAgo)
          .order('created_at', ascending: false)
          .listen(
            (List<Map<String, dynamic>> data) {
              _handleRealTimeUpdate(data);
            },
            onError: (error) {
              print('Real-time subscription error: $error');
              // Optionally retry the subscription after a delay
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  _setupRealTimeUpdates();
                }
              });
            },
          );
    } catch (e) {
      print('Error setting up real-time updates: $e');
    }
  }

  void _handleRealTimeUpdate(List<Map<String, dynamic>> data) async {
    if (data.isEmpty || !mounted) return;
    
    // Process only new posts that aren't already in our list
    final newPosts = <dynamic>[];
    
    for (final postData in data) {
      final postId = postData['id'];
      
      // Check if this post is already in our list
      bool postExists = _posts.any((post) {
        final id = post is Post ? post.id : (post as PickPost).id;
        return id == postId;
      });
      
      if (!postExists) {
        try {
          // Fetch the full post data with profile information
          final fullPostData = await SupabaseConfig.supabase
              .from('posts')
              .select('''
                *,
                profile:profiles!posts_profile_id_fkey (
                  id, username, avatar_url
                )
              ''')
              .eq('id', postId)
              .single();
          
          // Convert to proper post object
          final newPost = await _mapSinglePost(fullPostData);
          
          // Only add if it's newer than our newest post or if we have no posts
          if (_posts.isEmpty || 
              newPost.timestamp.isAfter(_getPostTimestamp(_posts.first))) {
            newPosts.add(newPost);
          }
        } catch (e) {
          print('Error fetching new post $postId: $e');
        }
      }
    }
    
    // Add all new posts at once
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
      print('Added ${newPosts.length} new posts via real-time update');
      
      // Show a brief notification for new posts (only show if not from current user's post creation)
      if (newPosts.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New post added'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newPosts.length} new posts added'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          ),
        );
      }
    }
  }

  DateTime _getPostTimestamp(dynamic post) {
    return post is Post ? post.timestamp : (post as PickPost).timestamp;
  }

  Future<dynamic> _mapSinglePost(Map<String, dynamic> postData) async {
    final postType = postData['post_type'] ?? 'text';
    
    if (postType == 'pick' && postData['picks_data'] != null) {
      // Parse picks data
      List<Pick> picks = [];
      try {
        final picksJson = jsonDecode(postData['picks_data']);
        picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
      } catch (e) {
        print('Error parsing picks data: $e');
      }
      
      return PickPost(
        id: postData['id'],
        userId: postData['user_id'] ?? postData['profile_id'] ?? '',
        username: postData['profile']['username'] ?? 'Anonymous',
        content: postData['content'],
        timestamp: DateTime.parse(postData['created_at']).toLocal(),
        likes: 0,
        comments: const [],
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
        comments: const [],
        reposts: 0,
        isLiked: false,
        isReposted: false,
        avatarUrl: postData['profile']['avatar_url'],
      );
    }
  }

  Widget _buildPickCard(Pick pick) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_basketball, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                pick.game.sport.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pick.displayText,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pick.reasoning!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            pick.game.formattedGameTime,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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
      print('Error loading posts: $e');
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
      print('Error loading more posts: $e');
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

      // The real-time subscription will handle adding the post to the list,
      // but we can also add it immediately for instant feedback
      setState(() {
        // Check if the post isn't already in the list (avoid duplicates)
        bool postExists = _posts.any((post) {
          final id = post is Post ? post.id : (post as PickPost).id;
          return id == newPost.id;
        });
        
        if (!postExists) {
          _posts.insert(0, newPost);
          _offset++;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      print('Error creating post: $e');
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

  void _showDeleteConfirmation(dynamic post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
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
      backgroundColor: Colors.grey[700],
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
      print('Error getting $type: $e');
      return [];
    }
  }

  void _showComments(dynamic post) async {
    final postId = post is Post ? post.id : (post as PickPost).id;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[700],
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

                      if (comments.isEmpty) {
                        return const Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                          leading: ProfileAvatar(
                          avatarUrl: null, // Comments don't have avatar URLs in current implementation
                          username: comment.username,
                          radius: 20,
                          backgroundColor: Colors.blue,
                          ),
                            title: Text(
                              comment.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.content,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(comment.timestamp),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.green,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_commentController.text.isEmpty) return;

                                setModalState(() => isSubmitting = true);

                                try {
                                  await _socialFeedService.addComment(
                                    postId,
                                    _commentController.text,
                                  );
                                  _commentController.clear();
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to add comment. Please try again.',
                                      ),
                                    ),
                                  );
                                  print('Error adding comment: $e');
                                } finally {
                                  setModalState(() => isSubmitting = false);
                                }
                              },
                      ),
                    ],
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
  double _americanToDecimal(String oddsStr) {
    int odds = int.tryParse(oddsStr) ?? 0;
    if (odds > 0) {
      return (odds / 100) + 1;
    } else {
      return 1 + (100 / -odds);
    }
  }

  String _decimalToAmerican(double dec) {
    if (dec >= 2) {
      return '+ 2${((dec - 1) * 100).round()}';
    } else {
      return '-${(100 / (dec - 1)).round()}';
    }
  }

  String? _getParlayOdds(List picks) {
    if (picks.length < 2) return null;
    double product = 1.0;
    for (var pick in picks) {
      double decimal = _americanToDecimal(pick.odds);
      product *= decimal;
    }
    return _decimalToAmerican(product);
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
      final isParlay = post.picks.length > 1;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.grey[700], // Use green theme for all
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                    radius: 20,
                    backgroundColor: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeago.format(timestamp),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isParlay)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.layers, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${post.picks.length}-Leg Parlay',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_getParlayOdds(post.picks) != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _getParlayOdds(post.picks)!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Content
              Text(
                content,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              // Picks list with improved formatting
              Column(
                children: post.picks.asMap().entries.map<Widget>((entry) {
                  final index = entry.key;
                  final pick = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pick.game.formattedGameTime} • ${pick.game.sport}',
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  pick.displayText,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pick.odds,
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
            ],
          ),
        ),
      );
    }
    // For regular posts, use the existing _buildPostCard logic
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[700],
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  radius: 20,
                  backgroundColor: Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
            const SizedBox(height: 8),
            // Content
            Text(
              content,
              style: const TextStyle(color: Colors.white),
            ),
            
            // Show picks if this is a PickPost
            if (post is PickPost && post.hasPicks) ...[
              const SizedBox(height: 12),
              ...post.picks.map((pick) => _buildPickCard(pick)).toList(),
            ],
            
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

  Widget _buildCreatePost() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.grey[700],
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                        radius: 20,
                        backgroundColor: Colors.green,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Fixed the button layout with proper constraints
              Row(
                children: [
                  const Spacer(), // Push buttons to the right
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
                        // Refresh the feed when returning from create pick page
                        if (result == true) {
                          _loadPosts();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.sports_basketball, size: 18),
                      label: const Text('Pick'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Regular post button with Flexible wrapper
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
                          : const Text('Post'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCreatePost(),
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  )
                : RefreshIndicator(
                    color: Colors.green,
                    onRefresh: _loadPosts,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
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
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }
}
