// Model class representing a comment on a social media post - stores comment data and user information
class Comment {
  // Unique identifier for the comment - primary key from database
  final String id;
  // Display name of the user who wrote the comment - shown in UI
  final String username;
  // Text content of the comment - the actual comment message
  final String content;
  // Timestamp when the comment was created - tracks when comment was made
  final DateTime timestamp;
  // Number of likes the comment has received - tracks user engagement
  final int likes;
  // URL of the user's avatar image - displays user profile picture
  final String? avatarUrl;

  // Constructor that initializes all comment properties - creates new Comment instance
  Comment({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.avatarUrl,
  });

  // Create a copy of the comment with modified properties - enables immutable updates
  Comment copyWith({
    String? id,
    String? username,
    String? content,
    DateTime? timestamp,
    int? likes,
    String? avatarUrl,
  }) {
    // Return new Comment instance with updated properties - creates modified copy
    return Comment(
      // Use provided value or keep existing value for each property - handles optional updates
      id: id ?? this.id,
      username: username ?? this.username,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Convert comment to a map for JSON serialization - prepares comment for storage/transmission
  Map<String, dynamic> toMap() {
    // Return map with all comment properties - converts object to dictionary format
    return {
      'id': id,
      'username': username,
      'content': content,
      'timestamp': timestamp.toIso8601String(), // Convert timestamp to ISO string format
      'likes': likes,
      'avatarUrl': avatarUrl,
    };
  }

  // Convert comment to JSON (same as toMap for compatibility) - provides JSON serialization
  Map<String, dynamic> toJson() {
    // Return the same map as toMap - ensures consistent serialization
    return toMap();
  }

  // Create a comment from a map (JSON deserialization) - reconstructs Comment from stored data
  factory Comment.fromMap(Map<String, dynamic> map) {
    // Create Comment instance from map data - converts dictionary back to object
    return Comment(
      id: map['id'],
      username: map['username'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']), // Parse timestamp string to DateTime
      likes: map['likes'] ?? 0,
      avatarUrl: map['avatarUrl'],
    );
  }

  // Create a comment from JSON (same as fromMap for compatibility) - provides JSON deserialization
  factory Comment.fromJson(Map<String, dynamic> json) {
    // Return the same result as fromMap - ensures consistent deserialization
    return Comment.fromMap(json);
  }
}
