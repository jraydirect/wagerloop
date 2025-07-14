// lib/models/pick_post.dart
import 'comment.dart'; // Import the Comment model class for use in pick posts
import 'sports/game.dart'; // Import the Game model class for use in betting picks

/// Represents the type of betting pick a user can make.
/// 
/// Defines the available betting markets supported by WagerLoop,
/// including standard sports betting options and player props.
enum PickType { // Define enum to represent different types of betting picks
  moneyline,  // Bet on which team will win
  spread,     // Bet on point spread
  total,      // Bet on over/under total points
  playerProp, // Bet on individual player performance
} // End of PickType enum

/// Represents which side of a bet the user is taking.
/// 
/// Defines the specific outcome or side of a betting pick,
/// varying by pick type (home/away for moneyline, over/under for totals).
enum PickSide { // Define enum to represent different sides of betting picks
  home,   // Home team or player
  away,   // Away team or player
  over,   // Over the total
  under,  // Under the total
  draw,   // Draw/tie outcome
} // End of PickSide enum

/// Represents a single betting pick within WagerLoop.
/// 
/// Contains all information about a user's betting selection including
/// the game, bet type, odds, stake amount, and reasoning. Used to track
/// betting history and display picks in the social feed.
class Pick { // Define Pick class as a data model for individual betting picks
  final String id; // Declare final string field for unique pick identifier
  final Game game; // Declare final Game field for the game being bet on
  final PickType pickType; // Declare final PickType field for the type of bet
  final PickSide pickSide; // Declare final PickSide field for the side of the bet
  final String? playerName; // Declare optional string field for player name in player props
  final String? propType; // Declare optional string field for prop type (e.g., "Points", "Rebounds")
  final double? propValue; // Declare optional double field for prop value (e.g., 22.5)
  final String odds; // Declare final string field for the odds of the bet
  final double? stake; // Declare optional double field for the stake amount
  final String? reasoning; // Declare optional string field for the user's reasoning for the pick

  Pick({ // Constructor for Pick class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.game, // Initialize required game parameter
    required this.pickType, // Initialize required pickType parameter
    required this.pickSide, // Initialize required pickSide parameter
    this.playerName, // Initialize optional playerName parameter
    this.propType, // Initialize optional propType parameter
    this.propValue, // Initialize optional propValue parameter
    required this.odds, // Initialize required odds parameter
    this.stake, // Initialize optional stake parameter
    this.reasoning, // Initialize optional reasoning parameter
  }); // End of constructor

  /// Generates a human-readable display text for the pick.
  /// 
  /// Creates formatted text showing the pick details including teams,
  /// bet type, odds, and any relevant props for display in the UI.
  /// 
  /// Returns:
  ///   String containing formatted pick information for display
  String get displayText { // Define getter to return formatted display text for the pick
    switch (pickType) { // Switch statement based on the pick type
      case PickType.moneyline: // Handle moneyline bet formatting
        String team = pickSide == PickSide.home ? game.homeTeam : // Choose home team if pick side is home
                     pickSide == PickSide.away ? game.awayTeam : 'Draw'; // Choose away team if pick side is away, otherwise draw
        return '$team ML ($odds)'; // Return formatted moneyline text
      
      case PickType.spread: // Handle spread bet formatting
        String team = pickSide == PickSide.home ? game.homeTeam : game.awayTeam; // Choose team based on pick side
        return '$team ${odds}'; // Return formatted spread text
      case PickType.total: // Handle total bet formatting
        String totalSide = pickSide == PickSide.over ? 'Over' : 'Under'; // Choose over or under based on pick side
        return '$totalSide ${odds}'; // Return formatted total text
      case PickType.playerProp: // Handle player prop bet formatting
        if (playerName != null && propType != null) { // Check if player name and prop type are available
          String propSide = pickSide == PickSide.over ? 'Over' : 'Under'; // Choose over or under for prop
          return '$playerName $propType $propSide ${propValue ?? ''} ($odds)'; // Return formatted player prop text
        } // End of player prop formatting
        return 'Player Prop ($odds)'; // Return generic player prop text if details are missing
    } // End of switch statement
  } // End of displayText getter

