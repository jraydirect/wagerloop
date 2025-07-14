// lib/models/pick_post.dart
import 'comment.dart';
import 'sports/game.dart';

enum PickType {
  moneyline,
  spread,
  total,
  playerProp,
}

enum PickSide {
  home,
  away,
  over,
  under,
  draw,
}

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

  String get displayText {
    switch (pickType) {
      case PickType.moneyline:
        String team = pickSide == PickSide.home ? game.homeTeam : 
                     pickSide == PickSide.away ? game.awayTeam : 'Draw';
        return '$team ML ($odds)';
      
      case PickType.spread:
        String team = pickSide == PickSide.home ? game.homeTeam : game.awayTeam;
        return '$team Spread ($odds)';
      
      case PickType.total:
        String side = pickSide == PickSide.over ? 'Over' : 'Under';
        return '$side Total ($odds)';
      
      case PickType.playerProp:
        if (playerName != null && propType != null && propValue != null) {
          String side = pickSide == PickSide.over ? 'Over' : 'Under';
          return '$playerName $side $propValue $propType ($odds)';
        }
        return 'Player Prop ($odds)';
    }
  }

  factory Pick.fromJson(Map<String, dynamic> json) {
    return Pick(
      id: json['id'],
      game: Game.fromJson(json['game']),
      pickType: PickType.values[json['pick_type']],
      pickSide: PickSide.values[json['pick_side']],
      playerName: json['player_name'],
      propType: json['prop_type'],
      propValue: json['prop_value']?.toDouble(),
      odds: json['odds'],
      stake: json['stake']?.toDouble(),
      reasoning: json['reasoning'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game.toJson(),
      'pick_type': pickType.index,
      'pick_side': pickSide.index,
      'player_name': playerName,
      'prop_type': propType,
      'prop_value': propValue,
      'odds': odds,
      'stake': stake,
      'reasoning': reasoning,
    };
  }
}

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

  bool get hasPicks => picks.isNotEmpty;
  
  String get picksDisplayText {
    if (picks.isEmpty) return '';
    if (picks.length == 1) return picks.first.displayText;
    return '${picks.length} picks';
  }

  // Convert UTC timestamp to local time
  void convertToLocalTime() {
    timestamp = timestamp.toLocal();
  }

  // Create a copy of the post with modified properties
  PickPost copyWith({
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
    List<Pick>? picks,
  }) {
    return PickPost(
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
      picks: picks ?? this.picks,
    );
  }

  // Convert post to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'reposts': reposts,
      'isLiked': isLiked,
      'isReposted': isReposted,
      'avatarUrl': avatarUrl,
      'picks': picks.map((pick) => pick.toJson()).toList(),
    };
  }

  // Create a post from a map
  factory PickPost.fromMap(Map<String, dynamic> map) {
    final pickPost = PickPost(
      id: map['id'],
      userId: map['userId'] ?? map['user_id'] ?? '',
      username: map['username'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']).toLocal(),
      likes: map['likes'] ?? 0,
      comments: (map['comments'] as List?)
              ?.map((comment) => Comment.fromMap(comment))
              .toList() ??
          [],
      reposts: map['reposts'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isReposted: map['isReposted'] ?? false,
      avatarUrl: map['avatarUrl'],
      picks: (map['picks'] as List?)
              ?.map((pick) => Pick.fromJson(pick))
              .toList() ??
          [],
    );
    return pickPost;
  }
}
