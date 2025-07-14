import 'dart:async'; // Import Dart's async library for Future and Timer functionality
import 'dart:convert'; // Import Dart's convert library for JSON parsing
import 'package:flutter/foundation.dart'; // Import Flutter foundation library for platform detection and debugging
import 'package:http/http.dart' as http; // Import HTTP package for making API requests
import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import '../models/sports/game.dart'; // Import Game model class
import '../models/sports/odds.dart'; // Import OddsData model class
import '../models/sports/player.dart'; // Import Player model class
import 'sports_odds_service.dart'; // Import sports odds service for sportsbook integration

class SportsApiService { // Define SportsApiService class to handle sports data from ESPN API
  // Singleton pattern
  static final SportsApiService _instance = SportsApiService._internal(); // Create static instance using private constructor
  factory SportsApiService() => _instance; // Factory constructor that returns the singleton instance
  SportsApiService._internal(); // Private constructor to prevent external instantiation

  // TextEditingController for caching search queries
  static TextEditingController? searchController; // Optional static text controller for search query caching

  // Cache data to avoid repeated API calls
  final Map<String, List<Game>> _cachedGamesBySport = {}; // Map to cache games by sport to reduce API calls
  DateTime? _lastFetchTime; // Optional DateTime to track when data was last fetched
  
  // Cache validity period (15 minutes)
  final Duration _cacheValidity = const Duration(minutes: 15); // Define cache validity duration as 15 minutes

  // ESPN API base URL
  final String _baseUrl = 'site.api.espn.com'; // Define constant for ESPN API base URL
  
  // API key for paid services (if needed)
  String? _apiKey; // Optional API key for paid ESPN services
  
  // Set API key for any paid services
  void setApiKey(String apiKey) { // Define method to set ESPN API key
    _apiKey = apiKey; // Set the API key field to the provided value
  } // End of setApiKey method

  // Sport codes for ESPN API - maps our app's sport keys to ESPN's format
  final Map<String, String> _sportCodes = { // Map to convert app sport names to ESPN API endpoints
    'NBA': 'basketball/nba', // Map NBA to basketball/nba endpoint
    'NFL': 'football/nfl', // Map NFL to football/nfl endpoint
    'MLB': 'baseball/mlb', // Map MLB to baseball/mlb endpoint
    'NHL': 'hockey/nhl', // Map NHL to hockey/nhl endpoint
    'Soccer': 'soccer', // Map Soccer to soccer endpoint
    'NCAAB': 'basketball/mens-college-basketball', // Map NCAAB to basketball/mens-college-basketball endpoint
    'NCAAF': 'football/college-football', // Map NCAAF to football/college-football endpoint
  }; // End of sport codes map

