import 'dart:convert'; // Import Dart's convert library for JSON parsing
import 'dart:math' as Math; // Import Dart's math library with alias for mathematical operations
import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import 'package:http/http.dart' as http; // Import HTTP package for making API requests
import '../models/sports/sportsbook.dart'; // Import Sportsbook model class
import '../models/sports/odds.dart'; // Import OddsData model class
import 'sports_api_service.dart'; // Import sports API service for integration

/// Manages sports betting odds data for WagerLoop.
/// 
/// Integrates with The Odds API to fetch real-time betting odds from
/// supported sportsbooks (primarily FanDuel). Handles odds caching,
/// format conversions, and provides best odds calculations for users.
/// 
/// Uses singleton pattern to ensure consistent odds data across the app.
class SportsOddsService { // Define SportsOddsService class to manage sports betting odds data
  // Singleton pattern
  static final SportsOddsService _instance = SportsOddsService._internal(); // Create static instance using private constructor
  factory SportsOddsService() => _instance; // Factory constructor that returns the singleton instance
  SportsOddsService._internal(); // Private constructor to prevent external instantiation

  // The Odds API - replace with your actual API key
  final String _baseUrl = 'api.the-odds-api.com'; // Define constant for The Odds API base URL
  String? _apiKey = 'placeholder'; // Declare optional API key field with placeholder value
  //String? _apiKey = '9413990d83982c8eb7e2f7af3deb42ab'; // Commented out actual API key

  // Cache for odds data to avoid frequent API calls
  final Map<String, Map<String, dynamic>> _oddsCache = {}; // Map to cache odds data by cache key
  DateTime? _lastFetchTime; // Optional DateTime to track when odds were last fetched
  final Duration _cacheValidity = const Duration(hours: 3); // Define cache validity duration as 3 hours

  // List of supported sportsbooks - only using FanDuel as requested
  final List<String> _supportedSportsbooks = [ // List of supported sportsbook identifiers
    'fanduel' // FanDuel sportsbook identifier
  ]; // End of supported sportsbooks list

  /// Configures the API key for The Odds API.
  /// 
  /// Must be called before fetching odds data. The API key is required
  /// to access real-time betting odds from supported sportsbooks.
  /// 
  /// Parameters:
  ///   - apiKey: Valid API key from The Odds API service
  void setApiKey(String apiKey) { // Define method to set The Odds API key
    _apiKey = apiKey; // Set the API key field to the provided value
  } // End of setApiKey method

  // Map of sports from app terminology to The Odds API terminology
  final Map<String, String> _sportMap = { // Map to convert app sport names to API sport codes
    'NBA': 'basketball_nba', // Map NBA to basketball_nba API code
    'NFL': 'americanfootball_nfl', // Map NFL to americanfootball_nfl API code
    'MLB': 'baseball_mlb', // Map MLB to baseball_mlb API code
    'NHL': 'icehockey_nhl', // Map NHL to icehockey_nhl API code
    'Soccer': 'soccer_epl', // Map Soccer to soccer_epl API code (English Premier League default)
    'NCAAB': 'basketball_ncaa', // Map NCAAB to basketball_ncaa API code
    'NCAAF': 'americanfootball_ncaa', // Map NCAAF to americanfootball_ncaa API code
  }; // End of sport map

  // Map of soccer leagues
  final Map<String, String> _soccerLeagueMap = { // Map to convert soccer league names to API codes
    'EPL': 'soccer_epl', // Map EPL to soccer_epl API code
    'La Liga': 'soccer_spain_la_liga', // Map La Liga to soccer_spain_la_liga API code
    'Bundesliga': 'soccer_germany_bundesliga', // Map Bundesliga to soccer_germany_bundesliga API code
    'Serie A': 'soccer_italy_serie_a', // Map Serie A to soccer_italy_serie_a API code
    'Ligue 1': 'soccer_france_ligue_one', // Map Ligue 1 to soccer_france_ligue_one API code
    'Champions League': 'soccer_uefa_champions_league', // Map Champions League to soccer_uefa_champions_league API code
    'MLS': 'soccer_usa_mls', // Map MLS to soccer_usa_mls API code
  }; // End of soccer league map