  /// Creates a Pick from a JSON map.
  /// 
  /// Used for deserializing pick data from the database or API.
  /// Handles conversion of pick types and sides from string names.
  /// 
  /// Parameters:
  ///   - json: Map containing pick data
  /// 
  /// Returns:
  ///   Pick object created from the JSON data
  /// 
  /// Throws:
  ///   - Exception: If required fields are missing or malformed
  factory Pick.fromJson(Map<String, dynamic> json) { // Define factory constructor to create Pick from JSON
    return Pick( // Return a new Pick instance
      id: json['id'], // Extract id from 'id' key
      game: Game.fromJson(json['game']), // Create Game instance from 'game' JSON
      pickType: PickType.values.firstWhere((e) => e.name == json['pick_type']), // Find PickType enum by name
      pickSide: PickSide.values.firstWhere((e) => e.name == json['pick_side']), // Find PickSide enum by name
      playerName: json['player_name'], // Extract playerName from 'player_name' key
      propType: json['prop_type'], // Extract propType from 'prop_type' key
      propValue: json['prop_value']?.toDouble(), // Extract propValue from 'prop_value' key and convert to double
      odds: json['odds'], // Extract odds from 'odds' key
      stake: json['stake']?.toDouble(), // Extract stake from 'stake' key and convert to double
      reasoning: json['reasoning'], // Extract reasoning from 'reasoning' key
    ); // End of Pick constructor call
  } // End of fromJson factory constructor

  /// Converts the pick to a JSON-serializable map.
  /// 
  /// Used for storing pick data in the database and transmitting
  /// pick information between client and server.
  /// 
  /// Returns:
  ///   Map<String, dynamic> containing all pick data
  Map<String, dynamic> toJson() { // Define method to convert Pick instance to JSON
    return { // Return a Map with pick properties
      'id': id, // Map id field to 'id' key
      'game': game.toJson(), // Convert game to JSON and map to 'game' key
      'pick_type': pickType.name, // Map pickType name to 'pick_type' key
      'pick_side': pickSide.name, // Map pickSide name to 'pick_side' key
      'player_name': playerName, // Map playerName field to 'player_name' key
      'prop_type': propType, // Map propType field to 'prop_type' key
      'prop_value': propValue, // Map propValue field to 'prop_value' key
      'odds': odds, // Map odds field to 'odds' key
      'stake': stake, // Map stake field to 'stake' key
      'reasoning': reasoning, // Map reasoning field to 'reasoning' key
    }; // End of Map literal
  } // End of toJson method
} // End of Pick class

/// Represents a social media post containing betting picks.
/// 
/// Extends the concept of a regular post to include betting picks,
/// allowing users to share their sports betting selections with the
/// WagerLoop community. Includes social interaction features like
/// likes, comments, and reposts.
class PickPost { // Define PickPost class as a data model for social media posts with betting picks
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
  final List<Pick> picks; // Declare final list field for the betting picks in the post

  PickPost({ // Constructor for PickPost class with required and optional parameters
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
    this.picks = const [], // Initialize picks parameter with default empty list
  }); // End of constructor

  /// Indicates whether this post contains any betting picks.
  /// 
  /// Returns:
  ///   bool - True if the post has associated picks, false otherwise
  bool get hasPicks => picks.isNotEmpty; // Define getter to check if the post has picks
  
  /// Calculates the total number of picks in this post.
  /// 
  /// Used for displaying pick counts and determining if this is
  /// a single pick or parlay bet.
  /// 
  /// Returns:
  ///   int - Total number of picks in the post
  int get pickCount => picks.length; // Define getter to return the number of picks