  /// Search for games by team name or any keyword across all sports
  Future<List<Game>> searchGamesByTeam(String query, {Function(List<Game>)? onIncrementalResults}) async { // Define async method to search for games by team name
    if (query.isEmpty) { // Check if search query is empty
      return []; // Return empty list for empty query
    } // End of query check
    
    print('Searching for games with query: $query'); // Log the search query
    
    try { // Begin try block for search error handling
      final normalizedQuery = query.toLowerCase(); // Convert query to lowercase for case-insensitive matching
      List<Game> allGames = []; // Initialize list to store all matching games
      
      // The minimum date for returned games
      final minDate = DateTime.now().subtract(const Duration(days: 1)); // Calculate minimum date as yesterday
      print('Using minimum date filter: ${minDate.toString()}'); // Log the minimum date filter
      
      // Try sports in order of popularity
      List<String> sportsToTry = ['NCAAB', 'NBA', 'NFL', 'NCAAF', 'MLB', 'NHL', 'Soccer']; // Define sports to search in order of popularity
      
      for (final sportKey in sportsToTry) { // Iterate through each sport to search
        try { // Begin try block for individual sport search
          print('Trying $sportKey scoreboard API'); // Log the sport being searched
          final games = await _fetchGamesFromESPN(sportKey); // Fetch games from ESPN for the current sport
          
          // Filter games by team name and date
          for (final game in games) { // Iterate through each game from the current sport
            try { // Begin try block for game filtering
              final homeMatch = game.homeTeam.toLowerCase().contains(normalizedQuery); // Check if home team matches query
              final awayMatch = game.awayTeam.toLowerCase().contains(normalizedQuery); // Check if away team matches query
              
              if (homeMatch || awayMatch) { // Check if either team matches the query
                // Check date is on or after minDate
                if (game.gameTime.isAfter(minDate) || game.gameTime.isAtSameMomentAs(minDate)) { // Check if game date is valid
                  // Include games that are scheduled or live
                  if (game.status == 'scheduled' || game.status == 'live') { // Check if game status is relevant
                    print('Match found in $sportKey: ${game.homeTeam} vs ${game.awayTeam} (Status: ${game.status})'); // Log the matching game
                    allGames.add(game); // Add matching game to results
                    
                    // Provide immediate feedback
                    if (onIncrementalResults != null) { // Check if incremental results callback is provided
                      onIncrementalResults(List.from(allGames)); // Call callback with current results
                    } // End of callback check
                  } // End of status check
                } // End of date check
              } // End of team match check
            } catch (e) { // Catch game filtering errors
              print('Error checking match in $sportKey: $e'); // Log game filtering error
            } // End of game filtering try-catch
          } // End of games iteration
        } catch (e) { // Catch sport search errors
          print('Error searching $sportKey: $e'); // Log sport search error
          continue; // Continue to next sport on error
        } // End of sport search try-catch
      } // End of sports iteration
      
      // Sort games by date
      allGames.sort((a, b) => a.gameTime.compareTo(b.gameTime)); // Sort games by game time in ascending order
      
      print('Search complete. Found ${allGames.length} games total'); // Log total number of games found
      
      return allGames; // Return the list of matching games
    } catch (e) { // Catch overall search errors
      print('Error in searchGamesByTeam: $e'); // Log overall search error
      return []; // Return empty list on error
    } // End of overall search try-catch
  } // End of searchGamesByTeam method

  /// Fetch upcoming games for a specific sport
  Future<List<Game>> fetchUpcomingGames({String? sport}) async { // Define async method to fetch upcoming games
    // Check if we have valid cached data
    final now = DateTime.now(); // Get current time
    final cacheIsValid = _lastFetchTime != null && // Check if last fetch time exists
                         now.difference(_lastFetchTime!) < _cacheValidity; // Check if cache is still valid
    
    if (sport != null && _cachedGamesBySport.containsKey(sport) && cacheIsValid) { // Check if cached data exists for specific sport and is valid
      return _cachedGamesBySport[sport]!; // Return cached games for the sport (non-null assertion)
    } // End of cache check
    
    try { // Begin try block for fetch error handling
      List<Game> games = []; // Initialize list to store fetched games
      
      if (sport != null) { // Check if specific sport is requested
        // Fetch games for a specific sport
        games = await _fetchGamesFromESPN(sport); // Fetch games for the specified sport
      } else { // If no specific sport requested
        // Fetch games for all supported sports
        for (final sportKey in _sportCodes.keys) { // Iterate through all supported sports
          final sportGames = await _fetchGamesFromESPN(sportKey); // Fetch games for current sport
          games.addAll(sportGames); // Add sport games to overall games list
        } // End of sports iteration
      } // End of sport check
      
      // Update cache
      if (sport != null) { // Check if specific sport was requested
        _cachedGamesBySport[sport] = games; // Cache games for the specific sport
      } else { // If all sports were fetched
        // Group games by sport
        final gamesBySport = <String, List<Game>>{}; // Initialize map to group games by sport
        for (final game in games) { // Iterate through all fetched games
          gamesBySport.putIfAbsent(game.sport, () => []).add(game); // Group games by sport, creating new list if needed
        } // End of games iteration
        _cachedGamesBySport.addAll(gamesBySport); // Add grouped games to cache
      } // End of cache update
      
      _lastFetchTime = now; // Update last fetch time
      return games; // Return the fetched games
    } catch (e) { // Catch fetch errors
      print('Error fetching games: $e'); // Log fetch error
      return []; // Return empty list on error
    } // End of fetch try-catch
  } // End of fetchUpcomingGames method

