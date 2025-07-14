// Import Dart convert library for JSON operations
import 'dart:convert';
// Import Dart math library for mathematical operations
import 'dart:math' as Math;
// Import Flutter material library for widgets
import 'package:flutter/material.dart';
// Import HTTP library for API requests
import 'package:http/http.dart' as http;
// Import Sportsbook model for sportsbook data
import '../models/sports/sportsbook.dart';
// Import Odds model for betting odds
import '../models/sports/odds.dart';
// Import sports API service for game data
import 'sports_api_service.dart';

/// Manages sports betting odds data for WagerLoop.
/// 
/// Integrates with The Odds API to fetch real-time betting odds from
/// supported sportsbooks (primarily FanDuel). Handles odds caching,
/// format conversions, and provides best odds calculations for users.
/// 
/// Uses singleton pattern to ensure consistent odds data across the app.
class SportsOddsService {
  // Singleton pattern implementation
  static final SportsOddsService _instance = SportsOddsService._internal();
  // Factory constructor that returns the singleton instance
  factory SportsOddsService() => _instance;
  // Private internal constructor for singleton pattern
  SportsOddsService._internal();

  // The Odds API base URL
  final String _baseUrl = 'api.the-odds-api.com';
  // API key for The Odds API (placeholder)
  String? _apiKey = 'placeholder';
  //String? _apiKey = '9413990d83982c8eb7e2f7af3deb42ab';

  // Cache for odds data to avoid frequent API calls
  final Map<String, List<dynamic>> _oddsCache = {};
  // Timestamp of last fetch for cache validation
  DateTime? _lastFetchTime;
  // Cache validity period (3 hours)
  final Duration _cacheValidity = const Duration(hours: 3);

  // List of supported sportsbooks - only using FanDuel as requested
  final List<String> _supportedSportsbooks = [
    'fanduel'
  ];

  /// Configures the API key for The Odds API.
  /// 
  /// Must be called before fetching odds data. The API key is required
  /// to access real-time betting odds from supported sportsbooks.
  /// 
  /// Parameters:
  ///   - apiKey: Valid API key from The Odds API service
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  // Map of sports from app terminology to The Odds API terminology
  final Map<String, String> _sportMap = {
    'NBA': 'basketball_nba',
    'NFL': 'americanfootball_nfl',
    'MLB': 'baseball_mlb',
    'NHL': 'icehockey_nhl',
    'Soccer': 'soccer_epl',
    'NCAAB': 'basketball_ncaa',
    'NCAAF': 'americanfootball_ncaa',
  };

  // Map of soccer leagues for different competitions
  final Map<String, String> _soccerLeagueMap = {
    'EPL': 'soccer_epl',
    'La Liga': 'soccer_spain_la_liga',
    'Bundesliga': 'soccer_germany_bundesliga',
    'Serie A': 'soccer_italy_serie_a',
    'Ligue 1': 'soccer_france_ligue_one',
    'Champions League': 'soccer_uefa_champions_league',
    'MLS': 'soccer_usa_mls',
  };

  /// Get all available sportsbooks
  List<Sportsbook> getAvailableSportsbooks() {
    // Map sportsbook IDs to Sportsbook objects
    return _supportedSportsbooks.map((id) => Sportsbook(
      id: id,
      name: _formatSportsbookName(id),
      isEnabled: true,
    )).toList();
  }

