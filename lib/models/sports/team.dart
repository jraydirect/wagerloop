//lib/models/sports/team.dart

class Team {
  final String id;
  final String name;        // Full name, e.g. "St. Louis Cardinals"
  final String shortName;   // Short name, e.g. "Cardinals"
  final String location;    // Location, e.g. "St. Louis"
  final String? logo;       // URL to team logo
  final String sport;       // Sport type: "MLB", "NBA", etc.
  final String league;      // League: "MLB", "NBA", "NFL", etc.

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    this.logo,
    required this.sport,
    required this.league,
  });

  // Factory constructor to create a Team from JSON data
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      shortName: json['short_name'],
      location: json['location'],
      logo: json['logo'],
      sport: json['sport'],
      league: json['league'],
    );
  }

  // Convert Team object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'location': location,
      'logo': logo,
      'sport': sport,
      'league': league,
    };
  }
}