  /// Fetch game with detailed sportsbook odds
  Future<Game?> fetchGameWithSportsbookOdds(String gameId, String sport, {List<String>? sportsbooks}) async { // Define async method to fetch game with sportsbook odds
    try { // Begin try block for game with odds error handling
      print('Fetching game with sportsbook odds for gameId: $gameId, sport: $sport'); // Log game fetch attempt
      
      // First fetch the game details from the standard API
      final games = await _fetchGamesFromESPN(sport); // Fetch games from ESPN for the sport
      
      // Try to find by exact ID match first
      int gameIndex = games.indexWhere((game) => game.id == gameId); // Find game index by exact ID match
      
      // If not found by ID, try to match by team names
      if (gameIndex == -1) { // Check if game was not found by ID
        print('Game not found by ID in ESPN data, trying alternative matching'); // Log alternative matching attempt
        
        // Extract team names from the search query if available
        String? teamQuery; // Declare variable for team search query
        if (searchController != null && searchController!.text.isNotEmpty) { // Check if search controller exists and has text
          teamQuery = searchController!.text; // Get search text from controller
          print('Using search text to match: $teamQuery'); // Log search text usage
        } // End of search controller check
        
        if (teamQuery != null && teamQuery.contains('vs')) { // Check if team query exists and contains 'vs'
          // Extract team names from search query
          final teamParts = teamQuery.split('vs'); // Split query by 'vs' to get team parts
          if (teamParts.length >= 2) { // Check if we have at least 2 team parts
            final homeTeam = teamParts[0].trim(); // Get home team name (first part)
            String awayTeam = teamParts[1].trim(); // Get away team name (second part)
            // Remove game time if it's in parentheses
            if (awayTeam.contains('(')) { // Check if away team contains parentheses
              awayTeam = awayTeam.split('(')[0].trim(); // Remove parentheses and everything after
            } // End of parentheses check
            
            print('Trying to match: $homeTeam vs $awayTeam'); // Log team matching attempt
            
            // Try to find a match by team names
            for (var game in games) { // Iterate through games to find team match
              if ((game.homeTeam.toLowerCase().contains(homeTeam.toLowerCase()) && // Check if home team matches first part
                   game.awayTeam.toLowerCase().contains(awayTeam.toLowerCase())) || // And away team matches second part
                  (game.homeTeam.toLowerCase().contains(awayTeam.toLowerCase()) && // Or home team matches second part
                   game.awayTeam.toLowerCase().contains(homeTeam.toLowerCase()))) { // And away team matches first part
                
                print('Found match by team names: ${game.homeTeam} vs ${game.awayTeam}'); // Log successful team match
                gameIndex = games.indexOf(game); // Get index of matched game
                break; // Exit loop once match is found
              } // End of team match check
            } // End of games iteration for team matching
          } // End of team parts check
        } // End of team query check
      } // End of alternative matching
      
      // If still not found, log error and return null
      if (gameIndex == -1) { // Check if game is still not found
        print('Game not found with ID: $gameId in $sport'); // Log game not found error
        return null; // Return null if game not found
      } // End of game not found check
      
      final game = games[gameIndex]; // Get the found game from the list
      print('Found game: ${game.homeTeam} vs ${game.awayTeam} at ${game.gameTime}'); // Log found game details
      
      // Get the sportsbooks odds service
      final sportsOddsService = SportsOddsService(); // Create instance of sports odds service
      
      // Try to directly fetch odds for just this game first
      print('Fetching odds directly for gameId: $gameId'); // Log direct odds fetch attempt
      final directOdds = await sportsOddsService.fetchOddsForGame(gameId, sport, sportsbooks: sportsbooks); // Fetch odds directly for the game
      
      if (directOdds.isNotEmpty) { // Check if direct odds fetch was successful
        print('Got direct odds for game from ${directOdds.length} sportsbooks'); // Log successful direct odds fetch
        // Create a new game object with the sportsbook odds included
        final gameWithOdds = Game( // Create new Game instance with odds
          id: game.id, // Copy game ID
          homeTeam: game.homeTeam, // Copy home team
          awayTeam: game.awayTeam, // Copy away team
          homeTeamId: game.homeTeamId, // Copy home team ID
          awayTeamId: game.awayTeamId, // Copy away team ID
          gameTime: game.gameTime, // Copy game time
          sport: game.sport, // Copy sport
          league: game.league, // Copy league
          status: game.status, // Copy status
          odds: game.odds, // Copy original odds
          sportsbookOdds: directOdds, // Add sportsbook odds
        ); // End of Game constructor
        
        return gameWithOdds; // Return game with sportsbook odds
      } // End of direct odds check
      
      // If direct fetch fails, try getting all odds for the sport
      print('Direct odds fetch failed or empty, trying to fetch all odds for sport'); // Log fallback odds fetch attempt
      final allOddsForSport = await sportsOddsService.fetchOddsForSport(sport); // Fetch all odds for the sport
      print('Fetched odds for ${allOddsForSport.length} games in $sport'); // Log number of games with odds
      
      // Extract the odds for this specific game
      Map<String, OddsData>? sportsbookOdds = allOddsForSport[gameId]; // Get odds for specific game ID
      
      // Create a new game object with the sportsbook odds included
      final gameWithOdds = Game( // Create new Game instance with odds
        id: game.id, // Copy game ID
        homeTeam: game.homeTeam, // Copy home team
        awayTeam: game.awayTeam, // Copy away team
        homeTeamId: game.homeTeamId, // Copy home team ID
        awayTeamId: game.awayTeamId, // Copy away team ID
        gameTime: game.gameTime, // Copy game time
        sport: game.sport, // Copy sport
        league: game.league, // Copy league
        status: game.status, // Copy status
        odds: game.odds, // Copy original odds
        sportsbookOdds: sportsbookOdds, // Add sportsbook odds (may be null)
      ); // End of Game constructor
      
      if (sportsbookOdds == null || sportsbookOdds.isEmpty) { // Check if no sportsbook odds found
        print('No sportsbook odds found for game: $gameId'); // Log no odds found
      } else { // If sportsbook odds found
        print('Retrieved odds from ${sportsbookOdds.length} sportsbooks for game'); // Log successful odds retrieval
      } // End of odds check
      
      return gameWithOdds; // Return game with or without sportsbook odds
    } catch (e) { // Catch game with odds errors
      print('Error fetching game with sportsbook odds: $e'); // Log error
      return null; // Return null on error
    } // End of game with odds try-catch
  } // End of fetchGameWithSportsbookOdds method

