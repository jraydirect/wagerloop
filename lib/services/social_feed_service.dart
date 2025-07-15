import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../models/comment.dart';
import 'dart:convert';

/// Manages social media functionality for WagerLoop.
/// 
/// Handles post creation, retrieval, and interactions including likes,
/// comments, and reposts. Supports both regular text posts and betting
/// pick posts with embedded sports picks and odds.
/// 
/// Integrates with Supabase for real-time social feed updates and
/// user interaction tracking.
class SocialFeedService {
  final SupabaseClient _supabase;

  SocialFeedService(this._supabase);

  /// Fetches posts for the social feed with user personalization.
  /// 
  /// Retrieves posts from all users with prioritization for followed users.
  /// Includes both regular posts and betting pick posts with like/repost
  /// status for the current user.
  /// 
  /// Parameters:
  ///   - limit: Maximum number of posts to retrieve (default: 20)
  ///   - offset: Number of posts to skip for pagination (default: 0)
  /// 
  /// Returns:
  ///   List<dynamic> containing Post and PickPost objects with interaction status
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or database query fails
  Future<List<dynamic>> fetchPosts({int limit = 20, int offset = 0}) async {
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
        final postId = post is Post ? post.id : (post as PickPost).id;
        try {
          // Check if user liked this post
          final likeExists = await _supabase
              .from('likes')
              .select()
              .eq('post_id', postId)
              .eq('user_id', user.id)
              .maybeSingle();
          
          if (post is Post) {
            post.isLiked = likeExists != null;
          } else if (post is PickPost) {
            post.isLiked = likeExists != null;
          }

          // Check if user reposted this post
          final repostExists = await _supabase
              .from('reposts')
              .select()
              .eq('post_id', postId)
              .eq('user_id', user.id)
              .maybeSingle();
          
          if (post is Post) {
            post.isReposted = repostExists != null;
          } else if (post is PickPost) {
            post.isReposted = repostExists != null;
          }

          // Get actual counts
          final likesCount = await _supabase
              .from('likes')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', postId);
          
          if (post is Post) {
            post.likes = likesCount.count ?? 0;
          } else if (post is PickPost) {
            post.likes = likesCount.count ?? 0;
          }

          final repostsCount = await _supabase
              .from('reposts')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', postId);
          
          if (post is Post) {
            post.reposts = repostsCount.count ?? 0;
          } else if (post is PickPost) {
            post.reposts = repostsCount.count ?? 0;
          }
        } catch (e) {
          print('Error checking like/repost status: $e');
        }
      }

      return posts;
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  /// Converts raw post data from database to Post or PickPost objects.
  /// 
  /// Transforms Supabase query results into typed objects with proper
  /// interaction counts and user information. Handles both regular posts
  /// and betting pick posts with embedded sports picks.
  /// 
  /// Parameters:
  ///   - postData: Raw post data from Supabase query
  /// 
  /// Returns:
  ///   List<dynamic> containing typed Post and PickPost objects
  /// 
  /// Throws:
  ///   - Exception: If post data is malformed or missing required fields
  Future<List<dynamic>> _mapPosts(List<dynamic> postData) async {
    final posts = <dynamic>[];
    
    for (final post in postData) {
      final postType = post['post_type'] ?? 'text';
      final postId = post['id'];
      
      // Get accurate comment count for this post
      final commentsCount = await _supabase
          .from('comments')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);
      
      final commentsCountValue = commentsCount.count ?? 0;
      
      if (postType == 'pick' && post['picks_data'] != null) {
        // Parse picks data
        List<Pick> picks = [];
        try {
          final picksJson = jsonDecode(post['picks_data']);
          picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
        } catch (e) {
          print('Error parsing picks data: $e');
        }
        
        posts.add(PickPost(
          id: post['id'],
          userId: post['profile_id'] ?? post['user_id'] ?? '',
          username: post['profile']['username'] ?? 'Anonymous',
          content: post['content'],
          timestamp: DateTime.parse(post['created_at']).toLocal(),
          likes: 0, // Will be updated in fetchPosts
          comments: List.generate(commentsCountValue, (index) => Comment(
            id: 'placeholder_$index',
            username: 'placeholder',
            content: 'placeholder',
            timestamp: DateTime.now(),
          )),
          reposts: 0, // Will be updated in fetchPosts
          isLiked: false, // Will be updated in fetchPosts
          isReposted: false, // Will be updated in fetchPosts
          avatarUrl: post['profile']['avatar_url'],
          picks: picks,
        ));
      } else {
        posts.add(Post(
          id: post['id'],
          userId: post['profile_id'] ?? post['user_id'] ?? '',
          username: post['profile']['username'] ?? 'Anonymous',
          content: post['content'],
          timestamp: DateTime.parse(post['created_at']).toLocal(),
          likes: 0, // Will be updated in fetchPosts
          comments: List.generate(commentsCountValue, (index) => Comment(
            id: 'placeholder_$index',
            username: 'placeholder',
            content: 'placeholder',
            timestamp: DateTime.now(),
          )),
          reposts: 0, // Will be updated in fetchPosts
          isLiked: false, // Will be updated in fetchPosts
          isReposted: false, // Will be updated in fetchPosts
          avatarUrl: post['profile']['avatar_url'],
        ));
      }
    }
    
