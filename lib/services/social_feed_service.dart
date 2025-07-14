import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for database operations
import '../models/post.dart'; // Import Post model class
import '../models/pick_post.dart'; // Import PickPost model class and Pick class
import '../models/comment.dart'; // Import Comment model class
import 'dart:convert'; // Import Dart's convert library for JSON encoding/decoding

/// Manages social media functionality for WagerLoop.
/// 
/// Handles post creation, retrieval, and interactions including likes,
/// comments, and reposts. Supports both regular text posts and betting
/// pick posts with embedded sports picks and odds.
/// 
/// Integrates with Supabase for real-time social feed updates and
/// user interaction tracking.
class SocialFeedService { // Define SocialFeedService class to handle social media functionality
  final SupabaseClient _supabase; // Declare final field for Supabase client instance

  SocialFeedService(this._supabase); // Constructor that takes Supabase client as parameter

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
  Future<List<dynamic>> fetchPosts({int limit = 20, int offset = 0}) async { // Define async method to fetch posts with pagination
    try { // Begin try block for post fetching error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      // Simplified approach: Get all recent posts first, then prioritize followed users
      final response = await _supabase // Query posts table
          .from('posts') // From posts table
          .select(''' // Select posts with user profile information
          *,
          profile:profiles!posts_profile_id_fkey (
            id, username, avatar_url
          )
        ''') // End of select statement
          .order('created_at', ascending: false) // Order by creation date, newest first
          .limit(limit) // Limit to specified number of posts
          .range(offset, offset + limit - 1); // Apply pagination range

      final posts = await _mapPosts(response); // Map raw database response to Post/PickPost objects
      
      // Fetch like and repost status for current user
      for (final post in posts) { // Iterate through each post to check user interactions
        final postId = post is Post ? post.id : (post as PickPost).id; // Get post ID regardless of type
        try { // Begin try block for interaction status checking
          // Check if user liked this post
          final likeExists = await _supabase // Query likes table
              .from('likes') // From likes table
              .select() // Select all fields
              .eq('post_id', postId) // Filter by post ID
              .eq('user_id', user.id) // Filter by current user ID
              .maybeSingle(); // Get single result or null
          
          if (post is Post) { // Check if post is a regular Post
            post.isLiked = likeExists != null; // Set liked status based on query result
          } else if (post is PickPost) { // Check if post is a PickPost
            post.isLiked = likeExists != null; // Set liked status based on query result
          } // End of post type check

          // Check if user reposted this post
          final repostExists = await _supabase // Query reposts table
              .from('reposts') // From reposts table
              .select() // Select all fields
              .eq('post_id', postId) // Filter by post ID
              .eq('user_id', user.id) // Filter by current user ID
              .maybeSingle(); // Get single result or null
          
          if (post is Post) { // Check if post is a regular Post
            post.isReposted = repostExists != null; // Set reposted status based on query result
          } else if (post is PickPost) { // Check if post is a PickPost
            post.isReposted = repostExists != null; // Set reposted status based on query result
          } // End of post type check

          // Get actual counts
          final likesCount = await _supabase // Query likes count
              .from('likes') // From likes table
              .select('id', const FetchOptions(count: CountOption.exact)) // Select with exact count
              .eq('post_id', postId); // Filter by post ID
          
          if (post is Post) { // Check if post is a regular Post
            post.likes = likesCount.count ?? 0; // Set likes count or default to 0
          } else if (post is PickPost) { // Check if post is a PickPost
            post.likes = likesCount.count ?? 0; // Set likes count or default to 0
          } // End of post type check

          final repostsCount = await _supabase // Query reposts count
              .from('reposts') // From reposts table
              .select('id', const FetchOptions(count: CountOption.exact)) // Select with exact count
              .eq('post_id', postId); // Filter by post ID
          
          if (post is Post) { // Check if post is a regular Post
            post.reposts = repostsCount.count ?? 0; // Set reposts count or default to 0
          } else if (post is PickPost) { // Check if post is a PickPost
            post.reposts = repostsCount.count ?? 0; // Set reposts count or default to 0
          } // End of post type check
        } catch (e) { // Catch interaction status checking errors
          print('Error checking like/repost status: $e'); // Log interaction status error
        } // End of interaction status try-catch
      } // End of posts iteration

      return posts; // Return list of posts with interaction status
    } catch (e) { // Catch post fetching errors
      print('Error fetching posts: $e'); // Log post fetching error
      rethrow; // Rethrow error to caller
    } // End of post fetching try-catch
  } // End of fetchPosts method

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
  Future<List<dynamic>> _mapPosts(List<dynamic> postData) async { // Define async method to map raw post data to objects
    return postData.map((post) { // Map each raw post to a typed object
      final postType = post['post_type'] ?? 'text'; // Extract post type or default to 'text'
      
      if (postType == 'pick' && post['picks_data'] != null) { // Check if post is a pick post with picks data
        // Parse picks data
        List<Pick> picks = []; // Initialize empty picks list
        try { // Begin try block for picks data parsing
          final picksJson = jsonDecode(post['picks_data']); // Decode JSON picks data
          picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList(); // Map JSON to Pick objects
        } catch (e) { // Catch picks data parsing errors
          print('Error parsing picks data: $e'); // Log picks parsing error
        } // End of picks parsing try-catch
        
        return PickPost( // Create PickPost object
          id: post['id'], // Set post ID
          userId: post['profile_id'] ?? post['user_id'] ?? '', // Set user ID with fallback
          username: post['profile']['username'] ?? 'Anonymous', // Set username with fallback
          content: post['content'], // Set post content
          timestamp: DateTime.parse(post['created_at']).toLocal(), // Parse and convert timestamp to local time
          likes: 0, // Initialize likes count (will be updated in fetchPosts)
          comments: const [], // Initialize empty comments list
          reposts: 0, // Initialize reposts count (will be updated in fetchPosts)
          isLiked: false, // Initialize liked status (will be updated in fetchPosts)
          isReposted: false, // Initialize reposted status (will be updated in fetchPosts)
          avatarUrl: post['profile']['avatar_url'], // Set avatar URL
          picks: picks, // Set parsed picks
        ); // End of PickPost constructor
      } else { // If post is a regular text post
        return Post( // Create Post object
          id: post['id'], // Set post ID
          userId: post['profile_id'] ?? post['user_id'] ?? '', // Set user ID with fallback
          username: post['profile']['username'] ?? 'Anonymous', // Set username with fallback
          content: post['content'], // Set post content
          timestamp: DateTime.parse(post['created_at']).toLocal(), // Parse and convert timestamp to local time
          likes: 0, // Initialize likes count (will be updated in fetchPosts)
          comments: const [], // Initialize empty comments list
          reposts: 0, // Initialize reposts count (will be updated in fetchPosts)
          isLiked: false, // Initialize liked status (will be updated in fetchPosts)
          isReposted: false, // Initialize reposted status (will be updated in fetchPosts)
          avatarUrl: post['profile']['avatar_url'], // Set avatar URL
        ); // End of Post constructor
      } // End of post type check
    }).toList(); // Convert mapped results to list
  } // End of _mapPosts method

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
  Future<List<dynamic>> fetchUserPosts(String userId) async { // Define async method to fetch posts by specific user
    try { // Begin try block for user posts fetching error handling
      final response = await _supabase.from('posts').select(''' // Query posts table with counts
        *,
        profile:profiles!posts_profile_id_fkey (
          username,
          avatar_url
        ),
        likes(count),
        comments(count),
        reposts(count)
      ''').eq('profile_id', userId).order('created_at', ascending: false); // Filter by user ID and order by date

      return (response as List<dynamic>) // Cast response to list
          .map((post) { // Map each post to appropriate object type
            final postType = post['post_type'] ?? 'text'; // Extract post type or default to 'text'
            
            if (postType == 'pick' && post['picks_data'] != null) { // Check if post is a pick post with picks data
              // Parse picks data
              List<Pick> picks = []; // Initialize empty picks list
              try { // Begin try block for picks data parsing
                final picksJson = jsonDecode(post['picks_data']); // Decode JSON picks data
                picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList(); // Map JSON to Pick objects
              } catch (e) { // Catch picks data parsing errors
                print('Error parsing picks data: $e'); // Log picks parsing error
              } // End of picks parsing try-catch
              
              return PickPost( // Create PickPost object
                id: post['id'], // Set post ID
                userId: post['profile_id'] ?? post['user_id'] ?? '', // Set user ID with fallback
                username: post['profile']['username'] ?? 'Anonymous', // Set username with fallback
                content: post['content'], // Set post content
                timestamp: DateTime.parse(post['created_at']).toLocal(), // Parse and convert timestamp to local time
                likes: (post['likes'] as List).isNotEmpty // Check if likes list is not empty
                    ? (post['likes'][0]['count'] ?? 0) // Get likes count from first element or default to 0
                    : 0, // Default to 0 if likes list is empty
                comments: const [], // Initialize empty comments list
                reposts: (post['reposts'] as List).isNotEmpty // Check if reposts list is not empty
                    ? (post['reposts'][0]['count'] ?? 0) // Get reposts count from first element or default to 0
                    : 0, // Default to 0 if reposts list is empty
                avatarUrl: post['profile']['avatar_url'], // Set avatar URL
                picks: picks, // Set parsed picks
              ); // End of PickPost constructor
            } else { // If post is a regular text post
              return Post( // Create Post object
                id: post['id'], // Set post ID
                userId: post['profile_id'] ?? post['user_id'] ?? '', // Set user ID with fallback
                username: post['profile']['username'] ?? 'Anonymous', // Set username with fallback
                content: post['content'], // Set post content
                timestamp: DateTime.parse(post['created_at']).toLocal(), // Parse and convert timestamp to local time
                likes: (post['likes'] as List).isNotEmpty // Check if likes list is not empty
                    ? (post['likes'][0]['count'] ?? 0) // Get likes count from first element or default to 0
                    : 0, // Default to 0 if likes list is empty
                comments: const [], // Initialize empty comments list
                reposts: (post['reposts'] as List).isNotEmpty // Check if reposts list is not empty
                    ? (post['reposts'][0]['count'] ?? 0) // Get reposts count from first element or default to 0
                    : 0, // Default to 0 if reposts list is empty
                avatarUrl: post['profile']['avatar_url'], // Set avatar URL
              ); // End of Post constructor
            } // End of post type check
          }) // End of map function
          .toList(); // Convert mapped results to list
    } catch (e) { // Catch user posts fetching errors
      print('Error fetching user posts: $e'); // Log user posts fetching error
      rethrow; // Rethrow error to caller
    } // End of user posts fetching try-catch
  } // End of fetchUserPosts method

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
  Future<Post> createPost(String content) async { // Define async method to create a new text post
    try { // Begin try block for post creation error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      // Get the user's profile
      final profileResponse = await _supabase // Query user's profile
          .from('profiles') // From profiles table
          .select('username, avatar_url') // Select username and avatar URL
          .eq('id', user.id) // Filter by user ID
          .single(); // Get single result

      // Create post with current timestamp in UTC
      final response = await _supabase.from('posts').insert({ // Insert new post
        'user_id': user.id, // Set user ID
        'profile_id': user.id, // Set profile ID
        'content': content, // Set post content
        'post_type': 'text', // Set post type to text
        'created_at': DateTime.now().toUtc().toIso8601String(), // Set creation timestamp in UTC
        'updated_at': DateTime.now().toUtc().toIso8601String(), // Set update timestamp in UTC
      }).select(''' // Select inserted post with profile information
      *,
      profile:profiles!posts_profile_id_fkey (
        username,
        avatar_url
      )
    ''').single(); // Get single result

      // Create and return a Post object with local timestamp
      return Post( // Create Post object
        id: response['id'], // Set post ID from response
        userId: user.id, // Set user ID
        username: profileResponse['username'] ?? 'Anonymous', // Set username with fallback
        content: response['content'], // Set content from response
        timestamp: DateTime.parse(response['created_at']).toLocal(), // Parse and convert timestamp to local time
        likes: 0, // Initialize likes count to 0
        comments: const [], // Initialize empty comments list
        reposts: 0, // Initialize reposts count to 0
        avatarUrl: profileResponse['avatar_url'], // Set avatar URL
      ); // End of Post constructor
    } catch (e) { // Catch post creation errors
      print('Error creating post: $e'); // Log post creation error
      rethrow; // Rethrow error to caller
    } // End of post creation try-catch
  } // End of createPost method

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
  Future<PickPost> createPickPost(PickPost pickPost) async { // Define async method to create a new pick post
    try { // Begin try block for pick post creation error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      // Get the user's profile
      final profileResponse = await _supabase // Query user's profile
          .from('profiles') // From profiles table
          .select('username, avatar_url') // Select username and avatar URL
          .eq('id', user.id) // Filter by user ID
          .single(); // Get single result

      // Create post with picks data
      final response = await _supabase.from('posts').insert({ // Insert new pick post
        'user_id': user.id, // Set user ID
        'profile_id': user.id, // Set profile ID
        'content': pickPost.content, // Set post content
        'post_type': 'pick', // Set post type to pick
        'picks_data': jsonEncode(pickPost.picks.map((pick) => pick.toJson()).toList()), // Encode picks as JSON
        'created_at': DateTime.now().toUtc().toIso8601String(), // Set creation timestamp in UTC
        'updated_at': DateTime.now().toUtc().toIso8601String(), // Set update timestamp in UTC
      }).select(''' // Select inserted post with profile information
      *,
      profile:profiles!posts_profile_id_fkey (
        username,
        avatar_url
      )
    ''').single(); // Get single result

      // Create and return a PickPost object with local timestamp
      return PickPost( // Create PickPost object
        id: response['id'], // Set post ID from response
        userId: user.id, // Set user ID
        username: profileResponse['username'] ?? 'Anonymous', // Set username with fallback
        content: response['content'], // Set content from response
        timestamp: DateTime.parse(response['created_at']).toLocal(), // Parse and convert timestamp to local time
        likes: 0, // Initialize likes count to 0
        comments: const [], // Initialize empty comments list
        reposts: 0, // Initialize reposts count to 0
        avatarUrl: profileResponse['avatar_url'], // Set avatar URL
        picks: pickPost.picks, // Set picks from input
      ); // End of PickPost constructor
    } catch (e) { // Catch pick post creation errors
      print('Error creating pick post: $e'); // Log pick post creation error
      rethrow; // Rethrow error to caller
    } // End of pick post creation try-catch
  } // End of createPickPost method

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
  Future<Comment> addComment(String postId, String content) async { // Define async method to add comment to post
    try { // Begin try block for comment creation error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      // Get the user's profile first
      final profileResponse = await _supabase // Query user's profile
          .from('profiles') // From profiles table
          .select('username, avatar_url') // Select username and avatar URL
          .eq('id', user.id) // Filter by user ID
          .single(); // Get single result

      final response = await _supabase // Insert new comment
          .from('comments') // Into comments table
          .insert({ // Insert comment data
            'post_id': postId, // Set post ID
            'user_id': user.id, // Set user ID
            'content': content, // Set comment content
            'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
            'updated_at': DateTime.now().toIso8601String(), // Set update timestamp
          }) // End of insert data
          .select() // Select inserted comment
          .single(); // Get single result

      return Comment( // Create Comment object
        id: response['id'], // Set comment ID from response
        username: profileResponse['username'] ?? 'Anonymous', // Set username with fallback
        content: response['content'], // Set content from response
        timestamp: DateTime.parse(response['created_at']), // Parse timestamp
        likes: 0, // Initialize likes count to 0
        avatarUrl: profileResponse['avatar_url'], // Set avatar URL
      ); // End of Comment constructor
    } catch (e) { // Catch comment creation errors
      print('Error adding comment: $e'); // Log comment creation error
      rethrow; // Rethrow error to caller
    } // End of comment creation try-catch
  } // End of addComment method

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
  Future<List<Comment>> fetchComments(String postId) async { // Define async method to fetch comments for a post
    try { // Begin try block for comments fetching error handling
      final response = await _supabase.from('comments').select(''' // Query comments with user information
            *,
            profile:profiles!inner (
              username,
              avatar_url
            )
          ''').eq('post_id', postId).order('created_at', ascending: true); // Filter by post ID and order by creation time

      return (response as List<dynamic>) // Cast response to list
          .map((comment) => Comment( // Map each comment to Comment object
                id: comment['id'], // Set comment ID
                username: comment['profile']['username'] ?? 'Anonymous', // Set username with fallback
                content: comment['content'], // Set comment content
                timestamp: DateTime.parse(comment['created_at']), // Parse timestamp
                likes: 0, // Initialize likes count to 0
                avatarUrl: comment['profile']['avatar_url'], // Set avatar URL
              )) // End of Comment constructor
          .toList(); // Convert mapped results to list
    } catch (e) { // Catch comments fetching errors
      print('Error fetching comments: $e'); // Log comments fetching error
      rethrow; // Rethrow error to caller
    } // End of comments fetching try-catch
  } // End of fetchComments method

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
  Future<void> toggleLike(String postId) async { // Define async method to toggle like status
    try { // Begin try block for like toggle error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      final exists = await _supabase // Check if like already exists
          .from('likes') // From likes table
          .select() // Select all fields
          .eq('post_id', postId) // Filter by post ID
          .eq('user_id', user.id) // Filter by user ID
          .maybeSingle(); // Get single result or null

      if (exists == null) { // Check if like doesn't exist
        await _supabase.from('likes').insert({ // Insert new like
          'post_id': postId, // Set post ID
          'user_id': user.id, // Set user ID
          'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
        }); // End of insert data
      } else { // If like exists
        await _supabase // Delete existing like
            .from('likes') // From likes table
            .delete() // Delete operation
            .eq('post_id', postId) // Filter by post ID
            .eq('user_id', user.id); // Filter by user ID
      } // End of like existence check
    } catch (e) { // Catch like toggle errors
      print('Error toggling like: $e'); // Log like toggle error
      rethrow; // Rethrow error to caller
    } // End of like toggle try-catch
  } // End of toggleLike method

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
  Future<void> toggleRepost(String postId) async { // Define async method to toggle repost status
    try { // Begin try block for repost toggle error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      final exists = await _supabase // Check if repost already exists
          .from('reposts') // From reposts table
          .select() // Select all fields
          .eq('post_id', postId) // Filter by post ID
          .eq('user_id', user.id) // Filter by user ID
          .maybeSingle(); // Get single result or null

      if (exists == null) { // Check if repost doesn't exist
        await _supabase.from('reposts').insert({ // Insert new repost
          'post_id': postId, // Set post ID
          'user_id': user.id, // Set user ID
          'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
        }); // End of insert data
      } else { // If repost exists
        await _supabase // Delete existing repost
            .from('reposts') // From reposts table
            .delete() // Delete operation
            .eq('post_id', postId) // Filter by post ID
            .eq('user_id', user.id); // Filter by user ID
      } // End of repost existence check
    } catch (e) { // Catch repost toggle errors
      print('Error toggling repost: $e'); // Log repost toggle error
      rethrow; // Rethrow error to caller
    } // End of repost toggle try-catch
  } // End of toggleRepost method

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
  Future<void> deletePost(String postId) async { // Define async method to delete a post
    try { // Begin try block for post deletion error handling
      final user = _supabase.auth.currentUser; // Get current authenticated user
      if (user == null) throw 'User not authenticated'; // Throw error if user not authenticated

      // First delete all related data
      await _supabase.from('likes').delete().eq('post_id', postId); // Delete all likes for the post
      await _supabase.from('comments').delete().eq('post_id', postId); // Delete all comments for the post
      await _supabase.from('reposts').delete().eq('post_id', postId); // Delete all reposts for the post
      
      // Then delete the post (only if user owns it)
      await _supabase // Delete the post
          .from('posts') // From posts table
          .delete() // Delete operation
          .eq('id', postId) // Filter by post ID
          .eq('user_id', user.id); // Ensure only owner can delete (filter by user ID)
    } catch (e) { // Catch post deletion errors
      print('Error deleting post: $e'); // Log post deletion error
      rethrow; // Rethrow error to caller
    } // End of post deletion try-catch
  } // End of deletePost method
} // End of SocialFeedService class