  /// Fetch games from ESPN API for a specific sport via scoreboard
  Future<List<Game>> _fetchGamesFromESPN(String sport) async { // Define private async method to fetch games from ESPN API
    if (!_sportCodes.containsKey(sport)) { // Check if sport is supported
      return []; // Return empty list for unsupported sport
    } // End of sport support check
  
    final sportCode = _sportCodes[sport]!; // Get ESPN sport code (non-null assertion)
    final uri = Uri.https(_baseUrl, '/apis/site/v2/sports/$sportCode/scoreboard'); // Construct ESPN API URI
  
    try { // Begin try block for ESPN API request
      final headers = <String, String>{}; // Initialize headers map
      if (_apiKey != null) { // Check if API key is available
        headers['apiKey'] = _apiKey!; // Add API key to headers (non-null assertion)
      } // End of API key check
  
      final response = await http.get(uri, headers: headers); // Make HTTP GET request to ESPN API
  
      if (response.statusCode == 200) { // Check if response status is OK
        final data = jsonDecode(response.body); // Decode JSON response body
        return _parseESPNGames(data, sport); // Parse ESPN games data and return
      } else { // Handle non-200 response status
        print('ESPN API request failed: Status: ${response.statusCode}'); // Log API request failure
        return []; // Return empty list on API failure
      } // End of response status check
    } catch (e) { // Catch ESPN API request errors
      print('ESPN API call failed: $e'); // Log API call error
      return []; // Return empty list on error
    } // End of ESPN API try-catch
  } // End of _fetchGamesFromESPN method

