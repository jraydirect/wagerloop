import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/supabase_config.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/auth_service.dart';
import '../widgets/dice_loading_widget.dart';
import '../utils/loading_utils.dart';

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

  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _offset = 0;
  static const int _limit = 20;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
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
      // Show a snackbar but don't update error state to maintain existing posts
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
      // Create the post and get the response
      final newPost = await _socialFeedService.createPost(content);

      // Clear the input field
      _postController.clear();

      // Add the new post to the beginning of the list
      setState(() {
        _posts.insert(0, newPost);
        _offset++; // Increment offset to account for the new post
      });

      // Show success message
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

  Future<void> _toggleLike(Post post) async {
    // Optimistically update UI
    setState(() {
      post.isLiked = !post.isLiked;
      post.likes += post.isLiked ? 1 : -1;
    });

    try {
      await _socialFeedService.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      setState(() {
        post.isLiked = !post.isLiked;
        post.likes += post.isLiked ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like. Please try again.')),
      );
      print('Error toggling like: $e');
    }
  }

  Future<void> _toggleRepost(Post post) async {
    // Optimistically update UI
    setState(() {
      post.isReposted = !post.isReposted;
      post.reposts += post.isReposted ? 1 : -1;
    });

    try {
      await _socialFeedService.toggleRepost(post.id);
    } catch (e) {
      // Revert on error
      setState(() {
        post.isReposted = !post.isReposted;
        post.reposts += post.isReposted ? 1 : -1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update repost. Please try again.')),
      );
      print('Error toggling repost: $e');
    }
  }

  void _showComments(Post post) async {
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[700], // Changed from dark color to gray
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Comment>>(
                    future: _socialFeedService.fetchComments(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Colors.green)); // Added green color
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load comments',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return Center(
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
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                comment.username[0].toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              comment.username,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.content,
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  timeago.format(comment.timestamp),
                                  style: TextStyle(
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
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Colors.green, // Changed from white to green
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (_commentController.text.isEmpty) return;

                                setModalState(() => isSubmitting = true);

                                try {
                                  await _socialFeedService.addComment(
                                    post.id,
                                    _commentController.text,
                                  );
                                  _commentController.clear();
                                  // Refresh the comments list
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
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

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[700], // Changed from grey[900] to grey[700]
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  backgroundImage: post.avatarUrl != null
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  child: post.avatarUrl == null
                      ? Text(
                          post.username[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(post.timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (post.username != _authService.currentUser?.email)
                  TextButton(
                    onPressed: () async {
                      try {
                        final isFollowing =
                            await _authService.isFollowing(post.id);
                        if (isFollowing) {
                          await _authService.unfollowUser(post.id);
                        } else {
                          await _authService.followUser(post.id);
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
                      backgroundColor: MaterialStateProperty.all(Colors.green), // Changed from blue to green
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Content
            Text(
              post.content,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: post.likes.toString(),
                  onTap: () => _toggleLike(post),
                  color: post.isLiked ? Colors.red : Colors.grey,
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: post.comments.length.toString(),
                  onTap: () => _showComments(post),
                ),
                _buildActionButton(
                  icon: Icons.repeat,
                  label: post.reposts.toString(),
                  onTap: () => _toggleRepost(post),
                  color: post.isReposted ? Colors.green : Colors.grey,
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
        color: Colors.grey[700], // Changed from grey[900] to grey[700]
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
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
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Added green background
                    foregroundColor: Colors.white, // Added white text
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white, // Added white color for loading
                          ),
                        )
                      : const Text('Post'),
                ),
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
      backgroundColor: Colors.grey[800], // Changed from black to gray
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Changed from black to gray
        title: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40, // Adjust height as needed
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
                    color: Colors.green, // Added green color for refresh indicator
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
                              child: CircularProgressIndicator(color: Colors.green), // Added green color
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
    super.dispose();
  }
}
