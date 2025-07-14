import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';

class SocialFeedService {
  final SupabaseClient _supabase;

  SocialFeedService(this._supabase);
// Fetch posts with user suggestions
  Future<List<Post>> fetchPosts({int limit = 20, int offset = 0}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Simplified approach: Get all recent posts first, then prioritize followed users
      final response = await _supabase
          .from('posts')
          .select('''
          *,
          profile:profiles!posts_profile_id_fkey (
            id, username, avatar_url
          )
        ''')
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      final posts = await _mapPosts(response);
      
      // Fetch like and repost status for current user
      for (final post in posts) {
        try {
          // Check if user liked this post
          final likeExists = await _supabase
              .from('likes')
              .select()
              .eq('post_id', post.id)
              .eq('user_id', user.id)
              .maybeSingle();
          post.isLiked = likeExists != null;

          // Check if user reposted this post
          final repostExists = await _supabase
              .from('reposts')
              .select()
              .eq('post_id', post.id)
              .eq('user_id', user.id)
              .maybeSingle();
          post.isReposted = repostExists != null;

          // Get actual counts
          final likesCount = await _supabase
              .from('likes')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', post.id);
          post.likes = likesCount.count ?? 0;

          final repostsCount = await _supabase
              .from('reposts')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', post.id);
          post.reposts = repostsCount.count ?? 0;
        } catch (e) {
          print('Error fetching post stats for ${post.id}: $e');
          // Continue with defaults if there's an error
        }
      }

      return posts;
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  // Update the fetchPosts method to handle timestamps
  Future<List<Post>> _mapPosts(List<dynamic> postData) async {
    return postData.map((post) {
      return Post(
        id: post['id'],
        username: post['profile']['username'] ?? 'Anonymous',
        content: post['content'],
        timestamp: DateTime.parse(post['created_at'])
            .toLocal(), // Convert to local time
        likes: 0, // Will be updated in fetchPosts
        comments: const [],
        reposts: 0, // Will be updated in fetchPosts
        isLiked: false, // Will be updated in fetchPosts
        isReposted: false, // Will be updated in fetchPosts
        avatarUrl: post['profile']['avatar_url'],
      );
    }).toList();
  }

  Future<List<Post>> fetchUserPosts(String userId) async {
    try {
      final response = await _supabase.from('posts').select('''
        *,
        profile:profiles!posts_profile_id_fkey (
          username,
          avatar_url
        ),
        likes(count),
        comments(count),
        reposts(count)
      ''').eq('profile_id', userId).order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((post) => Post(
                id: post['id'],
                username: post['profile']['username'] ?? 'Anonymous',
                content: post['content'],
                timestamp: DateTime.parse(post['created_at'])
                    .toLocal(), // Convert to local time
                likes: (post['likes'] as List).isNotEmpty
                    ? (post['likes'][0]['count'] ?? 0)
                    : 0,
                comments: const [],
                reposts: (post['reposts'] as List).isNotEmpty
                    ? (post['reposts'][0]['count'] ?? 0)
                    : 0,
                avatarUrl: post['profile']['avatar_url'],
              ))
          .toList();
    } catch (e) {
      print('Error fetching user posts: $e');
      rethrow;
    }
  }

  Future<Post> createPost(String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create post with current timestamp in UTC
      final response = await _supabase.from('posts').insert({
        'user_id': user.id,
        'profile_id': user.id,
        'content': content,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select('''
      *,
      profile:profiles!posts_profile_id_fkey (
        username,
        avatar_url
      )
    ''').single();

      // Create and return a Post object with local timestamp
      return Post(
        id: response['id'],
        username: profileResponse['username'] ?? 'Anonymous',
        content: response['content'],
        timestamp: DateTime.parse(response['created_at']).toLocal(),
        likes: 0,
        comments: const [],
        reposts: 0,
        avatarUrl: profileResponse['avatar_url'],
      );
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Add a comment to a post
  Future<Comment> addComment(String postId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile first
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Comment(
        id: response['id'],
        username: profileResponse['username'] ?? 'Anonymous',
        content: response['content'],
        timestamp: DateTime.parse(response['created_at']),
        likes: 0,
        avatarUrl: profileResponse['avatar_url'],
      );
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Fetch comments for a post
  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final response = await _supabase.from('comments').select('''
            *,
            profile:profiles!inner (
              username,
              avatar_url
            )
          ''').eq('post_id', postId).order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((comment) => Comment(
                id: comment['id'],
                username: comment['profile']['username'] ?? 'Anonymous',
                content: comment['content'],
                timestamp: DateTime.parse(comment['created_at']),
                likes: 0,
                avatarUrl: comment['profile']['avatar_url'],
              ))
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
      rethrow;
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final exists = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (exists == null) {
        await _supabase.from('likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Toggle repost on a post
  Future<void> toggleRepost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final exists = await _supabase
          .from('reposts')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (exists == null) {
        await _supabase.from('reposts').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('reposts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      print('Error toggling repost: $e');
      rethrow;
    }
  }
}