  /// Parse ESPN API response into Game objects
  List<Game> _parseESPNGames(Map<String, dynamic> data, String sport) { // Define method to parse ESPN API response into Game objects
    final List<Game> games = []; // Initialize list to store parsed games
    print('Starting to parse ESPN games for $sport'); // Log parsing start
    
    try { // Begin try block for parsing error handling
      final events = data['events'] as List? ?? []; // Extract events list or default to empty list
      
      if (events.isEmpty) { // Check if events list is empty
        print('No events found in $sport scoreboard API'); // Log no events found
        return []; // Return empty list if no events
      } // End of events check
      
      print('Found ${events.length} events in $sport scoreboard'); // Log number of events found
      
      for (var event in events) { // Iterate through each event
        try { // Begin try block for individual event parsing
          final id = event['id'] as String? ?? ''; // Extract event ID or default to empty string
          final competitions = event['competitions'] as List? ?? []; // Extract competitions list or default to empty list
          
          if (competitions.isEmpty) { // Check if competitions list is empty
            continue; // Skip event if no competitions
          } // End of competitions check
          
          final competition = competitions[0]; // Get first competition
          final competitors = competition['competitors'] as List? ?? []; // Extract competitors list or default to empty list
          
          if (competitors.length < 2) { // Check if there are at least 2 competitors
            continue; // Skip competition if not enough competitors
          } // End of competitors check
          
          // Get teams
          String homeTeam = ''; // Initialize home team name
          String awayTeam = ''; // Initialize away team name
          String homeTeamId = ''; // Initialize home team ID
          String awayTeamId = ''; // Initialize away team ID
          
          for (var team in competitors) { // Iterate through each competitor
            final isHome = team['homeAway'] == 'home'; // Check if team is home team
            final teamData = team['team'] as Map<String, dynamic>? ?? {}; // Extract team data or default to empty map
            final teamName = teamData['displayName'] as String? ?? 'Unknown Team'; // Extract team name or default
            final teamId = teamData['id'] as String? ?? ''; // Extract team ID or default to empty string
            
            if (isHome) { // Check if this is the home team
              homeTeam = teamName; // Set home team name
              homeTeamId = teamId; // Set home team ID
            } else { // If this is the away team
              awayTeam = teamName; // Set away team name
              awayTeamId = teamId; // Set away team ID
            } // End of home/away check
          } // End of competitors iteration
          
          // Get game time
          final dateString = competition['date'] as String? ?? DateTime.now().toIso8601String(); // Extract date string or default to now
          DateTime gameTime; // Declare game time variable
          try { // Begin try block for date parsing
            gameTime = DateTime.parse(dateString); // Parse date string to DateTime
          } catch (e) { // Catch date parsing errors
            print('Error parsing date for $id: $e'); // Log date parsing error
            gameTime = DateTime.now().add(const Duration(days: 1)); // Default to tomorrow
          } // End of date parsing try-catch
          
          // Get game status
          final statusData = competition['status'] as Map<String, dynamic>? ?? {}; // Extract status data or default to empty map
          final statusType = statusData['type'] as Map<String, dynamic>? ?? {}; // Extract status type or default to empty map
          final status = statusType['state'] as String? ?? 'SCHEDULED'; // Extract status state or default to SCHEDULED
          
          // Get scores for live games
          int? homeScore; // Declare optional home score
          int? awayScore; // Declare optional away score
          String? period; // Declare optional period string
          
          if (status.toUpperCase() == 'IN' || status.toUpperCase() == 'LIVE') { // Check if game is live
            try { // Begin try block for live game data parsing
              // Extract scores from competitors
              for (var team in competitors) { // Iterate through competitors to get scores
                final isHome = team['homeAway'] == 'home'; // Check if team is home team
                final score = int.tryParse(team['score'] ?? '') ?? 0; // Parse team score or default to 0
                
                if (isHome) { // Check if this is the home team
                  homeScore = score; // Set home team score
                } else { // If this is the away team
                  awayScore = score; // Set away team score
                } // End of home/away score check
              } // End of competitors iteration for scores
              
              // Try to get period/quarter/inning information
              final displayPeriod = statusData['displayPeriod'] as int? ?? 0; // Extract display period or default to 0
              final displayClock = statusData['displayClock'] as String? ?? ''; // Extract display clock or default to empty string
              
              // Convert period data to readable format based on sport
              switch (sport) { // Switch based on sport type
                case 'NBA': // Handle NBA
                case 'NCAAB': // Handle NCAAB
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : ''; // Format basketball period
                  if (displayClock.isNotEmpty) { // Check if clock is available
                    period = '$period - $displayClock'; // Add clock to period
                  } // End of clock check
                  break; // Break from switch
                  
                case 'NFL': // Handle NFL
                case 'NCAAF': // Handle NCAAF
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : ''; // Format football period
                  if (displayClock.isNotEmpty) { // Check if clock is available
                    period = '$period - $displayClock'; // Add clock to period
                  } // End of clock check
                  break; // Break from switch
                  
                case 'MLB': // Handle MLB
                  final inningHalf = statusData['period'] == 'T' ? 'Top' : 'Bottom'; // Determine inning half
                  period = displayPeriod > 0 ? '$inningHalf ${_getOrdinal(displayPeriod)}' : ''; // Format baseball period
                  if (displayClock.isNotEmpty && period.isEmpty) { // Check if clock available and no period set
                    period = displayClock; // Use clock as period
                  } // End of clock check
                  break; // Break from switch
                  
                case 'NHL': // Handle NHL
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Period' : ''; // Format hockey period
                  if (displayClock.isNotEmpty) { // Check if clock is available
                    period = '$period - $displayClock'; // Add clock to period
                  } // End of clock check
                  break; // Break from switch
                  
                case 'Soccer': // Handle Soccer
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Half' : ''; // Format soccer period
                  if (displayClock.isNotEmpty) { // Check if clock is available
                    period = '$period - $displayClock'; // Add clock to period
                  } // End of clock check
                  break; // Break from switch
                  
                default: // Handle other sports
                  if (displayClock.isNotEmpty) { // Check if clock is available
                    period = displayClock; // Use clock as period
                  } // End of clock check
              } // End of sport switch
            } catch (e) { // Catch live game data parsing errors
              print('Error parsing live game data: $e'); // Log live game data error
              // Leave scores and period as null if parsing fails
            } // End of live game data try-catch
          } // End of live game check
          
          // Get odds if available
          Map<String, dynamic>? odds; // Declare optional odds map
          final oddsData = competition['odds'] as List? ?? []; // Extract odds data or default to empty list
          
          if (oddsData.isNotEmpty) { // Check if odds data is available
            final oddDetails = oddsData[0] as Map<String, dynamic>? ?? {}; // Get first odds entry or default to empty map
            odds = _parseOddsFromESPN(oddDetails, sport); // Parse odds from ESPN format
          } // End of odds data check
          
          // Create game object
          final game = Game( // Create new Game instance
            id: id, // Set game ID
            homeTeam: homeTeam, // Set home team name
            awayTeam: awayTeam, // Set away team name
            homeTeamId: homeTeamId, // Set home team ID
            awayTeamId: awayTeamId, // Set away team ID
            gameTime: gameTime, // Set game time
            sport: sport, // Set sport
            league: _getLeagueFromSport(sport), // Set league based on sport
            status: _mapESPNStatusToApp(status), // Map ESPN status to app status
            odds: odds, // Set parsed odds
            homeScore: homeScore, // Set home team score (if live)
            awayScore: awayScore, // Set away team score (if live)
            period: period, // Set game period (if live)
          ); // End of Game constructor
          
          games.add(game); // Add parsed game to games list
        } catch (e) { // Catch individual event parsing errors
          print('Error parsing ESPN game data: $e'); // Log event parsing error
          continue; // Continue to next event on error
        } // End of event parsing try-catch
      } // End of events iteration
    } catch (e) { // Catch overall parsing errors
      print('Error parsing ESPN games response: $e'); // Log overall parsing error
    } // End of overall parsing try-catch
    
    print('Parsed ${games.length} games for $sport from scoreboard API'); // Log number of games parsed
    return games; // Return list of parsed games
  } // End of _parseESPNGames method

