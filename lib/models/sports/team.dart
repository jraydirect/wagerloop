//lib/models/sports/team.dart

class Team { // Define Team class as a data model for sports teams
  final String id; // Declare final string field for unique team identifier
  final String name; // Declare final string field for the full team name (e.g. "St. Louis Cardinals")
  final String shortName; // Declare final string field for the short team name (e.g. "Cardinals")
  final String location; // Declare final string field for the team's location (e.g. "St. Louis")
  final String? logo; // Declare optional final string field for the URL to team logo
  final String sport; // Declare final string field for the sport type (e.g. "MLB", "NBA")
  final String league; // Declare final string field for the league name (e.g. "MLB", "NBA", "NFL")

  Team({ // Constructor for Team class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.name, // Initialize required name parameter
    required this.shortName, // Initialize required shortName parameter
    required this.location, // Initialize required location parameter
    this.logo, // Initialize optional logo parameter
    required this.sport, // Initialize required sport parameter
    required this.league, // Initialize required league parameter
  }); // End of constructor

  // Factory constructor to create a Team from JSON data
  factory Team.fromJson(Map<String, dynamic> json) { // Define factory constructor to create Team from JSON
    return Team( // Return a new Team instance
      id: json['id'], // Extract id from 'id' key in JSON
      name: json['name'], // Extract name from 'name' key in JSON
      shortName: json['short_name'], // Extract shortName from 'short_name' key in JSON
      location: json['location'], // Extract location from 'location' key in JSON
      logo: json['logo'], // Extract logo from 'logo' key in JSON
      sport: json['sport'], // Extract sport from 'sport' key in JSON
      league: json['league'], // Extract league from 'league' key in JSON
    ); // End of Team constructor call
  } // End of fromJson factory constructor

  // Convert Team object to a JSON map
  Map<String, dynamic> toJson() { // Define method to convert Team instance to JSON
    return { // Return a Map with team properties
      'id': id, // Map id field to 'id' key
      'name': name, // Map name field to 'name' key
      'short_name': shortName, // Map shortName field to 'short_name' key
      'location': location, // Map location field to 'location' key
      'logo': logo, // Map logo field to 'logo' key
      'sport': sport, // Map sport field to 'sport' key
      'league': league, // Map league field to 'league' key
    }; // End of Map literal
  } // End of toJson method
} // End of Team class
