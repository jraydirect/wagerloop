// Import Dart async library for asynchronous operations - provides Future and async/await functionality
import 'dart:async';
// Import Dart convert library for JSON operations - provides JSON encoding and decoding
import 'dart:convert';
// Import Flutter foundation library for platform detection - provides kIsWeb and other platform utilities
import 'package:flutter/foundation.dart';
// Import HTTP library for API requests - provides HTTP client for making API calls
import 'package:http/http.dart' as http;
// Import Flutter material library for widgets - provides TextEditingController
import 'package:flutter/material.dart';
// Import Game model for sports games - provides data structure for game information
import '../models/sports/game.dart';
// Import Odds model for betting odds - provides data structure for odds information
import '../models/sports/odds.dart';
// Import Player model for sports players - provides data structure for player information
import '../models/sports/player.dart';
// Import sports odds service for betting data - provides access to betting odds functionality
import 'sports_odds_service.dart';

// Service class for handling sports API operations - manages sports data retrieval and processing
class SportsApiService {
  // Singleton pattern implementation - ensures only one instance exists throughout the app
  static final SportsApiService _instance = SportsApiService._internal();
  // Factory constructor that returns the singleton instance - provides global access to the same instance
  factory SportsApiService() => _instance;
  // Private internal constructor for singleton pattern - prevents external instantiation
  SportsApiService._internal();

  // TextEditingController for caching search queries - stores search input for reuse
  static TextEditingController? searchController;

  // Cache data to avoid repeated API calls - stores games by sport to reduce API requests
  final Map<String, List<Game>> _cachedGamesBySport = {};
  // Timestamp of last fetch for cache validation - tracks when data was last retrieved
  DateTime? _lastFetchTime;
  
  // Cache validity period (15 minutes) - defines how long cached data remains valid
  final Duration _cacheValidity = const Duration(minutes: 15);

  // ESPN API base URL - the base domain for ESPN's sports API
  final String _baseUrl = 'site.api.espn.com';
  
  // API key for paid services (if needed) - stores API key for premium features
  String? _apiKey;
  
  // Set API key for any paid services - allows setting API key for premium API access
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  // Sport codes for ESPN API - maps our app's sport keys to ESPN's format
  final Map<String, String> _sportCodes = {
    'NBA': 'basketball/nba',
    'NFL': 'football/nfl',
    'MLB': 'baseball/mlb',
    'NHL': 'hockey/nhl',
    'Soccer': 'soccer',
    'NCAAB': 'basketball/mens-college-basketball',
    'NCAAF': 'football/college-football',
  };

