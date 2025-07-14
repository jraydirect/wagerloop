// lib/models/post.dart
import 'comment.dart';

class Post {
  final String id;
  final String userId; // Add userId field
  final String username;
  final String content;
  DateTime timestamp; // Changed to non-final to allow conversion
  int likes;
  final List<Comment> comments;
  int reposts;
  bool isLiked;
  bool isReposted;
  final String? avatarUrl;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.comments = const [],
    this.reposts = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.avatarUrl,
  });

  // Convert UTC timestamp to local time
  void convertToLocalTime() {
    timestamp = timestamp.toLocal();
  }

  // Create a copy of the post with modified properties
  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? content,
    DateTime? timestamp,
    int? likes,
    List<Comment>? comments,
    int? reposts,
    bool? isLiked,
    bool? isReposted,
    String? avatarUrl,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Convert post to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp.toUtc().toIso8601String(), // Store as UTC
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'reposts': reposts,
      'isLiked': isLiked,
      'isReposted': isReposted,
      'avatarUrl': avatarUrl,
    };
  }

  // Create a post from a map
  factory Post.fromMap(Map<String, dynamic> map) {
    final post = Post(
      id: map['id'],
      userId: map['userId'] ?? map['user_id'] ?? '',
      username: map['username'],
      content: map['content'],
      timestamp:
          DateTime.parse(map['timestamp']).toLocal(), // Convert to local time
      likes: map['likes'] ?? 0,
      comments: (map['comments'] as List?)
              ?.map((comment) => Comment.fromMap(comment))
              .toList() ??
          [],
      reposts: map['reposts'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isReposted: map['isReposted'] ?? false,
      avatarUrl: map['avatarUrl'],
    );
    return post;
  }
}