  /// Determines if this is a parlay bet (multiple picks).
  /// 
  /// Parlay bets combine multiple picks for higher potential payouts
  /// but require all picks to be correct to win.
  /// 
  /// Returns:
  ///   bool - True if this is a parlay (more than one pick), false otherwise
  bool get isParlay => picks.length > 1; // Define getter to check if this is a parlay bet

  /// Calculates the total stake amount across all picks.
  /// 
  /// Sums up the stake amounts from all picks in the post to show
  /// the total amount wagered by the user.
  /// 
  /// Returns:
  ///   double - Total stake amount, or 0.0 if no stakes are specified
  double get totalStake { // Define getter to calculate total stake amount
    return picks.fold(0.0, (sum, pick) => sum + (pick.stake ?? 0.0)); // Sum up all pick stakes with 0.0 as default
  } // End of totalStake getter

  /// Converts the pick post to a JSON-serializable map.
  /// 
  /// Used for storing pick post data in the database and transmitting
  /// between client and server. Includes all post metadata and pick data.
  /// 
  /// Returns:
  ///   Map<String, dynamic> containing all pick post data
  Map<String, dynamic> toJson() { // Define method to convert PickPost instance to JSON
    return { // Return a Map with pick post properties
      'id': id, // Map id field to 'id' key
      'user_id': userId, // Map userId field to 'user_id' key
      'username': username, // Map username field to 'username' key
      'content': content, // Map content field to 'content' key
      'timestamp': timestamp.toIso8601String(), // Map timestamp field to 'timestamp' key as ISO string
      'likes': likes, // Map likes field to 'likes' key
      'comments': comments.map((c) => c.toJson()).toList(), // Map comments field to 'comments' key as list of JSON objects
      'reposts': reposts, // Map reposts field to 'reposts' key
      'is_liked': isLiked, // Map isLiked field to 'is_liked' key
      'is_reposted': isReposted, // Map isReposted field to 'is_reposted' key
      'avatar_url': avatarUrl, // Map avatarUrl field to 'avatar_url' key
      'picks': picks.map((p) => p.toJson()).toList(), // Map picks field to 'picks' key as list of JSON objects
    }; // End of Map literal
  } // End of toJson method

  /// Creates a PickPost from a JSON map.
  /// 
  /// Used for deserializing pick post data from the database or API.
  /// Handles conversion of timestamps and nested pick objects.
  /// 
  /// Parameters:
  ///   - json: Map containing pick post data
  /// 
  /// Returns:
  ///   PickPost object created from the JSON data
  /// 
  /// Throws:
  ///   - Exception: If required fields are missing or malformed
  factory PickPost.fromJson(Map<String, dynamic> json) { // Define factory constructor to create PickPost from JSON
    return PickPost( // Return a new PickPost instance
      id: json['id'], // Extract id from 'id' key
      userId: json['user_id'], // Extract userId from 'user_id' key
      username: json['username'], // Extract username from 'username' key
      content: json['content'], // Extract content from 'content' key
      timestamp: DateTime.parse(json['timestamp']), // Parse timestamp from 'timestamp' key
      likes: json['likes'] ?? 0, // Extract likes from 'likes' key with default value of 0
      comments: (json['comments'] as List?)?.map((c) => Comment.fromJson(c)).toList() ?? [], // Map comments list to Comment objects or empty list
      reposts: json['reposts'] ?? 0, // Extract reposts from 'reposts' key with default value of 0
      isLiked: json['is_liked'] ?? false, // Extract isLiked from 'is_liked' key with default value of false
      isReposted: json['is_reposted'] ?? false, // Extract isReposted from 'is_reposted' key with default value of false
      avatarUrl: json['avatar_url'], // Extract avatarUrl from 'avatar_url' key
      picks: (json['picks'] as List?)?.map((p) => Pick.fromJson(p)).toList() ?? [], // Map picks list to Pick objects or empty list
    ); // End of PickPost constructor call
  } // End of fromJson factory constructor
} // End of PickPost class