  /// Search for games by team name or any keyword across all sports
  Future<List<Game>> searchGamesByTeam(String query, {Function(List<Game>)? onIncrementalResults}) async {
    // Return empty list if query is empty - handles empty search queries
    if (query.isEmpty) {
      return [];
    }
    
    // Print debug message with search query - logs search operation for debugging
    print('Searching for games with query: $query');
    
    try {
      // Normalize query to lowercase for case-insensitive matching - ensures consistent search
      final normalizedQuery = query.toLowerCase();
      // List to store all matching games - accumulates search results
      List<Game> allGames = [];
      
      // The minimum date for returned games (yesterday) - filters out old games
      final minDate = DateTime.now().subtract(const Duration(days: 1));
      // Print debug message with minimum date filter - logs date filtering
      print('Using minimum date filter: ${minDate.toString()}');
      
      // Try sports in order of popularity - prioritizes popular sports for better results
      List<String> sportsToTry = ['NCAAB', 'NBA', 'NFL', 'NCAAF', 'MLB', 'NHL', 'Soccer'];
      
      // Loop through each sport to search for games - searches each sport for matches
      for (final sportKey in sportsToTry) {
        try {
          // Print debug message for current sport - logs which sport is being searched
          print('Trying $sportKey scoreboard API');
          // Fetch games for current sport - retrieves games from ESPN API
          final games = await _fetchGamesFromESPN(sportKey);
          
          // Filter games by team name and date - finds games matching search criteria
          for (final game in games) {
            try {
              // Check if home team matches query - searches home team name
              final homeMatch = game.homeTeam.toLowerCase().contains(normalizedQuery);
              // Check if away team matches query - searches away team name
              final awayMatch = game.awayTeam.toLowerCase().contains(normalizedQuery);
              
              // If either team matches the query - includes games with matching teams
              if (homeMatch || awayMatch) {
                // Check date is on or after minDate - filters out old games
                if (game.gameTime.isAfter(minDate) || game.gameTime.isAtSameMomentAs(minDate)) {
                  // Include games that are scheduled or live - focuses on relevant games
                  if (game.status == 'scheduled' || game.status == 'live') {
                    // Print debug message for found match - logs successful matches
                    print('Match found in $sportKey: ${game.homeTeam} vs ${game.awayTeam} (Status: ${game.status})');
                    // Add game to results list - includes game in search results
                    allGames.add(game);
                    
                    // Provide immediate feedback if callback provided - enables real-time results
                    if (onIncrementalResults != null) {
                      onIncrementalResults(List.from(allGames));
                    }
                  }
                }
              }
            } catch (e) {
              // Print error if checking match fails - logs individual game processing errors
              print('Error checking match in $sportKey: $e');
            }
          }
        } catch (e) {
          // Print error if searching sport fails - logs sport search errors
          print('Error searching $sportKey: $e');
          // Continue to next sport - ensures other sports are still searched
          continue;
        }
      }
      
      // Sort games by date (earliest first) - orders results chronologically
      allGames.sort((a, b) => a.gameTime.compareTo(b.gameTime));
      
      // Print debug message with total results - logs final search results
      print('Search complete. Found ${allGames.length} games total');
      
      // Return the filtered and sorted games - provides final search results
      return allGames;
    } catch (e) {
      // Print error if search fails - logs overall search errors
      print('Error in searchGamesByTeam: $e');
      // Return empty list on error - provides safe fallback
      return [];
    }
  }

  /// Fetch upcoming games for a specific sport
  Future<List<Game>> fetchUpcomingGames({String? sport}) async {
    // Check if we have valid cached data - validates cache before using
    final now = DateTime.now();
    // Check if cache is still valid - determines if cached data is fresh
    final cacheIsValid = _lastFetchTime != null && 
                         now.difference(_lastFetchTime!) < _cacheValidity;
    
    // Return cached data if available and valid - uses cached data to avoid API calls
    if (sport != null && _cachedGamesBySport.containsKey(sport) && cacheIsValid) {
      return _cachedGamesBySport[sport]!;
    }
    
    try {
      // List to store all games - accumulates games from API calls
      List<Game> games = [];
      
      // If specific sport requested - handles single sport requests
      if (sport != null) {
        // Fetch games for a specific sport - retrieves games for requested sport
        games = await _fetchGamesFromESPN(sport);
      } else {
        // Fetch games for all supported sports - retrieves games for all sports
        for (final sportKey in _sportCodes.keys) {
          // Fetch games for current sport - retrieves games for each sport
          final sportGames = await _fetchGamesFromESPN(sportKey);
          // Add to games list - accumulates all games
          games.addAll(sportGames);
        }
      }
      
      // Update cache - stores games for future use
      if (sport != null) {
        // Cache games for specific sport - stores single sport games
        _cachedGamesBySport[sport] = games;
      } else {
        // Group games by sport for caching - organizes games by sport for caching
        final gamesBySport = <String, List<Game>>{};
        for (final game in games) {
          gamesBySport.putIfAbsent(game.sport, () => []).add(game);
        }
        // Add all sport groups to cache - stores all sport groups
        _cachedGamesBySport.addAll(gamesBySport);
      }
      
      // Update last fetch time - records when data was last retrieved
      _lastFetchTime = now;
      // Return the games - provides requested games
      return games;
    } catch (e) {
      // Print error if fetching games fails - logs game fetching errors
      print('Error fetching games: $e');
      // Return empty list on error - provides safe fallback
      return [];
    }
  }

