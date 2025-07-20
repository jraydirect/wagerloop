// lib/models/community_post_comment.dart

/// Represents a comment on a community post.
/// 
/// Contains all information about a comment including threaded
/// replies, user information, and interaction data.
/// Supports nested comment structures for discussions.
class CommunityPostComment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String content;
  final String? parentCommentId; // For threaded replies
  final String? replyToUsername; // Username being replied to
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Interaction counts
  int replyCount;
  
  // Nested replies (for display purposes)
  final List<CommunityPostComment> replies;

  CommunityPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.content,
    this.parentCommentId,
    this.replyToUsername,
    required this.createdAt,
    required this.updatedAt,
    this.replyCount = 0,
    this.replies = const [],
  });

  /// Indicates whether this is a reply to another comment.
  /// 
  /// Returns:
  ///   bool - True if this comment is a reply, false if it's a top-level comment
  bool get isReply => parentCommentId != null;

  /// Indicates whether this comment has replies.
  /// 
  /// Returns:
  ///   bool - True if this comment has replies, false otherwise
  bool get hasReplies => replyCount > 0 || replies.isNotEmpty;

  /// Creates a copy of this comment with modified properties.
  /// 
  /// Parameters:
  ///   - All parameters are optional and default to existing values
  /// 
  /// Returns:
  ///   CommunityPostComment - A new instance with updated values
  CommunityPostComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? userAvatarUrl,
    String? content,
    String? parentCommentId,
    String? replyToUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? replyCount,
    List<CommunityPostComment>? replies,
  }) {
    return CommunityPostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToUsername: replyToUsername ?? this.replyToUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
    );
  }

  /// Creates a CommunityPostComment from JSON/Map data (for Supabase).
  /// 
  /// Parameters:
  ///   - json: Map containing the comment data from database
  /// 
  /// Returns:
  ///   CommunityPostComment - Instance created from JSON data
  factory CommunityPostComment.fromJson(Map<String, dynamic> json) {
    return CommunityPostComment(
      id: json['id'] ?? '',
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      userAvatarUrl: json['user_avatar_url'],
      content: json['content'] ?? '',
      parentCommentId: json['parent_comment_id'],
      replyToUsername: json['reply_to_username'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      replyCount: json['reply_count'] ?? 0,
      replies: _parseReplies(json['replies']),
    );
  }

  /// Converts this CommunityPostComment to JSON/Map (for Supabase).
  /// 
  /// Returns:
  ///   Map<String, dynamic> - JSON representation of the comment
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'content': content,
      'parent_comment_id': parentCommentId,
      'reply_to_username': replyToUsername,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reply_count': replyCount,
    };
  }

  /// Parses replies from JSON array.
  /// 
  /// Parameters:
  ///   - repliesJson: JSON array of replies or null
  /// 
  /// Returns:
  ///   List<CommunityPostComment> - Parsed replies list
  static List<CommunityPostComment> _parseReplies(dynamic repliesJson) {
    if (repliesJson == null) return [];
    
    if (repliesJson is List) {
      return repliesJson
          .map<CommunityPostComment>((json) => CommunityPostComment.fromJson(json))
          .toList();
    }
    
    return [];
  }

  @override
  String toString() {
    return 'CommunityPostComment(id: $id, postId: $postId, username: $username, isReply: $isReply, content: ${content.length > 30 ? content.substring(0, 30) + '...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPostComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for creating new community post comments before submission.
/// 
/// Provides a simplified interface for creating comments with validation
/// and proper data formatting for threaded discussions.
class CommunityPostCommentCreator {
  final String postId;
  final String content;
  final String? parentCommentId; // For replies
  final String? replyToUsername; // Username being replied to

  CommunityPostCommentCreator({
    required this.postId,
    required this.content,
    this.parentCommentId,
    this.replyToUsername,
  });

  /// Validates the comment data before creation.
  /// 
  /// Returns:
  ///   String? - Error message if validation fails, null if valid
  String? validate() {
    // Content validation
    if (content.trim().isEmpty) {
      return 'Comment content cannot be empty';
    }

    if (content.trim().length > 1000) {
      return 'Comment is too long (max 1000 characters)';
    }

    // Reply validation
    if (parentCommentId != null && (replyToUsername == null || replyToUsername!.isEmpty)) {
      return 'Reply must specify the username being replied to';
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
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'user_avatar_url': userAvatarUrl,
      'content': content.trim(),
      'parent_comment_id': parentCommentId,
      'reply_to_username': replyToUsername,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
} 