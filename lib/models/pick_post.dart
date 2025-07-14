// lib/models/pick_post.dart
import 'comment.dart';
import 'sports/game.dart';

/// Represents the type of betting pick a user can make.
/// 
/// Defines the available betting markets supported by WagerLoop,
/// including standard sports betting options and player props.
enum PickType {
  moneyline,  // Bet on which team will win
  spread,     // Bet on point spread
  total,      // Bet on over/under total points
  playerProp, // Bet on individual player performance
}

/// Represents which side of a bet the user is taking.
/// 
/// Defines the specific outcome or side of a betting pick,
/// varying by pick type (home/away for moneyline, over/under for totals).
enum PickSide {
  home,   // Home team or player
  away,   // Away team or player
  over,   // Over the total
  under,  // Under the total
  draw,   // Draw/tie outcome
}

/// Represents a single betting pick within WagerLoop.
/// 
/// Contains all information about a user's betting selection including
/// the game, bet type, odds, stake amount, and reasoning. Used to track
/// betting history and display picks in the social feed.
class Pick {
  final String id;
  final Game game;
  final PickType pickType;
  final PickSide pickSide;
  final String? playerName; // For player props
  final String? propType; // For player props (e.g., "Points", "Rebounds")
  final double? propValue; // For player props (e.g., 22.5)
  final String odds;
  final double? stake; // Optional stake amount
  final String? reasoning; // Why the user made this pick

  Pick({
    required this.id,
    required this.game,
    required this.pickType,
    required this.pickSide,
    this.playerName,
    this.propType,
    this.propValue,
    required this.odds,
    this.stake,
    this.reasoning,
  });

  /// Generates a human-readable display text for the pick.
  /// 
  /// Creates formatted text showing the pick details including teams,
  /// bet type, odds, and any relevant props for display in the UI.
  /// 
  /// Returns:
  ///   String containing formatted pick information for display
  String get displayText {
    switch (pickType) {
      case PickType.moneyline:
        String team = pickSide == PickSide.home ? game.homeTeam : 
                     pickSide == PickSide.away ? game.awayTeam : 'Draw';
        return '$team ML ($odds)';
      
      case PickType.spread:
        String team = pickSide == PickSide.home ? game.homeTeam : game.awayTeam;
        return '$team ${odds}';
      case PickType.total:
        String totalSide = pickSide == PickSide.over ? 'Over' : 'Under';
        return '$totalSide ${odds}';
      case PickType.playerProp:
        if (playerName != null && propType != null) {
          String propSide = pickSide == PickSide.over ? 'Over' : 'Under';
          return '$playerName $propType $propSide ${propValue ?? ''} ($odds)';
        }
        return 'Player Prop ($odds)';
    }
  }

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
  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
      id: json['id'],
      game: Game.fromJson(json['game']),
      pickType: PickType.values.firstWhere((e) => e.name == json['pick_type']),
      pickSide: PickSide.values.firstWhere((e) => e.name == json['pick_side']),
      playerName: json['player_name'],
      propType: json['prop_type'],
      propValue: json['prop_value']?.toDouble(),
      odds: json['odds'],
      stake: json['stake']?.toDouble(),
      reasoning: json['reasoning'],
    );
  }

  /// Converts the pick to a JSON-serializable map.
  /// 
  /// Used for storing pick data in the database and transmitting
  /// pick information between client and server.
  /// 
  /// Returns:
  ///   Map<String, dynamic> containing all pick data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game.toJson(),
      'pick_type': pickType.name,
      'pick_side': pickSide.name,
      'player_name': playerName,
      'prop_type': propType,
      'prop_value': propValue,
      'odds': odds,
      'stake': stake,
      'reasoning': reasoning,
    };
  }
}

/// Represents a social media post containing betting picks.
/// 
/// Extends the concept of a regular post to include betting picks,
/// allowing users to share their sports betting selections with the
/// WagerLoop community. Includes social interaction features like
/// likes, comments, and reposts.
class PickPost {
  final String id;
  final String userId; // Add userId field
  final String username;
  final String content;
  DateTime timestamp;
  int likes;
  final List<Comment> comments;
  int reposts;
  bool isLiked;
  bool isReposted;
  final String? avatarUrl;
  final List<Pick> picks; // The main difference from regular Post

  PickPost({
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
    this.picks = const [],
  });

  /// Indicates whether this post contains any betting picks.
  /// 
  /// Returns:
  ///   bool - True if the post has associated picks, false otherwise
  bool get hasPicks => picks.isNotEmpty;
  
  /// Calculates the total number of picks in this post.
  /// 
  /// Used for displaying pick counts and determining if this is
  /// a single pick or parlay bet.
  /// 
  /// Returns:
  ///   int - Total number of picks in the post
  int get pickCount => picks.length;

  /// Determines if this is a parlay bet (multiple picks).
  /// 
  /// Parlay bets combine multiple picks for higher potential payouts
  /// but require all picks to be correct to win.
  /// 
  /// Returns:
  ///   bool - True if this is a parlay (more than one pick), false otherwise
  bool get isParlay => picks.length > 1;

  /// Calculates the total stake amount across all picks.
  /// 
  /// Sums up the stake amounts from all picks in the post to show
  /// the total amount wagered by the user.
  /// 
  /// Returns:
  ///   double - Total stake amount, or 0.0 if no stakes are specified
  double get totalStake {
    return picks.fold(0.0, (sum, pick) => sum + (pick.stake ?? 0.0));
  }

  /// Converts the pick post to a JSON-serializable map.
  /// 
  /// Used for storing pick post data in the database and transmitting
  /// between client and server. Includes all post metadata and pick data.
  /// 
  /// Returns:
  ///   Map<String, dynamic> containing all pick post data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'comments': comments.map((c) => c.toJson()).toList(),
      'reposts': reposts,
      'is_liked': isLiked,
      'is_reposted': isReposted,
      'avatar_url': avatarUrl,
      'picks': picks.map((p) => p.toJson()).toList(),
    };
  }

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
  factory PickPost.fromJson(Map<String, dynamic> json) {
    return PickPost(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      likes: json['likes'] ?? 0,
      comments: (json['comments'] as List?)?.map((c) => Comment.fromJson(c)).toList() ?? [],
      reposts: json['reposts'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isReposted: json['is_reposted'] ?? false,
      avatarUrl: json['avatar_url'],
      picks: (json['picks'] as List?)?.map((p) => Pick.fromJson(p)).toList() ?? [],
    );
  }
}