  /// Parse odds data from ESPN format
  Map<String, dynamic>? _parseOddsFromESPN(Map<String, dynamic> oddsData, String sport) { // Define method to parse odds from ESPN format
    try { // Begin try block for odds parsing error handling
      final result = <String, dynamic>{}; // Initialize result map for parsed odds
      
      // Parse spread
      final spread = oddsData['spread'] as double? ?? 0; // Extract spread value or default to 0
      result['spread'] = { // Set spread odds in result
        'home': -spread, // Home team gets negative spread
        'away': spread, // Away team gets positive spread
      }; // End of spread odds
      
      // Parse over/under
      final overUnder = oddsData['overUnder'] as double? ?? 0; // Extract over/under value or default to 0
      result['total'] = overUnder; // Set total in result
      
      // Set default moneyline (ESPN doesn't always provide this)
      result['moneyline'] = { // Set default moneyline odds
        'home': -110, // Default home moneyline
        'away': -110, // Default away moneyline
      }; // End of moneyline odds
      
      // Add draw for soccer
      if (sport == 'Soccer') { // Check if sport is soccer
        result['moneyline']['draw'] = 220; // Add draw option for soccer
      } // End of soccer check
      
      return result; // Return parsed odds
    } catch (e) { // Catch odds parsing errors
      return null; // Return null on parsing error
    } // End of odds parsing try-catch
  } // End of _parseOddsFromESPN method