  /// Format sportsbook name for display
  String _formatSportsbookName(String id) {
    // Handle specific sportsbook names
    switch (id) {
      case 'fanduel':
        return 'FanDuel';
      default:
        // Convert to title case for generic formatting
        return id.split('_').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

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
  String _getSportApiCode(String sport) {
    // Handle soccer specifically
    if (sport == 'Soccer') {
      return 'soccer_epl';
    }
    
    // Return mapped sport code or empty string
    return _sportMap[sport] ?? '';
  }

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
  Future<Map<String, OddsData>> fetchOddsForGame(String gameId, String sport, {List<String>? sportsbooks}) async {
    // Check if API key is set
    if (_apiKey == null || _apiKey!.isEmpty) {
      // Print error if API key is missing
      print('API key not set for SportsOddsService');
      return {};
    }

    // Get sport API code
    final sportApiCode = _getSportApiCode(sport);
    // Return empty map if sport not supported
    if (sportApiCode.isEmpty) {
      return {};
    }
    
    // Print debug message with game ID and sport
    print('Fetching odds from The Odds API for game: $gameId in sport: $sport');

    try {
      // Check cache first to avoid unnecessary API calls
      final cacheKey = '${sportApiCode}_${gameId}';
      final now = DateTime.now();
      
      // Check if cached data is valid
      if (_oddsCache.containsKey(cacheKey) && 
          _lastFetchTime != null && 
          now.difference(_lastFetchTime!) < _cacheValidity) {
        // Print debug message for cache usage
        print('Using cached odds data for game: $gameId');
        // Get cached games list
        final gamesList = _oddsCache[cacheKey]!;
        // Find specific game in cached data
        final gameData = gamesList.firstWhere(
          (game) => game['id'] == gameId,
          orElse: () => null,
        );
        // Return parsed odds if game found
        if (gameData != null) {
          return _parseOddsForGame(gameData, gameId, sportsbooks);
        }
      }

      // API endpoint parameters
      final queryParams = {
        'apiKey': _apiKey!,
        'regions': 'us',
        'markets': 'h2h,spreads,totals',
        'oddsFormat': 'american',
        'dateFormat': 'iso',
        'bookmakers': 'fanduel',
      };
      
      // Print debug message with query parameters
      print('The Odds API query params: $queryParams');

      // Construct API URL
      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams);
      
      // Print debug message with API URL
      print('Making API call to The Odds API: $uri');
      // Make HTTP GET request
      final response = await http.get(uri);
      
      // Check if request was successful
      if (response.statusCode == 200) {
        // Print debug message for successful response
        print('The Odds API response received with status 200');
        // Parse JSON response
        final List<dynamic> data = json.decode(response.body);
        // Print debug message with game count
        print('Received ${data.length} games from The Odds API');
        
        // Cache the response
        _oddsCache[cacheKey] = data;
        _lastFetchTime = now;
        
        // Find the specific game from the list
        final gameData = data.firstWhere(
          (game) => game['id'] == gameId,
          orElse: () => null,
        );
        
        // Return parsed odds if game found
        if (gameData != null) {
          return _parseOddsForGame(gameData, gameId, sportsbooks);
        } else {
          // Print error if game not found
          print('Game with ID $gameId not found in API response');
          return {};
        }
      } else {
        // Print error if request failed
        print('Error fetching odds: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      // Print error if fetch fails
      print('Error in fetchOddsForGame: $e');
      return {};
    }
  }

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
  Future<Map<String, Map<String, OddsData>>> fetchOddsForSport(String sport) async {
    // Check if API key is set
    if (_apiKey == null || _apiKey!.isEmpty) {
      // Print error if API key is missing
      print('API key not set for SportsOddsService');
      return {};
    }

    // Get sport API code
    final sportApiCode = _getSportApiCode(sport);
    // Return empty map if sport not supported
    if (sportApiCode.isEmpty) {
      return {};
    }

    try {
      // Initialize result map
      final Map<String, Map<String, OddsData>> result = {};
      
      // API endpoint parameters
      final queryParams = {
        'apiKey': _apiKey!,
        'regions': 'us',
        'markets': 'h2h,spreads,totals',
        'oddsFormat': 'american',
        'dateFormat': 'iso',
        'bookmakers': 'fanduel',
      };
      
      // Construct API URL
      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams);
      // Make HTTP GET request
      final response = await http.get(uri);
      
      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final List<dynamic> oddsData = json.decode(response.body);
        
        // Cache the entire list of games for this sport
        _oddsCache[sportApiCode] = oddsData;
        _lastFetchTime = DateTime.now();
        
        // Process each game in the response
        for (var gameData in oddsData) {
          // Extract game ID
          final gameId = gameData['id'] as String? ?? '';
          // Parse odds for this game
          final odds = _parseOddsForGame(gameData, gameId, null);
          
          // Add to result if odds are available
          if (odds.isNotEmpty) {
            result[gameId] = odds;
          }
        }
        
        // Return the result map
        return result;
      } else {
        // Print error if request failed
        print('The Odds API request failed: Status: ${response.statusCode}');
      }
      
      // Return empty map on error
      return {};
    } catch (e) {
      // Print error if fetch fails
      print('Error fetching odds for sport: $e');
      return {};
    }
  }

  /// Set specific soccer league
  void setSoccerLeague(String league) {
    // Update soccer mapping if league is supported
    if (_soccerLeagueMap.containsKey(league)) {
      _sportMap['Soccer'] = _soccerLeagueMap[league]!;
    }
  }

  /// Parse odds data for a specific game
  Map<String, OddsData> _parseOddsForGame(Map<String, dynamic> gameData, String gameId, List<String>? sportsbooks) {
    // Print debug message for parsing
    print('Parsing odds data for game');
    
    try {
      // Initialize result map
      final Map<String, OddsData> result = {};
      
      // Extract bookmakers from game data
      final List<dynamic> bookmakers = gameData['bookmakers'] ?? [];
      // Return empty map if no bookmakers
      if (bookmakers.isEmpty) {
        return {};
      }
      
      // Process each bookmaker
      for (var bookmaker in bookmakers) {
        // Extract bookmaker key
        final String bookmakerKey = bookmaker['key'] as String? ?? '';
        
        // Skip if sportsbooks filter is specified and bookmaker not included
        if (sportsbooks != null && !sportsbooks.contains(bookmakerKey)) {
          continue;
        }
        
        // Skip if bookmaker has no markets
        if (!bookmaker.containsKey('markets')) {
          continue;
        }
        
        // Format bookmaker name for display
        final String bookmakerName = _formatSportsbookName(bookmakerKey);
        // Extract markets from bookmaker
        final List<dynamic> markets = bookmaker['markets'] ?? [];
        
        // Skip if no markets available
        if (markets.isEmpty) {
          continue;
        }
        
        // Initialize odds maps for different bet types
        Map<String, dynamic> moneylineOdds = {};
        Map<String, dynamic> spreadOdds = {};
        Map<String, dynamic> totalOdds = {};
        
        // Process each market
        for (var market in markets) {
          // Extract market key
          final String marketKey = market['key'] as String? ?? '';
          // Extract outcomes from market
          final List<dynamic> outcomes = market['outcomes'] ?? [];
          
          // Process different market types
          if (marketKey == 'h2h') {
            // Process moneyline outcomes
            _processMoneylineOutcomes(outcomes, moneylineOdds);
          } else if (marketKey == 'spreads') {
            // Process spread outcomes
            _processSpreadOutcomes(outcomes, spreadOdds);
          } else if (marketKey == 'totals') {
            // Process total outcomes
            _processTotalOutcomes(outcomes, totalOdds);
          }
        }
        
        // Create OddsData object with parsed odds
        final oddsData = OddsData(
          sportsbook: Sportsbook(
            id: bookmakerKey,
            name: bookmakerName,
            isEnabled: true,
          ),
          moneyline: moneylineOdds.isNotEmpty ? moneylineOdds : null,
          spread: spreadOdds.isNotEmpty ? spreadOdds : null,
          total: totalOdds.isNotEmpty ? totalOdds : null,
          lastUpdated: bookmaker.containsKey('last_update') ? 
                       DateTime.parse(bookmaker['last_update']) : 
                       DateTime.now(),
        );
        
        // Add to result map
        result[bookmakerKey] = oddsData;
      }
      
      // Return parsed odds
      return result;
    } catch (e) {
      // Print error if parsing fails
      print('Error parsing odds data: $e');
      return {};
    }
  }
  
  // Process moneyline outcomes from API response
  void _processMoneylineOutcomes(List<dynamic> outcomes, Map<String, dynamic> moneylineOdds) {
    // Loop through each outcome
    for (var outcome in outcomes) {
      // Extract outcome name
      final String name = outcome['name'] as String? ?? '';
      // Extract price (odds)
      final int price = outcome['price'] as int? ?? 0;
      
      // Map outcome names to odds keys
      if (name.toLowerCase() == 'home') {
        moneylineOdds['home'] = price;
      } else if (name.toLowerCase() == 'away') {
        moneylineOdds['away'] = price;
      } else if (name.toLowerCase() == 'draw') {
        moneylineOdds['draw'] = price;
      }
    }
  }
  
  // Process spread outcomes from API response
  void _processSpreadOutcomes(List<dynamic> outcomes, Map<String, dynamic> spreadOdds) {
    // Loop through each outcome
    for (var outcome in outcomes) {
      // Extract outcome name
      final String name = outcome['name'] as String? ?? '';
      // Extract point spread
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0;
      // Extract price (odds)
      final int price = outcome['price'] as int? ?? 0;
      
      // Map outcome names to odds keys
      if (name.toLowerCase() == 'home') {
        spreadOdds['home'] = {'point': point, 'price': price};
      } else if (name.toLowerCase() == 'away') {
        spreadOdds['away'] = {'point': point, 'price': price};
      }
    }
  }
  
  // Process total outcomes from API response
  void _processTotalOutcomes(List<dynamic> outcomes, Map<String, dynamic> totalOdds) {
    // Loop through each outcome
    for (var outcome in outcomes) {
      // Extract outcome name and convert to lowercase
      final String name = (outcome['name'] as String? ?? '').toLowerCase();
      // Extract point total
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0;
      // Extract price (odds)
      final int price = outcome['price'] as int? ?? 0;
      
      // Map outcome names to odds keys
      if (name == 'over') {
        totalOdds['over'] = {'point': point, 'price': price};
      } else if (name == 'under') {
        totalOdds['under'] = {'point': point, 'price': price};
      }
    }
  }

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
  Future<OddsData?> getBestOddsForGame(String gameId, String sport, String betType, String betSide) async {
    try {
      // Fetch all odds for the game
      final allOdds = await fetchOddsForGame(gameId, sport);
      
      // Return null if no odds available
      if (allOdds.isEmpty) {
        return null;
      }
      
      // Initialize variables for finding best odds
      OddsData? bestOdds;
      int bestPrice = -10000;
      
      // Loop through all odds data
      for (var oddsData in allOdds.values) {
        int currentPrice = -10000;
        
        // Get price based on bet type
        switch (betType.toLowerCase()) {
          case 'moneyline':
            // Get moneyline price for bet side
            if (oddsData.moneyline != null && oddsData.moneyline!.containsKey(betSide)) {
              currentPrice = oddsData.moneyline![betSide] as int;
            }
            break;
            
          case 'spread':
            // Get spread price for bet side
            if (oddsData.spread != null && oddsData.spread!.containsKey(betSide)) {
              currentPrice = oddsData.spread![betSide]['price'] as int;
            }
            break;
            
          case 'total':
            // Get total price for bet side
            if (oddsData.total != null && oddsData.total!.containsKey(betSide)) {
              currentPrice = oddsData.total![betSide]['price'] as int;
            }
            break;
        }
        
        // Update best odds if current price is better
        if (currentPrice > bestPrice) {
          bestPrice = currentPrice;
          bestOdds = oddsData;
        }
      }
      
      // Return best odds found
      return bestOdds;
    } catch (e) {
      // Print error if getting best odds fails
      print('Error getting best odds: $e');
      return null;
    }
  }

  /// Compare odds across sportsbooks
  Map<String, dynamic> compareOddsAcrossSportsbooks(Map<String, OddsData> odds, String betType, String betSide) {
    // Return empty map if no odds available
    if (odds.isEmpty) {
      return {};
    }
    
    // Initialize result map with comparison structure
    final Map<String, dynamic> result = {
      'best': null,
      'worst': null,
      'average': 0,
      'difference': 0,
      'all': <String, dynamic>{},
    };
    
    // Return result (implementation incomplete)
    return result;
  }
}
