// lib/models/comment.dart
class Comment { // Define Comment class as a data model for user comments on posts
  final String id; // Declare final string field for unique comment identifier
  final String username; // Declare final string field for the username of the comment author
  final String content; // Declare final string field for the text content of the comment
  final DateTime timestamp; // Declare final DateTime field for when the comment was created
  final int likes; // Declare final int field for the number of likes on the comment
  final String? avatarUrl; // Declare optional final string field for the user's avatar URL

  Comment({ // Constructor for Comment class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.username, // Initialize required username parameter
    required this.content, // Initialize required content parameter
    required this.timestamp, // Initialize required timestamp parameter
    this.likes = 0, // Initialize likes parameter with default value of 0
    this.avatarUrl, // Initialize optional avatarUrl parameter
  }); // End of constructor

  // Create a copy of the comment with modified properties
  Comment copyWith({ // Define copyWith method to create a new Comment instance with modified properties
    String? id, // Optional new id parameter
    String? username, // Optional new username parameter
    String? content, // Optional new content parameter
    DateTime? timestamp, // Optional new timestamp parameter
    int? likes, // Optional new likes parameter
    String? avatarUrl, // Optional new avatarUrl parameter
  }) { // Begin copyWith method body
    return Comment( // Return a new Comment instance
      id: id ?? this.id, // Use new id if provided, otherwise use current id
      username: username ?? this.username, // Use new username if provided, otherwise use current username
      content: content ?? this.content, // Use new content if provided, otherwise use current content
      timestamp: timestamp ?? this.timestamp, // Use new timestamp if provided, otherwise use current timestamp
      likes: likes ?? this.likes, // Use new likes if provided, otherwise use current likes
      avatarUrl: avatarUrl ?? this.avatarUrl, // Use new avatarUrl if provided, otherwise use current avatarUrl
    ); // End of Comment constructor call
  } // End of copyWith method

  // Convert comment to a map
  Map<String, dynamic> toMap() { // Define toMap method to convert Comment instance to a Map
    return { // Return a Map with comment properties
      'id': id, // Map id field to 'id' key
      'username': username, // Map username field to 'username' key
      'content': content, // Map content field to 'content' key
      'timestamp': timestamp.toIso8601String(), // Map timestamp field to 'timestamp' key as ISO string
      'likes': likes, // Map likes field to 'likes' key
      'avatarUrl': avatarUrl, // Map avatarUrl field to 'avatarUrl' key
    }; // End of Map literal
  } // End of toMap method

  // Create a comment from a map
  factory Comment.fromMap(Map<String, dynamic> map) { // Define factory constructor to create Comment from Map
    return Comment( // Return a new Comment instance
      id: map['id'], // Extract id from 'id' key in map
      username: map['username'], // Extract username from 'username' key in map
      content: map['content'], // Extract content from 'content' key in map
      timestamp: DateTime.parse(map['timestamp']), // Extract timestamp from 'timestamp' key and parse to DateTime
      likes: map['likes'] ?? 0, // Extract likes from 'likes' key with default value of 0
      avatarUrl: map['avatarUrl'], // Extract avatarUrl from 'avatarUrl' key in map
    ); // End of Comment constructor call
  } // End of fromMap factory constructor
} // End of Comment class
