// lib/models/sports/player.dart
class PlayerProp { // Define PlayerProp class as a data model for player betting propositions
  final String name; // Declare final string field for the prop name (e.g., "Points", "Rebounds", "Assists")
  final double value; // Declare final double field for the prop value (e.g., 22.5)
  final String overOdds; // Declare final string field for the over betting odds (e.g., "-110")
  final String underOdds; // Declare final string field for the under betting odds (e.g., "-110")

  PlayerProp({ // Constructor for PlayerProp class with required parameters
    required this.name, // Initialize required name parameter
    required this.value, // Initialize required value parameter
    required this.overOdds, // Initialize required overOdds parameter
    required this.underOdds, // Initialize required underOdds parameter
  }); // End of constructor

  factory PlayerProp.fromJson(Map<String, dynamic> json) { // Define factory constructor to create PlayerProp from JSON
    return PlayerProp( // Return a new PlayerProp instance
      name: json['name'] ?? '', // Extract name from 'name' key with default empty string
      value: (json['value'] is double) ? json['value'] : double.tryParse(json['value']?.toString() ?? '0') ?? 0.0, // Parse value to double with safe fallback
      overOdds: json['over_odds']?.toString() ?? '-110', // Extract overOdds from 'over_odds' key with default '-110'
      underOdds: json['under_odds']?.toString() ?? '-110', // Extract underOdds from 'under_odds' key with default '-110'
    ); // End of PlayerProp constructor call
  } // End of fromJson factory constructor

  Map<String, dynamic> toJson() { // Define method to convert PlayerProp instance to JSON
    return { // Return a Map with player prop properties
      'name': name, // Map name field to 'name' key
      'value': value, // Map value field to 'value' key
      'over_odds': overOdds, // Map overOdds field to 'over_odds' key
      'under_odds': underOdds, // Map underOdds field to 'under_odds' key
    }; // End of Map literal
  } // End of toJson method
} // End of PlayerProp class

class Player { // Define Player class as a data model for sports players
  final String id; // Declare final string field for unique player identifier
  final String name; // Declare final string field for the player's name
  final String position; // Declare final string field for the player's position
  final String teamId; // Declare final string field for the player's team ID
  final String teamName; // Declare final string field for the player's team name
  final String? jerseyNumber; // Declare optional final string field for the player's jersey number
  final Map<String, dynamic>? stats; // Declare optional final Map field for player statistics
  final List<PlayerProp>? props; // Declare optional final List field for player betting propositions

  Player({ // Constructor for Player class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.name, // Initialize required name parameter
    required this.position, // Initialize required position parameter
    required this.teamId, // Initialize required teamId parameter
    required this.teamName, // Initialize required teamName parameter
    this.jerseyNumber, // Initialize optional jerseyNumber parameter
    this.stats, // Initialize optional stats parameter
    this.props, // Initialize optional props parameter
  }); // End of constructor

  // For basketball, get the standard props that most players have
  List<PlayerProp> get basketballDefaultProps { // Define getter for default basketball props
    // These values are examples and should be replaced with real data when available
    return [ // Return a list of default basketball player props
      PlayerProp(name: 'Points', value: 18.5, overOdds: '-110', underOdds: '-110'), // Create Points prop with default values
      PlayerProp(name: 'Rebounds', value: 5.5, overOdds: '-110', underOdds: '-110'), // Create Rebounds prop with default values
      PlayerProp(name: 'Assists', value: 4.5, overOdds: '-110', underOdds: '-110'), // Create Assists prop with default values
      PlayerProp(name: '3-Pointers Made', value: 1.5, overOdds: '-110', underOdds: '-110'), // Create 3-Pointers Made prop with default values
    ]; // End of default props list
  } // End of basketballDefaultProps getter

  // Get available props - if none are available, return default ones for demo purposes
  List<PlayerProp> getAvailableProps() { // Define method to get available player props
    if (props != null && props!.isNotEmpty) { // Check if props exist and are not empty
      return props!; // Return the existing props
    } // End of props existence check
    
    // Default to basketball props for now as a fallback
    return basketballDefaultProps; // Return default basketball props as fallback
  } // End of getAvailableProps method

  factory Player.fromJson(Map<String, dynamic> json) { // Define factory constructor to create Player from JSON
    // Parse props if available
    List<PlayerProp>? playerProps; // Declare variable to hold parsed player props
    if (json['props'] != null && json['props'] is List) { // Check if props exist and are a list
      playerProps = (json['props'] as List) // Cast props to List
          .map((propJson) => PlayerProp.fromJson(propJson)) // Map each prop JSON to PlayerProp instance
          .toList(); // Convert mapped props to list
    } // End of props parsing

    return Player( // Return a new Player instance
      id: json['id'] ?? '', // Extract id from 'id' key with default empty string
      name: json['name'] ?? '', // Extract name from 'name' key with default empty string
      position: json['position'] ?? '', // Extract position from 'position' key with default empty string
      teamId: json['team_id'] ?? '', // Extract teamId from 'team_id' key with default empty string
      teamName: json['team_name'] ?? '', // Extract teamName from 'team_name' key with default empty string
      jerseyNumber: json['jersey_number'], // Extract jerseyNumber from 'jersey_number' key
      stats: json['stats'], // Extract stats from 'stats' key
      props: playerProps, // Set props to parsed player props
    ); // End of Player constructor call
  } // End of fromJson factory constructor

  Map<String, dynamic> toJson() { // Define method to convert Player instance to JSON
    return { // Return a Map with player properties
      'id': id, // Map id field to 'id' key
      'name': name, // Map name field to 'name' key
      'position': position, // Map position field to 'position' key
      'team_id': teamId, // Map teamId field to 'team_id' key
      'team_name': teamName, // Map teamName field to 'team_name' key
      'jersey_number': jerseyNumber, // Map jerseyNumber field to 'jersey_number' key
      'stats': stats, // Map stats field to 'stats' key
      'props': props?.map((prop) => prop.toJson()).toList(), // Map props to JSON list if props exist
    }; // End of Map literal
  } // End of toJson method
} // End of Player class
