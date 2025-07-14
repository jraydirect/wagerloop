// lib/models/comment.dart
class Comment {
  final String id;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final String? avatarUrl;

  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.avatarUrl,
  });

  // Create a copy of the comment with modified properties
  Comment copyWith({
    String? id,
    String? username,
    String? content,
    DateTime? timestamp,
    int? likes,
    String? avatarUrl,
  }) {
    return Comment(
      id: id ?? this.id,
      username: username ?? this.username,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
    );
  }

  // Create a comment from JSON (same as fromMap for compatibility)
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment.fromMap(json);
  }
}
