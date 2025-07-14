// lib/models/post.dart
import 'comment.dart'; // Import the Comment model class for use in the Post model

class Post { // Define Post class as a data model for social media posts
  final String id; // Declare final string field for unique post identifier
  final String userId; // Declare final string field for the user ID who created the post
  final String username; // Declare final string field for the username of the post author
  final String content; // Declare final string field for the text content of the post
  DateTime timestamp; // Declare DateTime field for when the post was created (mutable for timezone conversion)
  int likes; // Declare mutable int field for the number of likes on the post
  final List<Comment> comments; // Declare final list field for comments on the post
  int reposts; // Declare mutable int field for the number of reposts of the post
  bool isLiked; // Declare mutable boolean field for whether the current user has liked the post
  bool isReposted; // Declare mutable boolean field for whether the current user has reposted the post
  final String? avatarUrl; // Declare optional final string field for the user's avatar URL

  Post({ // Constructor for Post class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.userId, // Initialize required userId parameter
    required this.username, // Initialize required username parameter
    required this.content, // Initialize required content parameter
    required this.timestamp, // Initialize required timestamp parameter
    this.likes = 0, // Initialize likes parameter with default value of 0
    this.comments = const [], // Initialize comments parameter with default empty list
    this.reposts = 0, // Initialize reposts parameter with default value of 0
    this.isLiked = false, // Initialize isLiked parameter with default value of false
    this.isReposted = false, // Initialize isReposted parameter with default value of false
    this.avatarUrl, // Initialize optional avatarUrl parameter
  }); // End of constructor

  // Convert UTC timestamp to local time
  void convertToLocalTime() { // Define method to convert UTC timestamp to local time
    timestamp = timestamp.toLocal(); // Convert the timestamp from UTC to local timezone
  } // End of convertToLocalTime method

  // Create a copy of the post with modified properties
  Post copyWith({ // Define copyWith method to create a new Post instance with modified properties
    String? id, // Optional new id parameter
    String? userId, // Optional new userId parameter
    String? username, // Optional new username parameter
    String? content, // Optional new content parameter
    DateTime? timestamp, // Optional new timestamp parameter
    int? likes, // Optional new likes parameter
    List<Comment>? comments, // Optional new comments parameter
    int? reposts, // Optional new reposts parameter
    bool? isLiked, // Optional new isLiked parameter
    bool? isReposted, // Optional new isReposted parameter
    String? avatarUrl, // Optional new avatarUrl parameter
  }) { // Begin copyWith method body
    return Post( // Return a new Post instance
      id: id ?? this.id, // Use new id if provided, otherwise use current id
      userId: userId ?? this.userId, // Use new userId if provided, otherwise use current userId
      username: username ?? this.username, // Use new username if provided, otherwise use current username
      content: content ?? this.content, // Use new content if provided, otherwise use current content
      timestamp: timestamp ?? this.timestamp, // Use new timestamp if provided, otherwise use current timestamp
      likes: likes ?? this.likes, // Use new likes if provided, otherwise use current likes
      comments: comments ?? this.comments, // Use new comments if provided, otherwise use current comments
      reposts: reposts ?? this.reposts, // Use new reposts if provided, otherwise use current reposts
      isLiked: isLiked ?? this.isLiked, // Use new isLiked if provided, otherwise use current isLiked
      isReposted: isReposted ?? this.isReposted, // Use new isReposted if provided, otherwise use current isReposted
      avatarUrl: avatarUrl ?? this.avatarUrl, // Use new avatarUrl if provided, otherwise use current avatarUrl
    ); // End of Post constructor call
  } // End of copyWith method

  // Convert post to a map
  Map<String, dynamic> toMap() { // Define toMap method to convert Post instance to a Map
    return { // Return a Map with post properties
      'id': id, // Map id field to 'id' key
      'userId': userId, // Map userId field to 'userId' key
      'username': username, // Map username field to 'username' key
      'content': content, // Map content field to 'content' key
      'timestamp': timestamp.toUtc().toIso8601String(), // Map timestamp field to 'timestamp' key as UTC ISO string
      'likes': likes, // Map likes field to 'likes' key
      'comments': comments.map((comment) => comment.toMap()).toList(), // Map comments field to 'comments' key as list of maps
      'reposts': reposts, // Map reposts field to 'reposts' key
      'isLiked': isLiked, // Map isLiked field to 'isLiked' key
      'isReposted': isReposted, // Map isReposted field to 'isReposted' key
      'avatarUrl': avatarUrl, // Map avatarUrl field to 'avatarUrl' key
    }; // End of Map literal
  } // End of toMap method

  // Create a post from a map
  factory Post.fromMap(Map<String, dynamic> map) { // Define factory constructor to create Post from Map
    final post = Post( // Create a new Post instance
      id: map['id'], // Extract id from 'id' key in map
      userId: map['userId'] ?? map['user_id'] ?? '', // Extract userId from 'userId' or 'user_id' key with default empty string
      username: map['username'], // Extract username from 'username' key in map
      content: map['content'], // Extract content from 'content' key in map
      timestamp: // Extract timestamp from 'timestamp' key and convert to local time
          DateTime.parse(map['timestamp']).toLocal(), // Parse timestamp string to DateTime and convert to local timezone
      likes: map['likes'] ?? 0, // Extract likes from 'likes' key with default value of 0
      comments: (map['comments'] as List?) // Extract comments from 'comments' key as nullable list
              ?.map((comment) => Comment.fromMap(comment)) // Map each comment map to Comment instance
              .toList() ?? // Convert mapped comments to list
          [], // Default to empty list if comments is null
      reposts: map['reposts'] ?? 0, // Extract reposts from 'reposts' key with default value of 0
      isLiked: map['isLiked'] ?? false, // Extract isLiked from 'isLiked' key with default value of false
      isReposted: map['isReposted'] ?? false, // Extract isReposted from 'isReposted' key with default value of false
      avatarUrl: map['avatarUrl'], // Extract avatarUrl from 'avatarUrl' key in map
    ); // End of Post constructor call
    return post; // Return the created Post instance
  } // End of fromMap factory constructor
} // End of Post class
