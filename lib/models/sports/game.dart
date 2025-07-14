import 'odds.dart'; // Import the OddsData model class for use in game odds

class Game { // Define Game class as a data model for sports games
  final String id; // Declare final string field for unique game identifier
  final String homeTeam; // Declare final string field for the home team name
  final String awayTeam; // Declare final string field for the away team name
  final String homeTeamId; // Declare final string field for the home team ID
  final String awayTeamId; // Declare final string field for the away team ID
  final DateTime gameTime; // Declare final DateTime field for when the game is scheduled
  final String sport; // Declare final string field for the sport type
  final String league; // Declare final string field for the league name
  final Map<String, dynamic>? odds; // Declare optional Map field for general odds data
  final Map<String, OddsData>? sportsbookOdds; // Declare optional Map field for sportsbook-specific odds
  final String status; // Declare final string field for game status (scheduled, live, finished)
  final int? homeScore; // Declare optional int field for the home team's score
  final int? awayScore; // Declare optional int field for the away team's score
  final String? period; // Declare optional string field for the current game period (Quarter, Half, Period, Inning, etc.)

  Game({ // Constructor for Game class with required and optional parameters
    required this.id, // Initialize required id parameter
    required this.homeTeam, // Initialize required homeTeam parameter
    required this.awayTeam, // Initialize required awayTeam parameter
    this.homeTeamId = '', // Initialize homeTeamId parameter with default empty string
    this.awayTeamId = '', // Initialize awayTeamId parameter with default empty string
    required this.gameTime, // Initialize required gameTime parameter
    required this.sport, // Initialize required sport parameter
    required this.league, // Initialize required league parameter
    this.odds, // Initialize optional odds parameter
    this.sportsbookOdds, // Initialize optional sportsbookOdds parameter
    required this.status, // Initialize required status parameter
    this.homeScore, // Initialize optional homeScore parameter
    this.awayScore, // Initialize optional awayScore parameter
    this.period, // Initialize optional period parameter
  }); // End of constructor

  String get matchupString => '$homeTeam vs $awayTeam'; // Define getter to return formatted matchup string
  
  String get formattedGameTime { // Define getter to return formatted game time string
    // Convert to Central Time
    final centralTime = _convertToCentralTime(gameTime); // Convert game time to Central Time
    
    // Get current time in Central Time for comparison
    final now = _convertToCentralTime(DateTime.now()); // Convert current time to Central Time
    
    // Check if game is today or tomorrow
    final isToday = centralTime.year == now.year && // Check if year matches
                    centralTime.month == now.month && // Check if month matches
                    centralTime.day == now.day; // Check if day matches
    final isTomorrow = centralTime.year == now.year && // Check if year matches
                       centralTime.month == now.month && // Check if month matches
                       centralTime.day == now.day + 1; // Check if day is tomorrow
    
    // Format date and time
    final date = '${centralTime.month}/${centralTime.day}'; // Format date as MM/DD
    
    // Format time in 12-hour format with AM/PM
    String formattedTime; // Declare variable for formatted time string
    int hour = centralTime.hour; // Get hour from central time
    final amPm = hour >= 12 ? 'PM' : 'AM'; // Determine AM/PM based on hour
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour); // Convert to 12-hour format
    formattedTime = '$hour:${centralTime.minute.toString().padLeft(2, '0')} $amPm CT'; // Format time string with minutes padded to 2 digits
    