  /// Fetch game with detailed sportsbook odds
  Future<Game?> fetchGameWithSportsbookOdds(String gameId, String sport, {List<String>? sportsbooks}) async {
    try {
      // Print debug message with game ID and sport - logs game fetching operation
      print('Fetching game with sportsbook odds for gameId: $gameId, sport: $sport');
      
      // First fetch the game details from the standard API - retrieves basic game information
      final games = await _fetchGamesFromESPN(sport);
      
      // Try to find by exact ID match first - searches for game by exact ID
      int gameIndex = games.indexWhere((game) => game.id == gameId);
      
      // If not found by ID, try to match by team names - provides fallback matching
      if (gameIndex == -1) {
        // Print debug message for alternative matching - logs fallback matching attempt
        print('Game not found by ID in ESPN data, trying alternative matching');
        
        // Extract team names from the search query if available - uses search context
        String? teamQuery;
        if (searchController != null && searchController!.text.isNotEmpty) {
          teamQuery = searchController!.text;
          // Print debug message with search text - logs search context
          print('Using search text to match: $teamQuery');
        }
        
        // If search query contains 'vs', extract team names - parses team names from search
        if (teamQuery != null && teamQuery.contains('vs')) {
          // Extract team names from search query - splits search query into team names
          final teamParts = teamQuery.split('vs');
          if (teamParts.length >= 2) {
            // Get home team name - extracts first team name
            final homeTeam = teamParts[0].trim();
            // Get away team name - extracts second team name
            String awayTeam = teamParts[1].trim();
            // Remove game time if it's in parentheses - cleans up team name
            if (awayTeam.contains('(')) {
              awayTeam = awayTeam.split('(')[0].trim();
            }
            
            // Print debug message with team names - logs extracted team names
            print('Trying to match: $homeTeam vs $awayTeam');
            
            // Try to find a match by team names - searches for game by team names
            for (var game in games) {
              // Check if team names match (in either order) - handles team name variations
              if ((game.homeTeam.toLowerCase().contains(homeTeam.toLowerCase()) && 
                   game.awayTeam.toLowerCase().contains(awayTeam.toLowerCase())) ||
                  (game.homeTeam.toLowerCase().contains(awayTeam.toLowerCase()) && 
                   game.awayTeam.toLowerCase().contains(homeTeam.toLowerCase()))) {
                
                // Print debug message for found match - logs successful team name match
                print('Found match by team names: ${game.homeTeam} vs ${game.awayTeam}');
                // Set game index to found game - updates game index
                gameIndex = games.indexOf(game);
                break;
              }
            }
          }
        }
      }
      
      // If still not found, log error and return null - handles complete failure
      if (gameIndex == -1) {
        // Print error message - logs game not found
        print('Game not found with ID: $gameId in $sport');
        return null;
      }
      
      // Get the found game - retrieves the matched game
      final game = games[gameIndex];
      // Print debug message with game details - logs found game information
      print('Found game: ${game.homeTeam} vs ${game.awayTeam} at ${game.gameTime}');
      
      // Get the sportsbooks odds service - creates odds service instance
      final sportsOddsService = SportsOddsService();
      
      // Try to directly fetch odds for just this game first - attempts direct odds fetch
      print('Fetching odds directly for gameId: $gameId');
      final directOdds = await sportsOddsService.fetchOddsForGame(gameId, sport, sportsbooks: sportsbooks);
      
      // If direct odds fetch was successful - handles successful direct fetch
      if (directOdds.isNotEmpty) {
        // Print debug message with odds count - logs successful odds fetch
        print('Got direct odds for game from ${directOdds.length} sportsbooks');
        // Create a new game object with the sportsbook odds included - combines game and odds data
        final gameWithOdds = Game(
          id: game.id,
          homeTeam: game.homeTeam,
          awayTeam: game.awayTeam,
          homeTeamId: game.homeTeamId,
          awayTeamId: game.awayTeamId,
          gameTime: game.gameTime,
          sport: game.sport,
          league: game.league,
          status: game.status,
          odds: game.odds,
          sportsbookOdds: directOdds,
        );
        
        // Return game with odds - provides game with betting odds
        return gameWithOdds;
      }
      
      // If direct fetch fails, try getting all odds for the sport - provides fallback odds fetch
      print('Direct odds fetch failed or empty, trying to fetch all odds for sport');
      final allOddsForSport = await sportsOddsService.fetchOddsForSport(sport);
      // Print debug message with odds count - logs fallback odds fetch results
      print('Fetched odds for ${allOddsForSport.length} games in $sport');
      
      // Extract the odds for this specific game - finds odds for the specific game
      Map<String, OddsData>? sportsbookOdds = allOddsForSport[gameId];
      
      // Create a new game object with the sportsbook odds included - combines game and odds data
      final gameWithOdds = Game(
        id: game.id,
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        homeTeamId: game.homeTeamId,
        awayTeamId: game.awayTeamId,
        gameTime: game.gameTime,
        sport: game.sport,
        league: game.league,
        status: game.status,
        odds: game.odds,
        sportsbookOdds: sportsbookOdds,
      );
      
      // Check if sportsbook odds were found - validates odds availability
      if (sportsbookOdds == null || sportsbookOdds.isEmpty) {
        // Print warning if no odds found - logs missing odds
        print('No sportsbook odds found for game: $gameId');
      } else {
        // Print debug message with sportsbook count - logs successful odds retrieval
        print('Retrieved odds from ${sportsbookOdds.length} sportsbooks for game');
      }
      
      // Return game with odds - provides game with betting odds
      return gameWithOdds;
    } catch (e) {
      // Print error if fetching game with odds fails - logs odds fetching errors
      print('Error fetching game with sportsbook odds: $e');
      return null;
    }
  }

