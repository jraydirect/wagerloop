// Import Comment model for post comments - provides data structure for post comments
import 'comment.dart';

// Model class representing a social media post in the WagerLoop app - stores post data and interaction state
class Post {
  // Unique identifier for the post - primary key from database
  final String id;
  // ID of the user who created the post - links post to user account
  final String userId; // Add userId field
  // Display name of the user who created the post - shown in UI
  final String username;
  // Text content of the post - the actual post message
  final String content;
  // Timestamp when the post was created - tracks when post was made (non-final to allow conversion)
  DateTime timestamp; // Changed to non-final to allow conversion
  // Number of likes the post has received - tracks user engagement
  int likes;
  // List of comments on the post - stores all comments for this post
  final List<Comment> comments;
  // Number of times the post has been reposted - tracks sharing activity
  int reposts;
  // Whether the current user has liked this post - tracks user's interaction state
  bool isLiked;
  // Whether the current user has reposted this post - tracks user's sharing state
  bool isReposted;
  // URL of the user's avatar image - displays user profile picture
  final String? avatarUrl;

  // Constructor that initializes all post properties - creates new Post instance
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

  // Convert UTC timestamp to local time - adjusts timestamp for user's timezone
  void convertToLocalTime() {
    // Convert timestamp from UTC to local timezone - ensures proper time display
    timestamp = timestamp.toLocal();
  }

  // Create a copy of the post with modified properties - enables immutable updates
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
    // Return new Post instance with updated properties - creates modified copy
    return Post(
      // Use provided value or keep existing value for each property - handles optional updates
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

  // Convert post to a map for JSON serialization - prepares post for storage/transmission
  Map<String, dynamic> toMap() {
    // Return map with all post properties - converts object to dictionary format
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp.toUtc().toIso8601String(), // Store as UTC for consistency
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(), // Convert comments to maps
      'reposts': reposts,
      'isLiked': isLiked,
      'isReposted': isReposted,
      'avatarUrl': avatarUrl,
    };
  }

  // Create a post from a map (JSON deserialization) - reconstructs Post from stored data
  factory Post.fromMap(Map<String, dynamic> map) {
    // Create Post instance from map data - converts dictionary back to object
    final post = Post(
      id: map['id'],
      userId: map['userId'] ?? map['user_id'] ?? '', // Handle different field name variations
      username: map['username'],
      content: map['content'],
      timestamp:
          DateTime.parse(map['timestamp']).toLocal(), // Convert to local time for display
      likes: map['likes'] ?? 0,
      comments: (map['comments'] as List?)
              ?.map((comment) => Comment.fromMap(comment)) // Convert comment maps to Comment objects
              .toList() ??
          [],
      reposts: map['reposts'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isReposted: map['isReposted'] ?? false,
      avatarUrl: map['avatarUrl'],
    );
    // Return the created post - provides reconstructed Post object
    return post;
  }
}