    return posts;
  }

  /// Fetches all posts created by a specific user.
  /// 
  /// Retrieves posts from a user's profile including both regular posts
  /// and betting picks. Used for displaying user profiles and post history.
  /// 
  /// Parameters:
  ///   - userId: ID of the user whose posts to retrieve
  /// 
  /// Returns:
  ///   List<dynamic> containing the user's Post and PickPost objects
  /// 
  /// Throws:
  ///   - Exception: If database query fails or user not found
  Future<List<dynamic>> fetchUserPosts(String userId) async {
    try {
      final response = await _supabase.from('posts').select('''
        *,
        profile:profiles!posts_profile_id_fkey (
          username,
          avatar_url
        )
      ''').eq('profile_id', userId).order('created_at', ascending: false);

      final posts = <dynamic>[];
      
      for (final post in response as List<dynamic>) {
        final postType = post['post_type'] ?? 'text';
        final postId = post['id'];
        
        // Get accurate counts for each post
        final likesCount = await _supabase
            .from('likes')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('post_id', postId);
        
        final commentsCount = await _supabase
            .from('comments')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('post_id', postId);
        
        final repostsCount = await _supabase
            .from('reposts')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('post_id', postId);
        
        final likesCountValue = likesCount.count ?? 0;
        final commentsCountValue = commentsCount.count ?? 0;
        final repostsCountValue = repostsCount.count ?? 0;
        
        if (postType == 'pick' && post['picks_data'] != null) {
          // Parse picks data
          List<Pick> picks = [];
          try {
            final picksJson = jsonDecode(post['picks_data']);
            picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
          } catch (e) {
            print('Error parsing picks data: $e');
          }
          
          posts.add(PickPost(
            id: post['id'],
            userId: post['profile_id'] ?? post['user_id'] ?? '',
            username: post['profile']['username'] ?? 'Anonymous',
            content: post['content'],
            timestamp: DateTime.parse(post['created_at']).toLocal(),
            likes: likesCountValue,
            comments: List.generate(commentsCountValue, (index) => Comment(
              id: 'placeholder_$index',
              username: 'placeholder',
              content: 'placeholder',
              timestamp: DateTime.now(),
            )),
            reposts: repostsCountValue,
            avatarUrl: post['profile']['avatar_url'],
            picks: picks,
          ));
        } else {
          posts.add(Post(
            id: post['id'],
            userId: post['profile_id'] ?? post['user_id'] ?? '',
            username: post['profile']['username'] ?? 'Anonymous',
            content: post['content'],
            timestamp: DateTime.parse(post['created_at']).toLocal(),
            likes: likesCountValue,
            comments: List.generate(commentsCountValue, (index) => Comment(
              id: 'placeholder_$index',
              username: 'placeholder',
              content: 'placeholder',
              timestamp: DateTime.now(),
            )),
            reposts: repostsCountValue,
            avatarUrl: post['profile']['avatar_url'],
          ));
        }
      }
      
      return posts;
    } catch (e) {
      print('Error fetching user posts: $e');
      rethrow;
    }
  }

  /// Creates a new text post in the social feed.
  /// 
  /// Allows users to share thoughts, comments, and reactions with the
  /// WagerLoop community. Posts are displayed in followers' feeds and
  /// can be liked, commented on, and reposted.
  /// 
  /// Parameters:
  ///   - content: Text content of the post
  /// 
  /// Returns:
  ///   Post object representing the newly created post
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or post creation fails
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
        'post_type': 'text',
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
        userId: user.id,
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

  /// Creates a new betting pick post in the social feed.
  /// 
  /// Allows users to share their sports betting picks with the community,
  /// including odds, reasoning, and stake amounts. Pick posts can be
  /// liked, commented on, and serve as a betting history.
  /// 
  /// Parameters:
  ///   - pickPost: PickPost object containing picks and post content
  /// 
  /// Returns:
  ///   PickPost object representing the newly created betting post
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or pick post creation fails
  Future<PickPost> createPickPost(PickPost pickPost) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create post with picks data
      final response = await _supabase.from('posts').insert({
        'user_id': user.id,
        'profile_id': user.id,
        'content': pickPost.content,
        'post_type': 'pick',
        'picks_data': jsonEncode(pickPost.picks.map((pick) => pick.toJson()).toList()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select('''
      *,
      profile:profiles!posts_profile_id_fkey (
        username,
        avatar_url
      )
    ''').single();

      // Create and return a PickPost object with local timestamp
      return PickPost(
        id: response['id'],
        userId: user.id,
        username: profileResponse['username'] ?? 'Anonymous',
        content: response['content'],
        timestamp: DateTime.parse(response['created_at']).toLocal(),
        likes: 0,
        comments: const [],
        reposts: 0,
        avatarUrl: profileResponse['avatar_url'],
        picks: pickPost.picks,
      );
    } catch (e) {
      print('Error creating pick post: $e');
      rethrow;
    }
  }

  /// Adds a comment to a post or pick post.
  /// 
  /// Enables users to engage with posts through comments, fostering
  /// discussion around betting picks and social content.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to comment on
  ///   - content: Text content of the comment
  /// 
  /// Returns:
  ///   Comment object representing the newly created comment
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or comment creation fails
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

  /// Retrieves all comments for a specific post.
  /// 
  /// Fetches comments with user information for display in post threads.
  /// Comments are ordered by creation time to show conversation flow.
  /// 
  /// Parameters:
  ///   - postId: ID of the post whose comments to retrieve
  /// 
  /// Returns:
  ///   List<Comment> containing all comments for the post
  /// 
  /// Throws:
  ///   - Exception: If database query fails
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

  /// Toggles like status for a post or pick post.
  /// 
  /// Allows users to like or unlike posts and betting picks. Updates
  /// like counts and tracks user interactions for feed personalization.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to like/unlike
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or like toggle fails
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

  /// Toggles repost status for a post or pick post.
  /// 
  /// Allows users to repost (share) content to their own feed, amplifying
  /// popular picks and posts within the WagerLoop community.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to repost/unrepost
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or repost toggle fails
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

  /// Fetches all comments made by a specific user.
  /// 
  /// Retrieves comments with associated post information for display
  /// in user profiles. Shows the user's commenting activity across
  /// all posts in the platform.
  /// 
  /// Parameters:
  ///   - userId: ID of the user whose comments to retrieve
  /// 
  /// Returns:
  ///   List<Map<String, dynamic>> containing comment and post information
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<Map<String, dynamic>>> fetchUserComments(String userId) async {
    try {
      final response = await _supabase.from('comments').select('''
        *,
        post:posts!inner (
          id,
          content,
          post_type,
          profile:profiles!posts_profile_id_fkey (
            username,
            avatar_url
          )
        )
      ''').eq('user_id', userId).order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((comment) => {
            'id': comment['id'],
            'content': comment['content'],
            'created_at': comment['created_at'],
            'post_id': comment['post_id'],
            'post_content': comment['post']['content'],
            'post_type': comment['post']['post_type'],
            'post_author': comment['post']['profile']['username'],
            'post_author_avatar': comment['post']['profile']['avatar_url'],
          })
          .toList();
    } catch (e) {
      print('Error fetching user comments: $e');
      rethrow;
    }
  }

  /// Deletes a comment from a post.
  /// 
  /// Allows users to remove their own comments from posts and pick posts.
  /// Only the comment creator can delete their own comments.
  /// 
  /// Parameters:
  ///   - commentId: ID of the comment to delete
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated, not the comment owner, or deletion fails
  Future<void> deleteComment(String commentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Delete the comment (only if user owns it)
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id); // Ensure only owner can delete
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  /// Deletes a post or pick post from the social feed.
  /// 
  /// Removes a post and all associated likes, comments, and reposts.
  /// Only the post creator can delete their own posts.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to delete
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated, not the post owner, or deletion fails
  Future<void> deletePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // First delete all related data
      await _supabase.from('likes').delete().eq('post_id', postId);
      await _supabase.from('comments').delete().eq('post_id', postId);
      await _supabase.from('reposts').delete().eq('post_id', postId);
      
      // Then delete the post (only if user owns it)
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', user.id); // Ensure only owner can delete
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }
}
