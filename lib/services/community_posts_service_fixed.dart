// lib/services/community_posts_service_fixed.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post.dart';
import '../models/community_post_comment.dart';
import 'image_upload_service.dart';
import 'dart:typed_data';

/// Fixed version of CommunityPostsService with proper like persistence
/// 
/// This version ensures that:
/// 1. Like status persists after page refresh
/// 2. Like counts are updated properly
/// 3. Community likes remain separate from profile likes
/// 4. Real-time updates work correctly
class CommunityPostsServiceFixed {
  final SupabaseClient _supabase;

  CommunityPostsServiceFixed(this._supabase);

  /// Fetches posts for a specific community with accurate user interaction status.
  /// 
  /// This method ensures that like status is properly fetched from the database
  /// and persists across page refreshes.
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to fetch posts from
  ///   - limit: Maximum number of posts to retrieve (default: 20)
  ///   - offset: Number of posts to skip for pagination (default: 0)
  /// 
  /// Returns:
  ///   List<CommunityPost> containing posts with accurate interaction status
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or database query fails
  Future<List<CommunityPost>> fetchCommunityPosts({
    required String communityId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Fetching community posts for community: $communityId, user: ${user.id}');

      // Fetch posts from the community with proper joins for like status
      final response = await _supabase
          .from('community_posts')
          .select('''
            *,
            community_post_likes!left (
              id,
              user_id
            )
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      print('Raw response: $response');

      final posts = <CommunityPost>[];

      for (final postData in response) {
        final postId = postData['id'];
        
        // Check like status more reliably
        bool isLiked = false;
        int likeCount = 0;
        
        // Method 1: Check if user liked this post (most reliable)
        final userLike = await _supabase
            .from('community_post_likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', user.id)
            .maybeSingle();
        
        isLiked = userLike != null;
        
        // Method 2: Get accurate like count
        final likesResponse = await _supabase
            .from('community_post_likes')
            .select('id', const FetchOptions(count: CountOption.exact))
            .eq('post_id', postId);
        
        likeCount = likesResponse.count ?? 0;
        
        print('Post $postId: isLiked=$isLiked, likeCount=$likeCount');

        // Create post object with accurate interaction status
        final post = CommunityPost.fromJson({
          ...postData,
          'is_liked': isLiked, // Override with accurate data
          'like_count': likeCount, // Override with accurate count
        });

        posts.add(post);
      }

      print('Returning ${posts.length} posts');
      return posts;
    } catch (e) {
      print('Error in fetchCommunityPosts: $e');
      throw Exception('Failed to fetch community posts: $e');
    }
  }

  /// Toggles like status on a community post with proper state management.
  /// 
  /// This method ensures that:
  /// 1. The like is properly added/removed from database
  /// 2. Like counts are updated via database triggers
  /// 3. The like status persists after page refresh
  /// 4. Optimistic UI updates work correctly
  /// 
  /// Parameters:
  ///   - postId: ID of the post to like/unlike
  /// 
  /// Returns:
  ///   Map<String, dynamic> containing the new like status and count
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or operation fails
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      print('Toggling like for post: $postId, user: ${user.id}');

      // Check current like status
      final existingLike = await _supabase
          .from('community_post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      bool newLikeStatus;
      
      if (existingLike != null) {
        // Unlike the post
        print('Removing like...');
        await _supabase
            .from('community_post_likes')
            .delete()
            .eq('id', existingLike['id']);
        newLikeStatus = false;
      } else {
        // Like the post
        print('Adding like...');
        await _supabase.from('community_post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        newLikeStatus = true;
      }

      // Get updated like count (the database trigger should have updated it)
      final likesResponse = await _supabase
          .from('community_post_likes')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);
      
      final newLikeCount = likesResponse.count ?? 0;
      
      print('Toggle complete: isLiked=$newLikeStatus, likeCount=$newLikeCount');

      return {
        'isLiked': newLikeStatus,
        'likeCount': newLikeCount,
      };
    } catch (e) {
      print('Error in toggleLike: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Creates a new chat post in a community.
  /// 
  /// Allows community members to share text-based discussions,
  /// questions, and announcements within the community.
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to post in
  ///   - content: Text content of the post
  /// 
  /// Returns:
  ///   CommunityPost object representing the newly created post
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or post creation fails
  Future<CommunityPost> createChatPost({
    required String communityId,
    required String content,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create post creator
      final creator = CommunityPostCreator(
        communityId: communityId,
        postType: CommunityPostType.chat,
        content: content,
      );

      // Validate post data
      final validationError = creator.validate();
      if (validationError != null) {
        throw validationError;
      }

      // Create post in database
      final response = await _supabase.from('community_posts').insert(
        creator.toCreateJson(
          userId: user.id,
          username: profileResponse['username'] ?? 'Anonymous',
          userAvatarUrl: profileResponse['avatar_url'],
        ),
      ).select().single();

      return CommunityPost.fromJson({...response, 'is_liked': false});
    } catch (e) {
      throw Exception('Failed to create chat post: $e');
    }
  }

  /// Creates a new image post in a community.
  /// 
  /// Allows community members to share images with optional captions.
  /// Handles image upload to storage and creates the post with media URL.
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to post in
  ///   - content: Caption/description for the image (optional)
  ///   - imageBytes: Raw image data to upload
  ///   - mimeType: MIME type of the image
  /// 
  /// Returns:
  ///   CommunityPost object representing the newly created image post
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated, upload fails, or post creation fails
  Future<CommunityPost> createImagePost({
    required String communityId,
    String content = '',
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Upload image to storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'community_${communityId}_${user.id}_$timestamp.jpg';
      
      print('Attempting to upload community image: $fileName');
      
      // Use a different storage bucket for community media
      final imageUrl = await _uploadCommunityMedia(imageBytes, fileName);
      
      if (imageUrl == null || imageUrl.isEmpty) {
        throw 'Failed to upload image to storage';
      }
      
      print('Successfully uploaded image: $imageUrl');

      // Create post creator
      final creator = CommunityPostCreator(
        communityId: communityId,
        postType: CommunityPostType.image,
        content: content,
        mediaUrl: imageUrl,
        mediaFileSize: imageBytes.length,
        mediaMimeType: mimeType,
      );

      // Validate post data
      final validationError = creator.validate();
      if (validationError != null) {
        throw validationError;
      }

      // Create post in database
      final response = await _supabase.from('community_posts').insert(
        creator.toCreateJson(
          userId: user.id,
          username: profileResponse['username'] ?? 'Anonymous',
          userAvatarUrl: profileResponse['avatar_url'],
        ),
      ).select().single();

      return CommunityPost.fromJson({...response, 'is_liked': false});
    } catch (e) {
      throw Exception('Failed to create image post: $e');
    }
  }

  /// Creates a new video post in a community.
  /// 
  /// Allows community members to share videos with optional captions.
  /// Handles video upload to storage and creates the post with media URL.
  /// 
  /// Parameters:
  ///   - communityId: ID of the community to post in
  ///   - content: Caption/description for the video (optional)
  ///   - videoBytes: Raw video data to upload
  ///   - mimeType: MIME type of the video
  ///   - thumbnailBytes: Optional thumbnail image data
  /// 
  /// Returns:
  ///   CommunityPost object representing the newly created video post
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated, upload fails, or post creation fails
  Future<CommunityPost> createVideoPost({
    required String communityId,
    String content = '',
    required Uint8List videoBytes,
    required String mimeType,
    Uint8List? thumbnailBytes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Upload video to storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoFileName = 'community_${communityId}_${user.id}_$timestamp.mp4';
      
      final videoUrl = await _uploadCommunityMedia(videoBytes, videoFileName);
      
      if (videoUrl == null) {
        throw 'Failed to upload video';
      }

      // Upload thumbnail if provided
      String? thumbnailUrl;
      if (thumbnailBytes != null) {
        final thumbnailFileName = 'community_${communityId}_${user.id}_${timestamp}_thumb.jpg';
        thumbnailUrl = await _uploadCommunityMedia(thumbnailBytes, thumbnailFileName);
      }

      // Create post creator
      final creator = CommunityPostCreator(
        communityId: communityId,
        postType: CommunityPostType.video,
        content: content,
        mediaUrl: videoUrl,
        mediaThumbnailUrl: thumbnailUrl,
        mediaFileSize: videoBytes.length,
        mediaMimeType: mimeType,
      );

      // Validate post data
      final validationError = creator.validate();
      if (validationError != null) {
        throw validationError;
      }

      // Create post in database
      final response = await _supabase.from('community_posts').insert(
        creator.toCreateJson(
          userId: user.id,
          username: profileResponse['username'] ?? 'Anonymous',
          userAvatarUrl: profileResponse['avatar_url'],
        ),
      ).select().single();

      return CommunityPost.fromJson({...response, 'is_liked': false});
    } catch (e) {
      throw Exception('Failed to create video post: $e');
    }
  }

  /// Adds a comment to a community post.
  /// 
  /// Allows community members to comment on posts within the community.
  /// Supports threaded replies to create nested discussions.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to comment on
  ///   - content: Text content of the comment
  ///   - parentCommentId: Optional ID of parent comment for replies
  ///   - replyToUsername: Optional username being replied to
  /// 
  /// Returns:
  ///   CommunityPostComment object representing the newly created comment
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or comment creation fails
  Future<CommunityPostComment> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    String? replyToUsername,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Get the user's profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .single();

      // Create comment creator
      final creator = CommunityPostCommentCreator(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
        replyToUsername: replyToUsername,
      );

      // Validate comment data
      final validationError = creator.validate();
      if (validationError != null) {
        throw validationError;
      }

      // Create comment in database
      final response = await _supabase.from('community_post_comments').insert(
        creator.toCreateJson(
          userId: user.id,
          username: profileResponse['username'] ?? 'Anonymous',
          userAvatarUrl: profileResponse['avatar_url'],
        ),
      ).select().single();

      return CommunityPostComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Retrieves all comments for a specific community post.
  /// 
  /// Fetches comments with user information for display in post threads.
  /// Comments are ordered by creation time and organized into threaded structure.
  /// 
  /// Parameters:
  ///   - postId: ID of the post whose comments to retrieve
  /// 
  /// Returns:
  ///   List<CommunityPostComment> containing all comments with nested replies
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<CommunityPostComment>> fetchComments(String postId) async {
    try {
      // Fetch all comments for the post (including replies)
      final response = await _supabase
          .from('community_post_comments')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      // Organize comments into threaded structure
      return _organizeCommentsIntoThreads(response);
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Deletes a community post.
  /// 
  /// Removes a community post and all associated data (comments, likes, media).
  /// Only the post creator or community owner can delete posts.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to delete
  ///   - communityId: ID of the community (for permission checking)
  /// 
  /// Returns:
  ///   bool - True if deletion was successful
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or doesn't have permission
  Future<bool> deletePost({
    required String postId,
    required String communityId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Check if user is the post creator or community owner
      final postCheck = await _supabase
          .from('community_posts')
          .select('user_id, media_url')
          .eq('id', postId)
          .single();

      final communityCheck = await _supabase
          .from('communities')
          .select('creator_id')
          .eq('id', communityId)
          .single();

      final isPostCreator = postCheck['user_id'] == user.id;
      final isCommunityOwner = communityCheck['creator_id'] == user.id;

      if (!isPostCreator && !isCommunityOwner) {
        throw 'You do not have permission to delete this post';
      }

      // Delete media file if exists
      if (postCheck['media_url'] != null) {
        await _deleteCommunityMedia(postCheck['media_url']);
      }

      // Delete the post (cascading deletes will handle comments and likes)
      await _supabase
          .from('community_posts')
          .delete()
          .eq('id', postId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Updates a community post.
  /// 
  /// Allows users to edit their own posts. Only content can be updated,
  /// media and post type cannot be changed after creation.
  /// 
  /// Parameters:
  ///   - postId: ID of the post to update
  ///   - newContent: Updated content for the post
  /// 
  /// Returns:
  ///   CommunityPost - Updated post object
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or doesn't own the post
  Future<CommunityPost> updatePost({
    required String postId,
    required String newContent,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Update the post content
      final response = await _supabase
          .from('community_posts')
          .update({
            'content': newContent,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', postId)
          .eq('user_id', user.id) // Ensure user owns the post
          .select()
          .single();

      return CommunityPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  /// Organizes flat comment list into threaded structure.
  /// 
  /// Takes a flat list of comments and organizes them into a threaded
  /// structure with top-level comments and nested replies.
  /// 
  /// Parameters:
  ///   - commentsData: List of comment data from database
  /// 
  /// Returns:
  ///   List<CommunityPostComment> - Organized threaded comments
  List<CommunityPostComment> _organizeCommentsIntoThreads(List<dynamic> commentsData) {
    final allComments = commentsData
        .map<CommunityPostComment>((data) => CommunityPostComment.fromJson(data))
        .toList();

    final topLevelComments = <CommunityPostComment>[];
    final commentMap = <String, CommunityPostComment>{};

    // Create a map of all comments by ID
    for (final comment in allComments) {
      commentMap[comment.id] = comment;
    }

    // Organize into threads
    for (final comment in allComments) {
      if (comment.parentCommentId == null) {
        // Top-level comment
        topLevelComments.add(comment);
      } else {
        // Reply - add to parent's replies list
        final parentComment = commentMap[comment.parentCommentId!];
        if (parentComment != null) {
          // Create a new comment with the reply added
          final updatedReplies = List<CommunityPostComment>.from(parentComment.replies)
            ..add(comment);
          
          final updatedParent = parentComment.copyWith(replies: updatedReplies);
          commentMap[parentComment.id] = updatedParent;
          
          // Update in top-level comments if it's a top-level comment
          final topLevelIndex = topLevelComments.indexWhere((c) => c.id == parentComment.id);
          if (topLevelIndex != -1) {
            topLevelComments[topLevelIndex] = updatedParent;
          }
        }
      }
    }

    return topLevelComments;
  }

  /// Uploads media file to community storage bucket.
  /// 
  /// Parameters:
  ///   - fileBytes: Raw file data
  ///   - fileName: Name for the uploaded file
  /// 
  /// Returns:
  ///   String? - Public URL of uploaded file or null if failed
  Future<String?> _uploadCommunityMedia(Uint8List fileBytes, String fileName) async {
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      print('Uploading to storage - File: $fileName, Size: ${fileBytes.length} bytes');

      // Use the avatars bucket but with a different folder structure for community media
      const bucketName = 'avatars';
      final filePath = 'community_media/$fileName';

      // Upload the file
      final uploadResponse = await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache for 1 hour
              upsert: true,
            ),
          );

      print('Upload response: $uploadResponse');

      // Get the public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      print('Generated public URL: $publicUrl');

      return publicUrl;
    } on StorageException catch (e) {
      print('Storage exception during upload: ${e.message} (${e.statusCode})');
      throw 'Storage error: ${e.message}';
    } catch (e) {
      print('General error during upload: $e');
      throw 'Upload failed: $e';
    }
  }

  /// Deletes media file from storage.
  /// 
  /// Parameters:
  ///   - mediaUrl: URL of the media file to delete
  Future<void> _deleteCommunityMedia(String mediaUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(mediaUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the file path within the storage bucket
      String? filePath;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'storage' && 
            i + 3 < pathSegments.length && 
            pathSegments[i + 2] == 'avatars') {
          filePath = pathSegments.sublist(i + 3).join('/');
          break;
        }
      }
      
      if (filePath != null) {
        await _supabase.storage
            .from('avatars')
            .remove([filePath]);
      }
    } catch (e) {
      print('Failed to delete community media: $e');
      // Don't throw - media deletion failure shouldn't prevent post deletion
    }
  }
}
