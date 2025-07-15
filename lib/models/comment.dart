// lib/models/comment.dart
class Comment {
  final String id;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final String? avatarUrl;
  final String? parentCommentId; // New field for reply functionality
  final String? replyToUsername; // New field to show who this reply is to
  final int replyCount; // New field to track number of replies
  final List<Comment> replies; // New field to store nested replies

  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.avatarUrl,
    this.parentCommentId,
    this.replyToUsername,
    this.replyCount = 0,
    this.replies = const [],
  });

  // Create a copy of the comment with modified properties
  Comment copyWith({
    String? id,
    String? username,
    String? content,
    DateTime? timestamp,
    int? likes,
    String? avatarUrl,
    String? parentCommentId,
    String? replyToUsername,
    int? replyCount,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      username: username ?? this.username,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToUsername: replyToUsername ?? this.replyToUsername,
      replyCount: replyCount ?? this.replyCount,
      replies: replies ?? this.replies,
    );
  }

  // Convert comment to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'avatarUrl': avatarUrl,
      'parentCommentId': parentCommentId,
      'replyToUsername': replyToUsername,
      'replyCount': replyCount,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }

  // Convert comment to JSON (same as toMap for compatibility)
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // Create a comment from a map
  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      username: map['username'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      likes: map['likes'] ?? 0,
      avatarUrl: map['avatarUrl'],
      parentCommentId: map['parentCommentId'],
      replyToUsername: map['replyToUsername'],
      replyCount: map['replyCount'] ?? 0,
      replies: map['replies'] != null 
          ? (map['replies'] as List).map((reply) => Comment.fromMap(reply)).toList()
          : [],
    );
  }

  // Create a comment from JSON (same as fromMap for compatibility)
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment.fromMap(json);
  }

  // Helper method to check if this is a reply
  bool get isReply => parentCommentId != null;

  // Helper method to check if this comment has replies
  bool get hasReplies => replyCount > 0 || replies.isNotEmpty;
}
