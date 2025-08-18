import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to fetch odds data directly from TheOddsAPI
/// 
/// This service replaces TheOddsAPI widget with custom implementation
/// allowing users to select odds and add them to betting slips
class TheOddsApiService {
  static final TheOddsApiService _instance = TheOddsApiService._internal();
  factory TheOddsApiService() => _instance;
  TheOddsApiService._internal();

  // API configuration
  static const String _baseUrl = 'https://api.the-odds-api.com/v4';
  
  // Get API key from environment - using direct API key for API calls
  String? get _apiKey => dotenv.env['ODDS_API_KEY'];

  // Cache for sports data
  List<Map<String, dynamic>>? _cachedSports;
  DateTime? _sportsLastFetch;

  // Cache for odds data (short-lived due to frequent updates)
  final Map<String, List<Map<String, dynamic>>> _oddsCache = {};
  final Map<String, DateTime> _oddsCacheTime = {};
  final Duration _oddsCacheValidity = const Duration(minutes: 5);

  // Sport mappings
  final Map<String, String> _sportKeys = {
    'NFL': 'americanfootball_nfl',
    'NBA': 'basketball_nba', 
    'MLB': 'baseball_mlb',
    'NHL': 'icehockey_nhl',
    'NCAAF': 'americanfootball_ncaaf',
    'NCAAB': 'basketball_ncaab',
    'Soccer': 'soccer_usa_mls',
    'UFC': 'mma_mixed_martial_arts',
  };

  // Bookmaker mappings (prioritizing FanDuel per user preference)
  final Map<String, String> _bookmakerKeys = {
    'fanduel': 'FanDuel',
    'draftkings': 'DraftKings',
    'betmgm': 'BetMGM',
    'caesars': 'Caesars',
    'bovada': 'Bovada',
    'betrivers': 'BetRivers',
    'pointsbetus': 'PointsBet',
    'barstool': 'Barstool',
    'williamhill_us': 'William Hill',
  };

  /// Fetch available sports from TheOddsAPI
  Future<List<Map<String, dynamic>>> fetchAvailableSports() async {
    // Return cached data if recent
    if (_cachedSports != null && _sportsLastFetch != null) {
      final age = DateTime.now().difference(_sportsLastFetch!);
      if (age.inHours < 24) {
        return _cachedSports!;
      }
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('TheOddsAPI key not configured');
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/sports/?apiKey=$_apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Filter to only active sports
        final activeSports = data
            .where((sport) => sport['active'] == true)
            .map((sport) => Map<String, dynamic>.from(sport))
            .toList();

        _cachedSports = activeSports;
        _sportsLastFetch = DateTime.now();

        debugPrint('Fetched ${activeSports.length} active sports from TheOddsAPI');
        return activeSports;
      } else {
        debugPrint('Failed to fetch sports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching sports: $e');
      return [];
    }
  }

