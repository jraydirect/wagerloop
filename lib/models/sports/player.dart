// lib/models/sports/player.dart
class PlayerProp {
  final String name;        // e.g., "Points", "Rebounds", "Assists"
  final double value;       // e.g., 22.5
  final String overOdds;    // e.g., "-110"
  final String underOdds;   // e.g., "-110"

  PlayerProp({
    required this.name,
    required this.value,
    required this.overOdds,
    required this.underOdds,
  });

  factory PlayerProp.fromJson(Map<String, dynamic> json) {
    return PlayerProp(
      name: json['name'] ?? '',
      value: (json['value'] is double) ? json['value'] : double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      overOdds: json['over_odds']?.toString() ?? '-110',
      underOdds: json['under_odds']?.toString() ?? '-110',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'over_odds': overOdds,
      'under_odds': underOdds,
    };
  }
}

class Player {
  final String id;
  final String name;
  final String position;
  final String teamId;
  final String teamName;
  final String? jerseyNumber;
  final Map<String, dynamic>? stats;
  final List<PlayerProp>? props;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.teamId,
    required this.teamName,
    this.jerseyNumber,
    this.stats,
    this.props,
  });

  // For basketball, get the standard props that most players have
  List<PlayerProp> get basketballDefaultProps {
    // These values are examples and should be replaced with real data when available
    return [
      PlayerProp(name: 'Points', value: 18.5, overOdds: '-110', underOdds: '-110'),
      PlayerProp(name: 'Rebounds', value: 5.5, overOdds: '-110', underOdds: '-110'),
      PlayerProp(name: 'Assists', value: 4.5, overOdds: '-110', underOdds: '-110'),
      PlayerProp(name: '3-Pointers Made', value: 1.5, overOdds: '-110', underOdds: '-110'),
    ];
  }

  // Get available props - if none are available, return default ones for demo purposes
  List<PlayerProp> getAvailableProps() {
    if (props != null && props!.isNotEmpty) {
      return props!;
    }
    
    // Default to basketball props for now as a fallback
    return basketballDefaultProps;
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    // Parse props if available
    List<PlayerProp>? playerProps;
    if (json['props'] != null && json['props'] is List) {
      playerProps = (json['props'] as List)
          .map((propJson) => PlayerProp.fromJson(propJson))
          .toList();
    }

    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      teamId: json['team_id'] ?? '',
      teamName: json['team_name'] ?? '',
      jerseyNumber: json['jersey_number'],
      stats: json['stats'],
      props: playerProps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'team_id': teamId,
      'team_name': teamName,
      'jersey_number': jerseyNumber,
      'stats': stats,
      'props': props?.map((prop) => prop.toJson()).toList(),
    };
  }
}
