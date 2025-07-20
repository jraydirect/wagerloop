// lib/models/community_post.dart
import 'community_post_comment.dart';

/// Represents the type of content in a community post.
/// 
/// Defines the available content types that users can post
/// within communities in WagerLoop.
enum CommunityPostType {
  chat,   // Text-only posts for discussions
  image,  // Posts with image content
  video,  // Posts with video content
}

/// Represents a post within a community.
/// 
/// Contains all information about a community post including
/// the content, media attachments, interactions, and metadata.
/// Supports different post types (chat, image, video) with
/// appropriate data fields for each type.
class CommunityPost {
  final String id;
  final String communityId;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final CommunityPostType postType;
  final String content;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? mediaFileSize; // File size in bytes
  final String? mediaMimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Interaction counts
  int likeCount;
  int commentCount;
  
  // User interaction state
  bool isLiked;
  final List<CommunityPostComment> comments;

  CommunityPost({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.postType,
    required this.content,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaFileSize,
    this.mediaMimeType,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.comments = const [],
  });

  /// Indicates whether this post contains media content.
  /// 
  /// Returns:
  ///   bool - True if the post has media (image or video), false otherwise
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Indicates whether this is an image post.
  /// 
  /// Returns:
  ///   bool - True if the post type is image, false otherwise
  bool get isImagePost => postType == CommunityPostType.image;

  /// Indicates whether this is a video post.
  /// 
  /// Returns:
  ///   bool - True if the post type is video, false otherwise
  bool get isVideoPost => postType == CommunityPostType.video;

  /// Indicates whether this is a chat (text-only) post.
  /// 
  /// Returns:
  ///   bool - True if the post type is chat, false otherwise
  bool get isChatPost => postType == CommunityPostType.chat;

  /// Returns the media file size in a human-readable format.
  /// 
  /// Returns:
  ///   String - Formatted file size (e.g., "2.5 MB") or empty string if no media
  String get formattedFileSize {
    if (mediaFileSize == null) return '';
    
    final sizeInMB = mediaFileSize! / (1024 * 1024);
    if (sizeInMB >= 1) {
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
    
    final sizeInKB = mediaFileSize! / 1024;
    return '${sizeInKB.toStringAsFixed(0)} KB';
  }

  /// Creates a copy of this post with modified properties.
  /// 
  /// Parameters:
  ///   - All parameters are optional and default to existing values
  /// 
  /// Returns:
  ///   CommunityPost - A new instance with updated values
  CommunityPost copyWith({
    String? id,
    String? communityId,
    String? userId,
    String? username,
    String? userAvatarUrl,
    CommunityPostType? postType,
    String? content,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    int? mediaFileSize,
    String? mediaMimeType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    List<CommunityPostComment>? comments,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      postType: postType ?? this.postType,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl ?? this.mediaThumbnailUrl,
      mediaFileSize: mediaFileSize ?? this.mediaFileSize,
      mediaMimeType: mediaMimeType ?? this.mediaMimeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }

  /// Creates a CommunityPost from JSON/Map data (for Supabase).
  /// 
  /// Parameters:
  ///   - json: Map containing the post data from database
  /// 
  /// Returns:
  ///   CommunityPost - Instance created from JSON data
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? '',
      communityId: json['community_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      userAvatarUrl: json['user_avatar_url'],
      postType: _parsePostType(json['post_type']),
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      mediaThumbnailUrl: json['media_thumbnail_url'],
      mediaFileSize: json['media_file_size'],
      mediaMimeType: json['media_mime_type'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      comments: _parseComments(json['comments']),
    );
  }

  /// Converts this CommunityPost to JSON/Map (for Supabase).
  /// 
  /// Returns:
  ///   Map<String, dynamic> - JSON representation of the post
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'post_type': _postTypeToString(postType),
      'content': content,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_file_size': mediaFileSize,
      'media_mime_type': mediaMimeType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
    };
  }

  /// Parses post type from string to enum.
  /// 
  /// Parameters:
  ///   - postType: String representation of post type
  /// 
  /// Returns:
  ///   CommunityPostType - Parsed enum value, defaults to chat
  static CommunityPostType _parsePostType(String? postType) {
    switch (postType?.toLowerCase()) {
      case 'image':
        return CommunityPostType.image;
      case 'video':
        return CommunityPostType.video;
      case 'chat':
      default:
        return CommunityPostType.chat;
    }
  }

  /// Converts post type enum to string.
  /// 
  /// Parameters:
  ///   - postType: CommunityPostType enum value
  /// 
  /// Returns:
  ///   String - String representation of post type
  static String _postTypeToString(CommunityPostType postType) {
    switch (postType) {
      case CommunityPostType.image:
        return 'image';
      case CommunityPostType.video:
        return 'video';
      case CommunityPostType.chat:
        return 'chat';
    }
  }

  /// Parses comments from JSON array.
  /// 
  /// Parameters:
  ///   - commentsJson: JSON array of comments or null
  /// 
  /// Returns:
  ///   List<CommunityPostComment> - Parsed comments list
  static List<CommunityPostComment> _parseComments(dynamic commentsJson) {
    if (commentsJson == null) return [];
    
    if (commentsJson is List) {
      return commentsJson
          .map<CommunityPostComment>((json) => CommunityPostComment.fromJson(json))
          .toList();
    }
    
    return [];
  }

  @override
  String toString() {
    return 'CommunityPost(id: $id, communityId: $communityId, postType: $postType, content: ${content.length > 50 ? content.substring(0, 50) + '...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for creating new community posts before submission.
/// 
/// Provides a simplified interface for creating posts with validation
/// and proper data formatting for different post types.
class CommunityPostCreator {
  final String communityId;
  final CommunityPostType postType;
  final String content;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final int? mediaFileSize;
  final String? mediaMimeType;

  CommunityPostCreator({
    required this.communityId,
    required this.postType,
    required this.content,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaFileSize,
    this.mediaMimeType,
  });

  /// Validates the post data before creation.
  /// 
  /// Returns:
  ///   String? - Error message if validation fails, null if valid
  String? validate() {
    // Content validation
    if (content.trim().isEmpty && postType == CommunityPostType.chat) {
      return 'Chat posts must have content';
    }

    // Media validation for image/video posts
    if (postType == CommunityPostType.image || postType == CommunityPostType.video) {
      if (mediaUrl == null || mediaUrl!.isEmpty) {
        return '${postType == CommunityPostType.image ? 'Image' : 'Video'} posts must have media content';
      }
    }

    // File size validation
    if (mediaFileSize != null) {
      if (postType == CommunityPostType.image && mediaFileSize! > 10 * 1024 * 1024) {
        return 'Image file size must be less than 10MB';
      }
      if (postType == CommunityPostType.video && mediaFileSize! > 50 * 1024 * 1024) {
        return 'Video file size must be less than 50MB';
      }
    }

    return null; // Valid
  }

  /// Converts this creator to JSON for database insertion.
  /// 
  /// Returns:
  ///   Map<String, dynamic> - JSON data for database insertion
  Map<String, dynamic> toCreateJson({
    required String userId,
    required String username,
    String? userAvatarUrl,
  }) {
    return {
      'community_id': communityId,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'post_type': CommunityPost._postTypeToString(postType),
      'content': content,
      'media_url': mediaUrl,
      'media_thumbnail_url': mediaThumbnailUrl,
      'media_file_size': mediaFileSize,
      'media_mime_type': mediaMimeType,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
} 