  /// Get all available sportsbooks
  List<Sportsbook> getAvailableSportsbooks() { // Define method to get list of available sportsbooks
    return _supportedSportsbooks.map((id) => Sportsbook( // Map each supported sportsbook ID to Sportsbook object
      id: id, // Set sportsbook ID
      name: _formatSportsbookName(id), // Set formatted sportsbook name
      isEnabled: true, // Set sportsbook as enabled
    )).toList(); // Convert mapped results to list
  } // End of getAvailableSportsbooks method

  /// Format sportsbook name for display
  String _formatSportsbookName(String id) { // Define private method to format sportsbook name for display
    switch (id) { // Switch statement based on sportsbook ID
      case 'fanduel': // Handle FanDuel case
        return 'FanDuel'; // Return properly formatted FanDuel name
      default: // Handle all other cases
        // Convert to title case
        return id.split('_').map((word) => // Split ID by underscores and map each word
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1) // Convert each word to title case
        ).join(' '); // Join words with spaces
    } // End of switch statement
  } // End of _formatSportsbookName method

  /// Converts WagerLoop sport names to The Odds API sport codes.
  /// 
  /// Maps user-friendly sport names used in the app to the specific
  /// API codes required by The Odds API service.
  /// 
  /// Parameters:
  ///   - sport: WagerLoop sport name (e.g., 'NBA', 'NFL', 'Soccer')
  /// 
  /// Returns:
  ///   String API code for the sport, or empty string if not supported
  String _getSportApiCode(String sport) { // Define private method to get API code for a sport
    if (sport == 'Soccer') { // Check if sport is Soccer
      return 'soccer_epl'; // Return EPL as default soccer league
    } // End of Soccer check
    
    return _sportMap[sport] ?? ''; // Return API code from sport map or empty string if not found
  } // End of _getSportApiCode method

  /// Fetches real-time betting odds for a specific game.
  /// 
  /// Retrieves moneyline, spread, and totals odds from supported sportsbooks
  /// for a specific game. Uses caching to minimize API calls and improve
  /// performance for frequently requested games.
  /// 
  /// Parameters:
  ///   - gameId: Unique identifier for the game
  ///   - sport: Sport type (NBA, NFL, MLB, etc.)
  ///   - sportsbooks: Optional list of specific sportsbooks to query
  /// 
  /// Returns:
  ///   Map<String, OddsData> containing odds data keyed by sportsbook name
  /// 
  /// Throws:
  ///   - Exception: If API key is missing or API request fails
  Future<Map<String, OddsData>> fetchOddsForGame(String gameId, String sport, {List<String>? sportsbooks}) async { // Define async method to fetch odds for a specific game
    if (_apiKey == null || _apiKey!.isEmpty) { // Check if API key is null or empty
      print('API key not set for SportsOddsService'); // Log missing API key error
      return {}; // Return empty map if no API key
    } // End of API key check

    final sportApiCode = _getSportApiCode(sport); // Get API code for the sport
    if (sportApiCode.isEmpty) { // Check if sport API code is empty
      return {}; // Return empty map if sport not supported
    } // End of sport code check
    
    print('Fetching odds from The Odds API for game: $gameId in sport: $sport'); // Log odds fetching attempt

    try { // Begin try block for API request error handling
      // Check cache first to avoid unnecessary API calls
      final cacheKey = '${sportApiCode}_${gameId}'; // Create cache key combining sport and game ID
      final now = DateTime.now(); // Get current time
      
      if (_oddsCache.containsKey(cacheKey) && // Check if cache contains the key
          _lastFetchTime != null && // Check if last fetch time is not null
          now.difference(_lastFetchTime!) < _cacheValidity) { // Check if cache is still valid
        print('Using cached odds data for game: $gameId'); // Log cache usage
        return _parseOddsForGame(_oddsCache[cacheKey]!, gameId, sportsbooks); // Return parsed odds from cache
      } // End of cache check

      // API endpoint parameters
      final queryParams = { // Map of query parameters for API request
        'apiKey': _apiKey!, // API key parameter (non-null assertion)
        'regions': 'us', // Regions parameter set to US
        'markets': 'h2h,spreads,totals', // Markets parameter for head-to-head, spreads, and totals
        'oddsFormat': 'american', // Odds format parameter set to American
        'dateFormat': 'iso', // Date format parameter set to ISO
        'bookmakers': 'fanduel', // Bookmakers parameter set to FanDuel only
      }; // End of query parameters
      
      print('The Odds API query params: $queryParams'); // Log query parameters

      // Construct API URL
      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams); // Construct HTTPS URI for API request
      
      print('Making API call to The Odds API: $uri'); // Log API call URL
      final response = await http.get(uri); // Make HTTP GET request to API
      
      if (response.statusCode == 200) { // Check if response status is OK
        print('The Odds API response received with status 200'); // Log successful response
        final List<dynamic> data = json.decode(response.body); // Decode JSON response body
        print('Received ${data.length} games from The Odds API'); // Log number of games received
        
        // Cache the response
        _oddsCache[cacheKey] = data; // Store response data in cache
        _lastFetchTime = now; // Update last fetch time
        
        return _parseOddsForGame(data, gameId, sportsbooks); // Parse and return odds for the specific game
      } else { // Handle non-200 response status
        print('Error fetching odds: ${response.statusCode}'); // Log error status code
        return {}; // Return empty map on error
      } // End of response status check
    } catch (e) { // Catch any exceptions during API request
      print('Error in fetchOddsForGame: $e'); // Log the exception
      return {}; // Return empty map on exception
    } // End of try-catch block
  } // End of fetchOddsForGame method

  /// Fetches odds for all games in a specific sport.
  /// 
  /// Retrieves comprehensive odds data for all available games in a sport,
  /// useful for displaying odds across multiple games or for analysis.
  /// 
  /// Parameters:
  ///   - sport: Sport type to fetch odds for
  /// 
  /// Returns:
  ///   Map<String, Map<String, OddsData>> nested map with game IDs as keys
  ///   and sportsbook odds as values
  /// 
  /// Throws:
  ///   - Exception: If API key is missing or API request fails
  Future<Map<String, Map<String, OddsData>>> fetchOddsForSport(String sport) async { // Define async method to fetch odds for all games in a sport
    if (_apiKey == null || _apiKey!.isEmpty) { // Check if API key is null or empty
      print('API key not set for SportsOddsService'); // Log missing API key error
      return {}; // Return empty map if no API key
    } // End of API key check

    final sportApiCode = _getSportApiCode(sport); // Get API code for the sport
    if (sportApiCode.isEmpty) { // Check if sport API code is empty
      return {}; // Return empty map if sport not supported
    } // End of sport code check

    try { // Begin try block for API request error handling
      final Map<String, Map<String, OddsData>> result = {}; // Initialize result map for game odds
      
      final queryParams = { // Map of query parameters for API request
        'apiKey': _apiKey!, // API key parameter (non-null assertion)
        'regions': 'us', // Regions parameter set to US
        'markets': 'h2h,spreads,totals', // Markets parameter for head-to-head, spreads, and totals
        'oddsFormat': 'american', // Odds format parameter set to American
        'dateFormat': 'iso', // Date format parameter set to ISO
        'bookmakers': 'fanduel', // Bookmakers parameter set to FanDuel only
      }; // End of query parameters
      
      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams); // Construct HTTPS URI for API request
      final response = await http.get(uri); // Make HTTP GET request to API
      
      if (response.statusCode == 200) { // Check if response status is OK
        final List<dynamic> oddsData = json.decode(response.body); // Decode JSON response body
        
        for (var gameData in oddsData) { // Iterate through each game in the odds data
          final gameId = gameData['id'] as String? ?? ''; // Extract game ID or default to empty string
          final odds = _parseOddsForGame(gameData, gameId, null); // Parse odds for the current game
          
          _oddsCache['${sportApiCode}_$gameId'] = gameData; // Cache the game data
          
          if (odds.isNotEmpty) { // Check if odds data is not empty
            result[gameId] = odds; // Add odds to result map with game ID as key
          } // End of odds check
        } // End of game data iteration
        
        _lastFetchTime = DateTime.now(); // Update last fetch time
        return result; // Return the result map
      } else { // Handle non-200 response status
        print('The Odds API request failed: Status: ${response.statusCode}'); // Log API request failure
      } // End of response status check
      
      return {}; // Return empty map if request failed
    } catch (e) { // Catch any exceptions during API request
      print('Error fetching odds for sport: $e'); // Log the exception
      return {}; // Return empty map on exception
    } // End of try-catch block
  } // End of fetchOddsForSport method

  /// Set specific soccer league
  void setSoccerLeague(String league) { // Define method to set specific soccer league
    if (_soccerLeagueMap.containsKey(league)) { // Check if league exists in soccer league map
      _sportMap['Soccer'] = _soccerLeagueMap[league]!; // Update soccer sport mapping to specific league (non-null assertion)
    } // End of league check
  } // End of setSoccerLeague method

  /// Parse odds data for a specific game
  Map<String, OddsData> _parseOddsForGame(Map<String, dynamic> gameData, String gameId, List<String>? sportsbooks) { // Define private method to parse odds data for a specific game
    print('Parsing odds data for game'); // Log odds parsing start
    
    try { // Begin try block for parsing error handling
      final Map<String, OddsData> result = {}; // Initialize result map for sportsbook odds
      
      final List<dynamic> bookmakers = gameData['bookmakers'] ?? []; // Extract bookmakers list or default to empty list
      if (bookmakers.isEmpty) { // Check if bookmakers list is empty
        return {}; // Return empty map if no bookmakers
      } // End of bookmakers check
      
      for (var bookmaker in bookmakers) { // Iterate through each bookmaker
        final String bookmakerKey = bookmaker['key'] as String? ?? ''; // Extract bookmaker key or default to empty string
        
        if (sportsbooks != null && !sportsbooks.contains(bookmakerKey)) { // Check if specific sportsbooks filter is applied and current bookmaker is not included
          continue; // Skip this bookmaker if not in the filter list
        } // End of sportsbooks filter check
        
        if (!bookmaker.containsKey('markets')) { // Check if bookmaker data contains markets
          continue; // Skip bookmaker if no markets data
        } // End of markets check
        
        final String bookmakerName = _formatSportsbookName(bookmakerKey); // Format bookmaker name for display
        final List<dynamic> markets = bookmaker['markets'] ?? []; // Extract markets list or default to empty list
        
        if (markets.isEmpty) { // Check if markets list is empty
          continue; // Skip bookmaker if no markets
        } // End of markets empty check
        
        Map<String, dynamic> moneylineOdds = {}; // Initialize map for moneyline odds
        Map<String, dynamic> spreadOdds = {}; // Initialize map for spread odds
        Map<String, dynamic> totalOdds = {}; // Initialize map for total odds
        
        for (var market in markets) { // Iterate through each market
          final String marketKey = market['key'] as String? ?? ''; // Extract market key or default to empty string
          final List<dynamic> outcomes = market['outcomes'] ?? []; // Extract outcomes list or default to empty list
          
          if (marketKey == 'h2h') { // Check if market is head-to-head (moneyline)
            _processMoneylineOutcomes(outcomes, moneylineOdds); // Process moneyline outcomes
          } else if (marketKey == 'spreads') { // Check if market is spreads
            _processSpreadOutcomes(outcomes, spreadOdds); // Process spread outcomes
          } else if (marketKey == 'totals') { // Check if market is totals
            _processTotalOutcomes(outcomes, totalOdds); // Process total outcomes
          } // End of market type checks
        } // End of markets iteration
        
        final oddsData = OddsData( // Create OddsData object
          sportsbook: Sportsbook( // Create Sportsbook object
            id: bookmakerKey, // Set sportsbook ID
            name: bookmakerName, // Set sportsbook name
            isEnabled: true, // Set sportsbook as enabled
          ), // End of Sportsbook object
          moneyline: moneylineOdds.isNotEmpty ? moneylineOdds : null, // Set moneyline odds if not empty, otherwise null
          spread: spreadOdds.isNotEmpty ? spreadOdds : null, // Set spread odds if not empty, otherwise null
          total: totalOdds.isNotEmpty ? totalOdds : null, // Set total odds if not empty, otherwise null
          lastUpdated: bookmaker.containsKey('last_update') ? // Check if bookmaker has last_update field
                       DateTime.parse(bookmaker['last_update']) : // Parse last update time if available
                       DateTime.now(), // Use current time if last update not available
        ); // End of OddsData object
        
        result[bookmakerKey] = oddsData; // Add odds data to result map with bookmaker key
      } // End of bookmakers iteration
      
      return result; // Return the result map
    } catch (e) { // Catch any parsing exceptions
      print('Error parsing odds data: $e'); // Log parsing error
      return {}; // Return empty map on parsing error
    } // End of parsing try-catch
  } // End of _parseOddsForGame method
  
  void _processMoneylineOutcomes(List<dynamic> outcomes, Map<String, dynamic> moneylineOdds) { // Define private method to process moneyline outcomes
    for (var outcome in outcomes) { // Iterate through each outcome
      final String name = outcome['name'] as String? ?? ''; // Extract outcome name or default to empty string
      final int price = outcome['price'] as int? ?? 0; // Extract outcome price or default to 0
      
      if (name.toLowerCase() == 'home') { // Check if outcome is for home team
        moneylineOdds['home'] = price; // Set home team moneyline odds
      } else if (name.toLowerCase() == 'away') { // Check if outcome is for away team
        moneylineOdds['away'] = price; // Set away team moneyline odds
      } else if (name.toLowerCase() == 'draw') { // Check if outcome is for draw
        moneylineOdds['draw'] = price; // Set draw moneyline odds
      } // End of outcome name checks
    } // End of outcomes iteration
  } // End of _processMoneylineOutcomes method
  
  void _processSpreadOutcomes(List<dynamic> outcomes, Map<String, dynamic> spreadOdds) { // Define private method to process spread outcomes
    for (var outcome in outcomes) { // Iterate through each outcome
      final String name = outcome['name'] as String? ?? ''; // Extract outcome name or default to empty string
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0; // Extract point spread value or default to 0.0
      final int price = outcome['price'] as int? ?? 0; // Extract outcome price or default to 0
      
      if (name.toLowerCase() == 'home') { // Check if outcome is for home team
        spreadOdds['home'] = {'point': point, 'price': price}; // Set home team spread odds with point and price
      } else if (name.toLowerCase() == 'away') { // Check if outcome is for away team
        spreadOdds['away'] = {'point': point, 'price': price}; // Set away team spread odds with point and price
      } // End of outcome name checks
    } // End of outcomes iteration
  } // End of _processSpreadOutcomes method
  
  void _processTotalOutcomes(List<dynamic> outcomes, Map<String, dynamic> totalOdds) { // Define private method to process total outcomes
    for (var outcome in outcomes) { // Iterate through each outcome
      final String name = (outcome['name'] as String? ?? '').toLowerCase(); // Extract and convert outcome name to lowercase or default to empty string
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0; // Extract total points value or default to 0.0
      final int price = outcome['price'] as int? ?? 0; // Extract outcome price or default to 0
      
      if (name == 'over') { // Check if outcome is for over
        totalOdds['over'] = {'point': point, 'price': price}; // Set over total odds with point and price
      } else if (name == 'under') { // Check if outcome is for under
        totalOdds['under'] = {'point': point, 'price': price}; // Set under total odds with point and price
      } // End of outcome name checks
    } // End of outcomes iteration
  } // End of _processTotalOutcomes method

  /// Finds the best available odds for a specific bet type and side.
  /// 
  /// Compares odds across all supported sportsbooks to find the most
  /// favorable odds for a user's bet selection. Essential for maximizing
  /// potential winnings in WagerLoop.
  /// 
  /// Parameters:
  ///   - gameId: Unique identifier for the game
  ///   - sport: Sport type
  ///   - betType: Type of bet (moneyline, spread, totals)
  ///   - betSide: Side of the bet (home, away, over, under)
  /// 
  /// Returns:
  ///   OddsData? containing the best odds found, or null if none available
  /// 
  /// Throws:
  ///   - Exception: If API request fails or odds cannot be compared
  Future<OddsData?> getBestOddsForGame(String gameId, String sport, String betType, String betSide) async { // Define async method to get best odds for a game
    try { // Begin try block for best odds error handling
      final allOdds = await fetchOddsForGame(gameId, sport); // Fetch all odds for the game
      
      if (allOdds.isEmpty) { // Check if all odds map is empty
        return null; // Return null if no odds available
      } // End of odds check
      
      OddsData? bestOdds; // Declare variable to store best odds
      int bestPrice = -10000; // Initialize best price with very low value
      
      for (var oddsData in allOdds.values) { // Iterate through each odds data
        int currentPrice = -10000; // Initialize current price with very low value
        
        switch (betType.toLowerCase()) { // Switch based on bet type (converted to lowercase)
          case 'moneyline': // Handle moneyline bet type
            if (oddsData.moneyline != null && oddsData.moneyline!.containsKey(betSide)) { // Check if moneyline data exists and contains bet side
              currentPrice = oddsData.moneyline![betSide] as int; // Get current price from moneyline data
            } // End of moneyline check
            break; // Break from switch
            
          case 'spread': // Handle spread bet type
            if (oddsData.spread != null && oddsData.spread!.containsKey(betSide)) { // Check if spread data exists and contains bet side
              currentPrice = oddsData.spread![betSide]['price'] as int; // Get current price from spread data
            } // End of spread check
            break; // Break from switch
            
          case 'total': // Handle total bet type
            if (oddsData.total != null && oddsData.total!.containsKey(betSide)) { // Check if total data exists and contains bet side
              currentPrice = oddsData.total![betSide]['price'] as int; // Get current price from total data
            } // End of total check
            break; // Break from switch
        } // End of bet type switch
        
        if (currentPrice > bestPrice) { // Check if current price is better than best price
          bestPrice = currentPrice; // Update best price
          bestOdds = oddsData; // Update best odds data
        } // End of price comparison
      } // End of odds iteration
      
      return bestOdds; // Return the best odds found
    } catch (e) { // Catch any exceptions during best odds calculation
      print('Error getting best odds: $e'); // Log the exception
      return null; // Return null on exception
    } // End of best odds try-catch
  } // End of getBestOddsForGame method

  /// Compare odds across sportsbooks
  Map<String, dynamic> compareOddsAcrossSportsbooks(Map<String, OddsData> odds, String betType, String betSide) { // Define method to compare odds across sportsbooks
    if (odds.isEmpty) { // Check if odds map is empty
      return {}; // Return empty map if no odds to compare
    } // End of odds check
    
    final Map<String, dynamic> result = { // Initialize result map for comparison
      'best': null, // Field for best odds
      'worst': null, // Field for worst odds
      'average': 0, // Field for average odds
      'difference': 0, // Field for difference between best and worst
      'all': <String, dynamic>{}, // Field for all odds data
    }; // End of result map
    
    return result; // Return the result map (currently empty implementation)
  } // End of compareOddsAcrossSportsbooks method
} // End of SportsOddsService class