  /// Map ESPN status to app status
  String _mapESPNStatusToApp(String espnStatus) { // Define method to map ESPN status to app status
    switch (espnStatus.toUpperCase()) { // Switch based on uppercase ESPN status
      case 'PRE': // Handle PRE status
      case 'SCHEDULED': // Handle SCHEDULED status
        return 'scheduled'; // Return scheduled for pre-game statuses
      case 'IN': // Handle IN status
      case 'LIVE': // Handle LIVE status
        return 'live'; // Return live for in-progress statuses
      case 'POST': // Handle POST status
      case 'FINAL': // Handle FINAL status
        return 'finished'; // Return finished for completed statuses
      default: // Handle unknown statuses
        return 'scheduled'; // Default to scheduled
    } // End of status switch
  } // End of _mapESPNStatusToApp method

  /// Helper method to convert numbers to ordinals (1st, 2nd, 3rd, etc.)
  String _getOrdinal(int number) { // Define method to convert numbers to ordinal strings
    if (number <= 0) return number.toString(); // Return string representation for non-positive numbers
    
    switch (number % 10) { // Switch based on last digit
      case 1: // Handle numbers ending in 1
        if (number % 100 != 11) return '${number}st'; // Return 'st' suffix unless it's 11
        break; // Break from switch
      case 2: // Handle numbers ending in 2
        if (number % 100 != 12) return '${number}nd'; // Return 'nd' suffix unless it's 12
        break; // Break from switch
      case 3: // Handle numbers ending in 3
        if (number % 100 != 13) return '${number}rd'; // Return 'rd' suffix unless it's 13
        break; // Break from switch
    } // End of digit switch
    return '${number}th'; // Default to 'th' suffix for all other cases
  } // End of _getOrdinal method

  /// Get league name from sport
  String _getLeagueFromSport(String sport) { // Define method to get league name from sport
    switch (sport) { // Switch based on sport
      case 'NBA': // Handle NBA
      case 'NFL': // Handle NFL
      case 'MLB': // Handle MLB
      case 'NHL': // Handle NHL
      case 'NCAAB': // Handle NCAAB
      case 'NCAAF': // Handle NCAAF
        return sport; // Return sport name as league name for major sports
      case 'Soccer': // Handle Soccer
        return 'Various'; // Return 'Various' for soccer as it includes multiple leagues
      default: // Handle unknown sports
        return sport; // Default to sport name
    } // End of sport switch
  } // End of _getLeagueFromSport method
} // End of SportsApiService class
