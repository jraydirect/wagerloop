import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sports/sportsbook.dart';
import '../models/sports/odds.dart';
import 'sports_api_service.dart';

class SportsOddsService {
  // Singleton pattern
  static final SportsOddsService _instance = SportsOddsService._internal();
  factory SportsOddsService() => _instance;
  SportsOddsService._internal();

  // The Odds API - replace with your actual API key
  final String _baseUrl = 'api.the-odds-api.com';
  String? _apiKey = 'placeholder';
  //String? _apiKey = '9413990d83982c8eb7e2f7af3deb42ab';

  // Cache for odds data to avoid frequent API calls
  final Map<String, Map<String, dynamic>> _oddsCache = {};
  DateTime? _lastFetchTime;
  final Duration _cacheValidity = const Duration(hours: 3);

  // List of supported sportsbooks - only using FanDuel as requested
  final List<String> _supportedSportsbooks = [
    'fanduel'
  ];

  // Set API key
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

  // Map of soccer leagues
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
    return _supportedSportsbooks.map((id) => Sportsbook(
      id: id,
      name: _formatSportsbookName(id),
      isEnabled: true,
    )).toList();
  }

  /// Format sportsbook name for display
  String _formatSportsbookName(String id) {
    switch (id) {
      case 'fanduel':
        return 'FanDuel';
      default:
        // Convert to title case
        return id.split('_').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  /// Convert API sport code back to app sport name
  String _getAppSportFromApiCode(String apiCode) {
    for (final entry in _sportMap.entries) {
      if (entry.value == apiCode) {
        return entry.key;
      }
    }
    return '';
  }

  /// Fetch odds for a specific game
  Future<Map<String, OddsData>> fetchOddsForGame(String gameId, String sport, {List<String>? sportsbooks}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('API key not set for SportsOddsService');
      return {};
    }

    final sportApiCode = _getSportApiCode(sport);
    if (sportApiCode.isEmpty) {
      return {};
    }
    
    print('Fetching odds from The Odds API for game: $gameId in sport: $sport');

    try {
      // Check cache first
      final cacheKey = '${sportApiCode}_${gameId}';
      final now = DateTime.now();
      
      if (_oddsCache.containsKey(cacheKey) && 
          _lastFetchTime != null && 
          now.difference(_lastFetchTime!) < _cacheValidity) {
        print('Using cached odds data for game: $gameId');
        return _parseOddsForGame(_oddsCache[cacheKey]!, gameId, sportsbooks);
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
      
      print('The Odds API query params: $queryParams');

      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams);
      
      print('Making API call to The Odds API: $uri');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        print('The Odds API response received with status 200');
        final List<dynamic> oddsData = json.decode(response.body);
        print('Received ${oddsData.length} games from The Odds API');
        
        // Find the game in the odds data that best matches our teams
        Map<String, dynamic>? matchedGame;
        for (var game in oddsData) {
          if (game['id'] == gameId) {
            print('Found exact ID match in API response');
            matchedGame = game;
            break;
          }
        }
        
        if (matchedGame != null) {
          final matchedId = matchedGame['id'] as String? ?? gameId;
          _oddsCache['${sportApiCode}_$matchedId'] = matchedGame;
          _lastFetchTime = now;
          print('Cached odds data for matched game: $matchedId');
          
          return _parseOddsForGame(matchedGame, gameId, sportsbooks);
        } else {
          print('No matching game found in The Odds API response');
        }
      } else {
        print('The Odds API request failed: Status: ${response.statusCode}');
      }
      
      return {};
    } catch (e) {
      print('Error fetching odds: $e');
      return {};
    }
  }

  /// Fetch odds for all upcoming games in a sport
  Future<Map<String, Map<String, OddsData>>> fetchOddsForSport(String sport) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('API key not set for SportsOddsService');
      return {};
    }

    final sportApiCode = _getSportApiCode(sport);
    if (sportApiCode.isEmpty) {
      return {};
    }

    try {
      final Map<String, Map<String, OddsData>> result = {};
      
      final queryParams = {
        'apiKey': _apiKey!,
        'regions': 'us',
        'markets': 'h2h,spreads,totals',
        'oddsFormat': 'american',
        'dateFormat': 'iso',
        'bookmakers': 'fanduel',
      };
      
      final uri = Uri.https(_baseUrl, '/v4/sports/$sportApiCode/odds', queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> oddsData = json.decode(response.body);
        
        for (var gameData in oddsData) {
          final gameId = gameData['id'] as String? ?? '';
          final odds = _parseOddsForGame(gameData, gameId, null);
          
          _oddsCache['${sportApiCode}_$gameId'] = gameData;
          
          if (odds.isNotEmpty) {
            result[gameId] = odds;
          }
        }
        
        _lastFetchTime = DateTime.now();
        return result;
      } else {
        print('The Odds API request failed: Status: ${response.statusCode}');
      }
      
      return {};
    } catch (e) {
      print('Error fetching odds for sport: $e');
      return {};
    }
  }

  /// Convert sport name to API code
  String _getSportApiCode(String sport) {
    if (sport == 'Soccer') {
      return 'soccer_epl';
    }
    
    return _sportMap[sport] ?? '';
  }

  /// Set specific soccer league
  void setSoccerLeague(String league) {
    if (_soccerLeagueMap.containsKey(league)) {
      _sportMap['Soccer'] = _soccerLeagueMap[league]!;
    }
  }

  /// Parse odds data for a specific game
  Map<String, OddsData> _parseOddsForGame(Map<String, dynamic> gameData, String gameId, List<String>? sportsbooks) {
    print('Parsing odds data for game');
    
    try {
      final Map<String, OddsData> result = {};
      
      final List<dynamic> bookmakers = gameData['bookmakers'] ?? [];
      if (bookmakers.isEmpty) {
        return {};
      }
      
      for (var bookmaker in bookmakers) {
        final String bookmakerKey = bookmaker['key'] as String? ?? '';
        
        if (sportsbooks != null && !sportsbooks.contains(bookmakerKey)) {
          continue;
        }
        
        if (!bookmaker.containsKey('markets')) {
          continue;
        }
        
        final String bookmakerName = _formatSportsbookName(bookmakerKey);
        final List<dynamic> markets = bookmaker['markets'] ?? [];
        
        if (markets.isEmpty) {
          continue;
        }
        
        Map<String, dynamic> moneylineOdds = {};
        Map<String, dynamic> spreadOdds = {};
        Map<String, dynamic> totalOdds = {};
        
        for (var market in markets) {
          final String marketKey = market['key'] as String? ?? '';
          final List<dynamic> outcomes = market['outcomes'] ?? [];
          
          if (marketKey == 'h2h') {
            _processMoneylineOutcomes(outcomes, moneylineOdds);
          } else if (marketKey == 'spreads') {
            _processSpreadOutcomes(outcomes, spreadOdds);
          } else if (marketKey == 'totals') {
            _processTotalOutcomes(outcomes, totalOdds);
          }
        }
        
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
        
        result[bookmakerKey] = oddsData;
      }
      
      return result;
    } catch (e) {
      print('Error parsing odds data: $e');
      return {};
    }
  }
  
  void _processMoneylineOutcomes(List<dynamic> outcomes, Map<String, dynamic> moneylineOdds) {
    for (var outcome in outcomes) {
      final String name = outcome['name'] as String? ?? '';
      final int price = outcome['price'] as int? ?? 0;
      
      if (name.toLowerCase() == 'home') {
        moneylineOdds['home'] = price;
      } else if (name.toLowerCase() == 'away') {
        moneylineOdds['away'] = price;
      } else if (name.toLowerCase() == 'draw') {
        moneylineOdds['draw'] = price;
      }
    }
  }
  
  void _processSpreadOutcomes(List<dynamic> outcomes, Map<String, dynamic> spreadOdds) {
    for (var outcome in outcomes) {
      final String name = outcome['name'] as String? ?? '';
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0;
      final int price = outcome['price'] as int? ?? 0;
      
      if (name.toLowerCase() == 'home') {
        spreadOdds['home'] = {'point': point, 'price': price};
      } else if (name.toLowerCase() == 'away') {
        spreadOdds['away'] = {'point': point, 'price': price};
      }
    }
  }
  
  void _processTotalOutcomes(List<dynamic> outcomes, Map<String, dynamic> totalOdds) {
    for (var outcome in outcomes) {
      final String name = (outcome['name'] as String? ?? '').toLowerCase();
      final double point = (outcome['point'] as num?)?.toDouble() ?? 0.0;
      final int price = outcome['price'] as int? ?? 0;
      
      if (name == 'over') {
        totalOdds['over'] = {'point': point, 'price': price};
      } else if (name == 'under') {
        totalOdds['under'] = {'point': point, 'price': price};
      }
    }
  }

  /// Get best odds for a specific game
  Future<OddsData?> getBestOddsForGame(String gameId, String sport, String betType, String betSide) async {
    try {
      final allOdds = await fetchOddsForGame(gameId, sport);
      
      if (allOdds.isEmpty) {
        return null;
      }
      
      OddsData? bestOdds;
      int bestPrice = -10000;
      
      for (var oddsData in allOdds.values) {
        int currentPrice = -10000;
        
        switch (betType.toLowerCase()) {
          case 'moneyline':
            if (oddsData.moneyline != null && oddsData.moneyline!.containsKey(betSide)) {
              currentPrice = oddsData.moneyline![betSide] as int;
            }
            break;
            
          case 'spread':
            if (oddsData.spread != null && oddsData.spread!.containsKey(betSide)) {
              currentPrice = oddsData.spread![betSide]['price'] as int;
            }
            break;
            
          case 'total':
            if (oddsData.total != null && oddsData.total!.containsKey(betSide)) {
              currentPrice = oddsData.total![betSide]['price'] as int;
            }
            break;
        }
        
        if (currentPrice > bestPrice) {
          bestPrice = currentPrice;
          bestOdds = oddsData;
        }
      }
      
      return bestOdds;
    } catch (e) {
      print('Error getting best odds: $e');
      return null;
    }
  }

  /// Compare odds across sportsbooks
  Map<String, dynamic> compareOddsAcrossSportsbooks(Map<String, OddsData> odds, String betType, String betSide) {
    if (odds.isEmpty) {
      return {};
    }
    
    final Map<String, dynamic> result = {
      'best': null,
      'worst': null,
      'average': 0,
      'difference': 0,
      'all': <String, dynamic>{},
    };
    
    return result;
  }
}