    // Return formatted string
    if (isToday) { // Check if game is today
      return 'Today - $date - $formattedTime'; // Return today format
    } else if (isTomorrow) { // Check if game is tomorrow
      return 'Tomorrow - $date - $formattedTime'; // Return tomorrow format
    } else { // Game is on another date
      return '$date - $formattedTime'; // Return standard date format
    } // End of date formatting conditions
  } // End of formattedGameTime getter
  
  // Helper method to convert UTC time to Central Time
  DateTime _convertToCentralTime(DateTime dateTime) { // Define private method to convert UTC to Central Time
    // ESPN API provides times in UTC
    // Central Time is UTC-6 for CST or UTC-5 for CDT
    // For simplicity, we'll use a fixed offset of -6 hours (CST)
    // In a production app, you'd want to properly handle daylight saving time
    return dateTime.subtract(const Duration(hours: 6)); // Subtract 6 hours from UTC to get Central Time
  } // End of _convertToCentralTime method
  
  // Check if game is scheduled within the next month
  bool get isWithinNextMonth { // Define getter to check if game is within next month
    try { // Begin try block for error handling
      final now = DateTime.now(); // Get current date and time
      
      // Create a date one month from now
      // We need to handle month overflow (e.g., month 12 + 1)
      DateTime oneMonthFromNow; // Declare variable for one month from now
      if (now.month == 12) { // Check if current month is December
        oneMonthFromNow = DateTime(now.year + 1, 1, now.day); // Create date for January of next year
      } else { // Current month is not December
        oneMonthFromNow = DateTime(now.year, now.month + 1, now.day); // Create date for next month
      } // End of month overflow handling
      
      // Convert UTC game time to local time for fair comparison
      final localGameTime = gameTime.toLocal(); // Convert game time to local timezone
      // Convert to date only (no time) for comparison
      final gameDate = DateTime(localGameTime.year, localGameTime.month, localGameTime.day); // Create date-only version of game time
      final nowDate = DateTime(now.year, now.month, now.day); // Create date-only version of current time
      final oneMonthFromNowDate = DateTime(oneMonthFromNow.year, oneMonthFromNow.month, oneMonthFromNow.day); // Create date-only version of one month from now
      
      // Game should be today or later, and earlier than one month from now
      final result = (gameDate.isAfter(nowDate) || gameDate.isAtSameMomentAs(nowDate)) && // Check if game is today or later
                     (gameDate.isBefore(oneMonthFromNowDate) || gameDate.isAtSameMomentAs(oneMonthFromNowDate)); // Check if game is within one month
      
      return result; // Return the calculated result
    } catch (e) { // Catch any exceptions during date calculations
      // Default to true to include games with date calculation issues
      return true; // Return true as default to include games with calculation errors
    } // End of try-catch block
  } // End of isWithinNextMonth getter

  factory Game.fromJson(Map<String, dynamic> json) { // Define factory constructor to create Game from JSON
    // Parse sportsbookOdds if available
    Map<String, OddsData>? sportsbookOdds; // Declare variable for sportsbook odds
    if (json.containsKey('sportsbook_odds') && json['sportsbook_odds'] != null) { // Check if sportsbook odds exist in JSON
      sportsbookOdds = <String, OddsData>{}; // Initialize empty map for sportsbook odds
      final oddsMap = json['sportsbook_odds'] as Map<String, dynamic>; // Cast odds data to map
      oddsMap.forEach((key, value) { // Iterate through each odds entry
        sportsbookOdds![key] = OddsData.fromJson(value); // Convert each odds entry to OddsData instance
      }); // End of odds parsing loop
    } // End of odds parsing condition
    
    return Game( // Return a new Game instance
      id: json['id'], // Extract id from 'id' key
      homeTeam: json['home_team'], // Extract homeTeam from 'home_team' key
      awayTeam: json['away_team'], // Extract awayTeam from 'away_team' key
      homeTeamId: json['home_team_id'] ?? '', // Extract homeTeamId from 'home_team_id' key with default empty string
      awayTeamId: json['away_team_id'] ?? '', // Extract awayTeamId from 'away_team_id' key with default empty string
      gameTime: DateTime.parse(json['game_time']), // Parse gameTime from 'game_time' key
      sport: json['sport'], // Extract sport from 'sport' key
      league: json['league'], // Extract league from 'league' key
      odds: json['odds'], // Extract odds from 'odds' key
      sportsbookOdds: sportsbookOdds, // Set sportsbookOdds to parsed odds
      status: json['status'], // Extract status from 'status' key
      homeScore: json['home_score'], // Extract homeScore from 'home_score' key
      awayScore: json['away_score'], // Extract awayScore from 'away_score' key
      period: json['period'], // Extract period from 'period' key
    ); // End of Game constructor call
  } // End of fromJson factory constructor

  Map<String, dynamic> toJson() { // Define method to convert Game instance to JSON
    final Map<String, dynamic> json = { // Create map with game properties
      'id': id, // Map id field to 'id' key
      'home_team': homeTeam, // Map homeTeam field to 'home_team' key
      'away_team': awayTeam, // Map awayTeam field to 'away_team' key
      'home_team_id': homeTeamId, // Map homeTeamId field to 'home_team_id' key
      'away_team_id': awayTeamId, // Map awayTeamId field to 'away_team_id' key
      'game_time': gameTime.toIso8601String(), // Map gameTime field to 'game_time' key as ISO string
      'sport': sport, // Map sport field to 'sport' key
      'league': league, // Map league field to 'league' key
      'odds': odds, // Map odds field to 'odds' key
      'status': status, // Map status field to 'status' key
      'home_score': homeScore, // Map homeScore field to 'home_score' key
      'away_score': awayScore, // Map awayScore field to 'away_score' key
      'period': period, // Map period field to 'period' key
    }; // End of json map initialization
    
    if (sportsbookOdds != null) { // Check if sportsbookOdds exists
      final sportsbookOddsJson = <String, dynamic>{}; // Create empty map for sportsbook odds JSON
      sportsbookOdds!.forEach((key, value) { // Iterate through each sportsbook odds entry
        sportsbookOddsJson[key] = value.toJson(); // Convert each OddsData to JSON and add to map
      }); // End of odds conversion loop
      json['sportsbook_odds'] = sportsbookOddsJson; // Add sportsbook odds to main JSON map
    } // End of sportsbookOdds conversion condition
    
    return json; // Return the JSON map
  } // End of toJson method
} // End of Game class
