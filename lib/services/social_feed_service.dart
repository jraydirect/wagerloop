// Import Supabase Flutter SDK for database operations - provides access to Supabase database and real-time features
import 'package:supabase_flutter/supabase_flutter.dart';
// Import Post model for social posts - provides data structure for regular social posts
import '../models/post.dart';
// Import PickPost model for betting posts - provides data structure for betting pick posts
import '../models/pick_post.dart';
// Import Comment model for post comments - provides data structure for post comments
import '../models/comment.dart';
// Import Dart convert library for JSON operations - provides JSON encoding and decoding
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
  // Supabase client instance for database operations - provides access to database and real-time features
  final SupabaseClient _supabase;

  // Constructor that takes Supabase client - initializes service with database connection
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized access
      if (user == null) throw 'User not authenticated';

      // Simplified approach: Get all recent posts first, then prioritize followed users - fetches posts with user profiles
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

      // Map raw post data to Post/PickPost objects - converts database response to typed objects
      final posts = await _mapPosts(response);
      
      // Fetch like and repost status for current user - determines user's interaction with each post
      for (final post in posts) {
        // Get post ID regardless of post type - extracts unique post identifier
        final postId = post is Post ? post.id : (post as PickPost).id;
        try {
          // Check if user liked this post - queries likes table for user's like status
          final likeExists = await _supabase
              .from('likes')
              .select()
              .eq('post_id', postId)
              .eq('user_id', user.id)
              .maybeSingle();
          
          // Set like status for Post objects - updates Post object with like status
          if (post is Post) {
            post.isLiked = likeExists != null;
          } else if (post is PickPost) {
            // Set like status for PickPost objects - updates PickPost object with like status
            post.isLiked = likeExists != null;
          }

          // Check if user reposted this post - queries reposts table for user's repost status
          final repostExists = await _supabase
              .from('reposts')
              .select()
              .eq('post_id', postId)
              .eq('user_id', user.id)
              .maybeSingle();
          
          // Set repost status for Post objects - updates Post object with repost status
          if (post is Post) {
            post.isReposted = repostExists != null;
          } else if (post is PickPost) {
            // Set repost status for PickPost objects - updates PickPost object with repost status
            post.isReposted = repostExists != null;
          }

          // Get actual like count - queries likes table for total like count
          final likesCount = await _supabase
              .from('likes')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', postId);
          
          // Set like count for Post objects - updates Post object with like count
          if (post is Post) {
            post.likes = likesCount.count ?? 0;
          } else if (post is PickPost) {
            // Set like count for PickPost objects - updates PickPost object with like count
            post.likes = likesCount.count ?? 0;
          }

          // Get actual repost count - queries reposts table for total repost count
          final repostsCount = await _supabase
              .from('reposts')
              .select('id', const FetchOptions(count: CountOption.exact))
              .eq('post_id', postId);
          
          // Set repost count for Post objects - updates Post object with repost count
          if (post is Post) {
            post.reposts = repostsCount.count ?? 0;
          } else if (post is PickPost) {
            // Set repost count for PickPost objects - updates PickPost object with repost count
            post.reposts = repostsCount.count ?? 0;
          }
        } catch (e) {
          // Print error if checking like/repost status fails - logs interaction status errors
          print('Error checking like/repost status: $e');
        }
      }

      // Return the processed posts - provides posts with complete interaction data
      return posts;
    } catch (e) {
      // Print error if fetching posts fails - logs post fetching errors
      print('Error fetching posts: $e');
      // Re-throw the error - allows calling code to handle the error
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
    // Map each post data to appropriate object type - converts database records to typed objects
    return postData.map((post) {
      // Get post type from data - determines if post is regular text or betting pick
      final postType = post['post_type'] ?? 'text';
      
      // Handle pick posts with embedded sports picks - processes betting pick posts
      if (postType == 'pick' && post['picks_data'] != null) {
        // Parse picks data from JSON - converts JSON string to Pick objects
        List<Pick> picks = [];
        try {
          // Decode JSON picks data - converts JSON string to Dart objects
          final picksJson = jsonDecode(post['picks_data']);
          // Convert JSON to Pick objects - creates typed Pick objects from JSON
          picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
        } catch (e) {
          // Print error if parsing picks data fails - logs JSON parsing errors
          print('Error parsing picks data: $e');
        }
        
        // Return PickPost object - creates PickPost with embedded sports picks
        return PickPost(
          id: post['id'],
          userId: post['profile_id'] ?? post['user_id'] ?? '',
          username: post['profile']['username'] ?? 'Anonymous',
          content: post['content'],
          timestamp: DateTime.parse(post['created_at']).toLocal(),
          likes: 0, // Will be updated in fetchPosts
          comments: const [],
          reposts: 0, // Will be updated in fetchPosts
          isLiked: false, // Will be updated in fetchPosts
          isReposted: false, // Will be updated in fetchPosts
          avatarUrl: post['profile']['avatar_url'],
          picks: picks,
        );
      } else {
        // Return regular Post object - creates regular text post
        return Post(
          id: post['id'],
          userId: post['profile_id'] ?? post['user_id'] ?? '',
          username: post['profile']['username'] ?? 'Anonymous',
          content: post['content'],
          timestamp: DateTime.parse(post['created_at']).toLocal(),
          likes: 0, // Will be updated in fetchPosts
          comments: const [],
          reposts: 0, // Will be updated in fetchPosts
          isLiked: false, // Will be updated in fetchPosts
          isReposted: false, // Will be updated in fetchPosts
          avatarUrl: post['profile']['avatar_url'],
        );
      }
    }).toList();
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
      // Query posts for specific user with counts - fetches posts with interaction counts
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

      // Map response to Post/PickPost objects - converts database response to typed objects
      return (response as List<dynamic>)
          .map((post) {
            // Get post type from data - determines if post is regular text or betting pick
            final postType = post['post_type'] ?? 'text';
            
            // Handle pick posts with embedded sports picks - processes betting pick posts
            if (postType == 'pick' && post['picks_data'] != null) {
              // Parse picks data from JSON - converts JSON string to Pick objects
              List<Pick> picks = [];
              try {
                // Decode JSON picks data - converts JSON string to Dart objects
                final picksJson = jsonDecode(post['picks_data']);
                // Convert JSON to Pick objects - creates typed Pick objects from JSON
                picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
              } catch (e) {
                // Print error if parsing picks data fails - logs JSON parsing errors
                print('Error parsing picks data: $e');
              }
              
              // Return PickPost object with counts - creates PickPost with interaction counts
              return PickPost(
                id: post['id'],
                userId: post['profile_id'] ?? post['user_id'] ?? '',
                username: post['profile']['username'] ?? 'Anonymous',
                content: post['content'],
                timestamp: DateTime.parse(post['created_at']).toLocal(),
                likes: (post['likes'] as List).isNotEmpty
                    ? (post['likes'][0]['count'] ?? 0)
                    : 0,
                comments: const [],
                reposts: (post['reposts'] as List).isNotEmpty
                    ? (post['reposts'][0]['count'] ?? 0)
                    : 0,
                avatarUrl: post['profile']['avatar_url'],
                picks: picks,
              );
            } else {
              // Return regular Post object with counts - creates Post with interaction counts
              return Post(
                id: post['id'],
                userId: post['profile_id'] ?? post['user_id'] ?? '',
                username: post['profile']['username'] ?? 'Anonymous',
                content: post['content'],
                timestamp: DateTime.parse(post['created_at']).toLocal(),
                likes: (post['likes'] as List).isNotEmpty
                    ? (post['likes'][0]['count'] ?? 0)
                    : 0,
                comments: const [],
                reposts: (post['reposts'] as List).isNotEmpty
                    ? (post['reposts'][0]['count'] ?? 0)
                    : 0,
                avatarUrl: post['profile']['avatar_url'],
              );
            }
          })
          .toList();
    } catch (e) {
      // Print error if fetching user posts fails - logs user post fetching errors
      print('Error fetching user posts: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized post creation
      if (user == null) throw 'User not authenticated';

      // Get the user's profile information - retrieves user profile data
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create post with current timestamp in UTC - inserts new post into database
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

      // Create and return a Post object with local timestamp - creates typed Post object
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
      // Print error if creating post fails - logs post creation errors
      print('Error creating post: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized pick post creation
      if (user == null) throw 'User not authenticated';

      // Get the user's profile information - retrieves user profile data
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create post with picks data encoded as JSON - inserts new pick post into database
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

      // Create and return a PickPost object with local timestamp - creates typed PickPost object
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
      // Print error if creating pick post fails - logs pick post creation errors
      print('Error creating pick post: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized comment creation
      if (user == null) throw 'User not authenticated';

      // Get the user's profile first - retrieves user profile data
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Insert comment into database - creates new comment record
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

      // Return Comment object - creates typed Comment object
      return Comment(
        id: response['id'],
        username: profileResponse['username'] ?? 'Anonymous',
        content: response['content'],
        timestamp: DateTime.parse(response['created_at']),
        likes: 0,
        avatarUrl: profileResponse['avatar_url'],
      );
    } catch (e) {
      // Print error if adding comment fails - logs comment creation errors
      print('Error adding comment: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Query comments with user profile information - fetches comments with user data
      final response = await _supabase.from('comments').select('''
            *,
            profile:profiles!inner (
              username,
              avatar_url
            )
          ''').eq('post_id', postId).order('created_at', ascending: true);

      // Map response to Comment objects - converts database response to typed objects
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
      // Print error if fetching comments fails - logs comment fetching errors
      print('Error fetching comments: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized like operations
      if (user == null) throw 'User not authenticated';

      // Check if user already liked the post - queries likes table for existing like
      final exists = await _supabase
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      // If not liked, add like - creates new like record
      if (exists == null) {
        await _supabase.from('likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // If already liked, remove like - deletes existing like record
        await _supabase
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Print error if toggling like fails - logs like toggle errors
      print('Error toggling like: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized repost operations
      if (user == null) throw 'User not authenticated';

      // Check if user already reposted the post - queries reposts table for existing repost
      final exists = await _supabase
          .from('reposts')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      // If not reposted, add repost - creates new repost record
      if (exists == null) {
        await _supabase.from('reposts').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // If already reposted, remove repost - deletes existing repost record
        await _supabase
            .from('reposts')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      // Print error if toggling repost fails - logs repost toggle errors
      print('Error toggling repost: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = _supabase.auth.currentUser;
      // Throw error if user is not authenticated - prevents unauthorized post deletion
      if (user == null) throw 'User not authenticated';

      // First delete all related data (likes, comments, reposts) - removes all associated interactions
      await _supabase.from('likes').delete().eq('post_id', postId);
      await _supabase.from('comments').delete().eq('post_id', postId);
      await _supabase.from('reposts').delete().eq('post_id', postId);
      
      // Then delete the post (only if user owns it) - removes the main post record
      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', user.id); // Ensure only owner can delete
    } catch (e) {
      // Print error if deleting post fails - logs post deletion errors
      print('Error deleting post: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }
}