  /// Fetch odds for a specific sport
  Future<List<Map<String, dynamic>>> fetchOddsForSport(
    String sport, {
    List<String>? bookmakers,
    List<String>? markets,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('TheOddsAPI key not configured');
      return [];
    }

    final sportKey = _sportKeys[sport] ?? sport.toLowerCase();
    final cacheKey = '${sportKey}_${bookmakers?.join(',') ?? 'all'}_${markets?.join(',') ?? 'h2h,spreads,totals'}';

    // Check cache
    if (_oddsCache.containsKey(cacheKey) && _oddsCacheTime.containsKey(cacheKey)) {
      final age = DateTime.now().difference(_oddsCacheTime[cacheKey]!);
      if (age < _oddsCacheValidity) {
        debugPrint('Returning cached odds for $sport');
        return _oddsCache[cacheKey]!;
      }
    }

    try {
      // Build query parameters
      final params = <String, String>{
        'apiKey': _apiKey!,
        'regions': 'us',
        'oddsFormat': 'american',
        'markets': markets?.join(',') ?? 'h2h,spreads,totals',
      };

      if (bookmakers != null && bookmakers.isNotEmpty) {
        params['bookmakers'] = bookmakers.join(',');
      }

      final uri = Uri.parse('$_baseUrl/sports/$sportKey/odds').replace(
        queryParameters: params,
      );

      debugPrint('Fetching odds from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final games = data.map((game) => Map<String, dynamic>.from(game)).toList();

        // Cache the results
        _oddsCache[cacheKey] = games;
        _oddsCacheTime[cacheKey] = DateTime.now();

        debugPrint('Fetched odds for ${games.length} games in $sport');
        return games;
      } else {
        debugPrint('Failed to fetch odds: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching odds: $e');
      return [];
    }
  }

  /// Parse odds data into a format suitable for display
  List<Map<String, dynamic>> parseOddsForDisplay(List<Map<String, dynamic>> oddsData) {
    final List<Map<String, dynamic>> displayOdds = [];

    for (final game in oddsData) {
      try {
        final gameId = game['id'] as String? ?? '';
        final homeTeam = game['home_team'] as String? ?? 'Unknown';
        final awayTeam = game['away_team'] as String? ?? 'Unknown';
        final commenceTime = game['commence_time'] as String? ?? '';
        
        DateTime? gameTime;
        try {
          gameTime = DateTime.parse(commenceTime);
        } catch (e) {
          gameTime = DateTime.now();
        }

        final bookmakers = game['bookmakers'] as List? ?? [];

        // Process each bookmaker
        for (final bookmaker in bookmakers) {
          final bookmakerKey = bookmaker['key'] as String? ?? '';
          final bookmakerTitle = bookmaker['title'] as String? ?? '';
          final markets = bookmaker['markets'] as List? ?? [];

          // Process each market (h2h, spreads, totals)
          for (final market in markets) {
            final marketKey = market['key'] as String? ?? '';
            final outcomes = market['outcomes'] as List? ?? [];

            // Convert market key to display name per user preference
            String marketDisplayName;
            switch (marketKey) {
              case 'h2h':
                marketDisplayName = 'Moneyline';
                break;
              case 'spreads':
                marketDisplayName = 'Spreads';
                break;
              case 'totals':
                marketDisplayName = 'Over/Under';
                break;
              default:
                marketDisplayName = marketKey.toUpperCase();
            }

            // Process each outcome
            for (final outcome in outcomes) {
              final name = outcome['name'] as String? ?? '';
              final price = outcome['price'];
              final point = outcome['point'];

              String displayName = name;
              String oddsText = '';

              if (price != null) {
                if (price is int) {
                  oddsText = price > 0 ? '+$price' : '$price';
                } else if (price is double) {
                  oddsText = price > 0 ? '+${price.toStringAsFixed(0)}' : '${price.toStringAsFixed(0)}';
                }
              }

              // Add point for spreads/totals
              if (point != null && (marketKey == 'spreads' || marketKey == 'totals')) {
                if (marketKey == 'spreads') {
                  displayName = '$name ${point > 0 ? '+' : ''}$point';
                } else if (marketKey == 'totals') {
                  displayName = '${name} $point';
                }
              }

              displayOdds.add({
                'gameId': gameId,
                'gameText': '$awayTeam @ $homeTeam',
                'homeTeam': homeTeam,
                'awayTeam': awayTeam,
                'gameTime': gameTime.toIso8601String(),
                'bookmaker': bookmakerTitle,
                'bookmakerKey': bookmakerKey,
                'market': marketDisplayName,
                'marketKey': marketKey,
                'outcome': displayName,
                'price': price,
                'odds': oddsText,
                'point': point,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error parsing game odds: $e');
        continue;
      }
    }

    return displayOdds;
  }

  /// Get the preferred bookmaker (FanDuel per user preference)
  String getPreferredBookmaker() {
    return 'fanduel';
  }

  /// Get all available bookmaker keys
  List<String> getAvailableBookmakers() {
    return _bookmakerKeys.keys.toList();
  }

  /// Get display name for bookmaker key
  String getBookmakerDisplayName(String key) {
    return _bookmakerKeys[key] ?? key;
  }

  /// Get all available sport keys
  List<String> getAvailableSportKeys() {
    return _sportKeys.keys.toList();
  }

  /// Get TheOddsAPI sport key from display name
  String? getSportKey(String displayName) {
    return _sportKeys[displayName];
  }

  /// Clear odds cache (useful for manual refresh)
  void clearOddsCache() {
    _oddsCache.clear();
    _oddsCacheTime.clear();
    debugPrint('Odds cache cleared');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'odds_cache_entries': _oddsCache.length,
      'sports_cached': _cachedSports?.length ?? 0,
      'sports_last_fetch': _sportsLastFetch?.toIso8601String(),
    };
  }
}