  /// Fetch games from ESPN API for a specific sport via scoreboard
  Future<List<Game>> _fetchGamesFromESPN(String sport) async {
    // Check if sport is supported - validates sport before API call
    if (!_sportCodes.containsKey(sport)) {
      return [];
    }
  
    // Get the ESPN sport code - converts app sport key to ESPN format
    final sportCode = _sportCodes[sport]!;
    // Build the API URL - constructs ESPN API endpoint
    final uri = Uri.https(_baseUrl, '/apis/site/v2/sports/$sportCode/scoreboard');
  
    try {
      // Prepare headers for API request - sets up HTTP headers
      final headers = <String, String>{};
      // Add API key if available - includes API key for premium access
      if (_apiKey != null) {
        headers['apiKey'] = _apiKey!;
      }
  
      // Make HTTP GET request to ESPN API - performs API call
      final response = await http.get(uri, headers: headers);
  
      // Check if request was successful - validates API response
      if (response.statusCode == 200) {
        // Parse JSON response - converts response to Dart objects
        final data = jsonDecode(response.body);
        // Parse games from response - extracts game data from API response
        return _parseESPNGames(data, sport);
      } else {
        // Print error if request failed - logs API request failures
        print('ESPN API request failed: Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      // Print error if API call fails - logs API call errors
      print('ESPN API call failed: $e');
      return [];
    }
  }

  /// Parse ESPN API response into Game objects
  List<Game> _parseESPNGames(Map<String, dynamic> data, String sport) {
    // List to store parsed games - accumulates parsed game objects
    final List<Game> games = [];
    // Print debug message for parsing start - logs parsing operation
    print('Starting to parse ESPN games for $sport');
    
    try {
      // Extract events from API response - gets events array from ESPN data
      final events = data['events'] as List? ?? [];
      
      // Check if events exist - validates events availability
      if (events.isEmpty) {
        // Print debug message if no events found - logs empty events
        print('No events found in $sport scoreboard API');
        return [];
      }
      
      // Print debug message with event count - logs event count
      print('Found ${events.length} events in $sport scoreboard');
      
      // Loop through each event - processes each game event
      for (var event in events) {
        try {
          // Extract event ID - gets unique event identifier
          final id = event['id'] as String? ?? '';
          // Extract competitions from event - gets competition data
          final competitions = event['competitions'] as List? ?? [];
          
          // Skip if no competitions - handles missing competition data
          if (competitions.isEmpty) {
            continue;
          }
          
          // Get the first competition - uses first competition (most sports have one)
          final competition = competitions[0];
          // Extract competitors from competition - gets team data
          final competitors = competition['competitors'] as List? ?? [];
          
          // Skip if not enough competitors - handles incomplete team data
          if (competitors.length < 2) {
            continue;
          }
          
          // Initialize team variables - sets up team data storage
          String homeTeam = '';
          String awayTeam = '';
          String homeTeamId = '';
          String awayTeamId = '';
          
          // Loop through competitors to get team information - processes team data
          for (var team in competitors) {
            // Check if team is home or away - determines team role
            final isHome = team['homeAway'] == 'home';
            // Get team data - extracts team information
            final teamData = team['team'] as Map<String, dynamic>? ?? {};
            // Extract team name - gets team display name
            final teamName = teamData['displayName'] as String? ?? 'Unknown Team';
            // Extract team ID - gets team identifier
            final teamId = teamData['id'] as String? ?? '';
            
            // Assign team to home or away based on flag - assigns team role
            if (isHome) {
              homeTeam = teamName;
              homeTeamId = teamId;
            } else {
              awayTeam = teamName;
              awayTeamId = teamId;
            }
          }
          
          // Get game time from competition - extracts game time
          final dateString = competition['date'] as String? ?? DateTime.now().toIso8601String();
          DateTime gameTime;
          try {
            // Parse game time - converts string to DateTime
            gameTime = DateTime.parse(dateString);
          } catch (e) {
            // Print error if date parsing fails - logs date parsing errors
            print('Error parsing date for $id: $e');
            // Use tomorrow as fallback - provides default date
            gameTime = DateTime.now().add(const Duration(days: 1));
          }
          
          // Get game status from competition - extracts game status
          final statusData = competition['status'] as Map<String, dynamic>? ?? {};
          final statusType = statusData['type'] as Map<String, dynamic>? ?? {};
          final status = statusType['state'] as String? ?? 'SCHEDULED';
          
          // Initialize score variables for live games - sets up live game data
          int? homeScore;
          int? awayScore;
          String? period;
          
          // If game is live, extract scores and period information - processes live game data
          if (status.toUpperCase() == 'IN' || status.toUpperCase() == 'LIVE') {
            try {
              // Extract scores from competitors - gets current scores
              for (var team in competitors) {
                // Check if team is home or away - determines team role
                final isHome = team['homeAway'] == 'home';
                // Parse score - converts score string to integer
                final score = int.tryParse(team['score'] ?? '') ?? 0;
                
                // Assign score to home or away - assigns score to correct team
                if (isHome) {
                  homeScore = score;
                } else {
                  awayScore = score;
                }
              }
              
              // Try to get period/quarter/inning information - extracts period data
              final displayPeriod = statusData['displayPeriod'] as int? ?? 0;
              final displayClock = statusData['displayClock'] as String? ?? '';
              
              // Convert period data to readable format based on sport - formats period for display
              switch (sport) {
                case 'NBA':
                case 'NCAAB':
                  // Format period for basketball - creates basketball period format
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'NFL':
                case 'NCAAF':
                  // Format period for football - creates football period format
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'MLB':
                  // Format period for baseball - creates baseball period format
                  final inningHalf = statusData['period'] == 'T' ? 'Top' : 'Bottom';
                  period = displayPeriod > 0 ? '$inningHalf ${_getOrdinal(displayPeriod)}' : '';
                  if (displayClock.isNotEmpty && period.isEmpty) {
                    period = displayClock;
                  }
                  break;
                  
                case 'NHL':
                  // Format period for hockey - creates hockey period format
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Period' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'Soccer':
                  // Format period for soccer - creates soccer period format
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Half' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                default:
                  // Default period format - provides fallback period format
                  if (displayClock.isNotEmpty) {
                    period = displayClock;
                  }
              }
            } catch (e) {
              // Print error if parsing live game data fails - logs live data parsing errors
              print('Error parsing live game data: $e');
              // Leave scores and period as null if parsing fails - provides safe fallback
            }
          }
          
          // Get odds if available - extracts betting odds data
          Map<String, dynamic>? odds;
          final oddsData = competition['odds'] as List? ?? [];
          
          // Parse odds if available - processes odds data
          if (oddsData.isNotEmpty) {
            final oddDetails = oddsData[0] as Map<String, dynamic>? ?? {};
            odds = _parseOddsFromESPN(oddDetails, sport);
          }
          
          // Create game object with all parsed data - constructs complete game object
          final game = Game(
            id: id,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeTeamId: homeTeamId,
            awayTeamId: awayTeamId,
            gameTime: gameTime,
            sport: sport,
            league: _getLeagueFromSport(sport),
            status: _mapESPNStatusToApp(status),
            odds: odds,
            homeScore: homeScore,
            awayScore: awayScore,
            period: period,
          );
          
          // Add game to list - includes game in results
          games.add(game);
        } catch (e) {
          // Print error if parsing individual game fails - logs individual game parsing errors
          print('Error parsing ESPN game data: $e');
          // Continue to next game - ensures other games are still processed
          continue;
        }
      }
    } catch (e) {
      // Print error if parsing overall response fails - logs overall parsing errors
      print('Error parsing ESPN games response: $e');
    }
    
    // Print debug message with parsed game count - logs final parsing results
    print('Parsed ${games.length} games for $sport from scoreboard API');
    return games;
  }

  /// Parse odds data from ESPN format
  Map<String, dynamic>? _parseOddsFromESPN(Map<String, dynamic> oddsData, String sport) {
    try {
      // Initialize result map - creates odds result structure
      final result = <String, dynamic>{};
      
      // Parse spread from ESPN data - extracts point spread
      final spread = oddsData['spread'] as double? ?? 0;
      result['spread'] = {
        'home': -spread,
        'away': spread,
      };
      
      // Parse over/under from ESPN data - extracts total points
      final overUnder = oddsData['overUnder'] as double? ?? 0;
      result['total'] = overUnder;
      
      // Set default moneyline (ESPN doesn't always provide this) - provides default moneyline
      result['moneyline'] = {
        'home': -110,
        'away': -110,
      };
      
      // Add draw for soccer - includes draw option for soccer
      if (sport == 'Soccer') {
        result['moneyline']['draw'] = 220;
      }
      
      return result;
    } catch (e) {
      // Return null if parsing fails - provides safe fallback
      return null;
    }
  }

  /// Map ESPN status to app status
  String _mapESPNStatusToApp(String espnStatus) {
    // Convert ESPN status to app status format - standardizes status values
    switch (espnStatus.toUpperCase()) {
      case 'PRE':
      case 'SCHEDULED':
        return 'scheduled';
      case 'IN':
      case 'LIVE':
        return 'live';
      case 'POST':
      case 'FINAL':
        return 'finished';
      default:
        return 'scheduled';
    }
  }

  /// Helper method to convert numbers to ordinals (1st, 2nd, 3rd, etc.)
  String _getOrdinal(int number) {
    // Return number as string if zero or negative - handles edge cases
    if (number <= 0) return number.toString();
    
    // Handle special cases for ordinal suffixes - processes ordinal formatting
    switch (number % 10) {
      case 1:
        if (number % 100 != 11) return '${number}st';
        break;
      case 2:
        if (number % 100 != 12) return '${number}nd';
        break;
      case 3:
        if (number % 100 != 13) return '${number}rd';
        break;
    }
    // Default to 'th' suffix - provides default ordinal suffix
    return '${number}th';
  }

  /// Get league name from sport
  String _getLeagueFromSport(String sport) {
    // Map sport to league name - converts sport codes to league names
    switch (sport) {
      case 'NBA':
      case 'NFL':
      case 'MLB':
      case 'NHL':
      case 'NCAAB':
      case 'NCAAF':
        return sport;
      case 'Soccer':
        return 'Various';
      default:
        return sport;
    }
  }
}
