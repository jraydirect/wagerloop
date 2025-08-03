import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/sports/odds.dart';
import '../models/sports/sportsbook.dart';

/// Comprehensive ESPN Odds Service
/// 
/// Leverages ESPN's dedicated betting endpoints to provide rich odds data
/// including multiple sportsbooks, win probabilities, odds movement, and
/// team performance metrics throughout the WagerLoop app.
class ESPNOddsService {
  // Singleton pattern
  static final ESPNOddsService _instance = ESPNOddsService._internal();
  factory ESPNOddsService() => _instance;
  ESPNOddsService._internal();

  // ESPN API base URLs for betting data  
  final String _coreApiUrl = 'sports.core.api.espn.com';
  final String _siteApiUrl = 'site.api.espn.com'; // For basic game data
  
  // Cache for odds data to improve performance
  final Map<String, dynamic> _oddsCache = {};
  final Map<String, dynamic> _probabilitiesCache = {};
  final Map<String, dynamic> _predictorCache = {};
  DateTime? _lastCacheUpdate;
  final Duration _cacheValidity = const Duration(minutes: 5);

  // ESPN Sportsbook Provider IDs and Names
  final Map<int, String> _providerNames = {
    38: 'Caesars',
    31: 'William Hill',
    41: 'SugarHouse', 
    36: 'Unibet',
    2000: 'Bet365',
    25: 'Westgate',
    45: 'William Hill NJ',
    1001: 'AccuScore',
    1004: 'Consensus',
    1003: 'NumberFire',
    1002: 'TeamRankings',
  };

  // Sport path mappings for ESPN API
  final Map<String, String> _sportPaths = {
    'NFL': 'football/leagues/nfl',
    'NBA': 'basketball/leagues/nba',
    'MLB': 'baseball/leagues/mlb',
    'NHL': 'hockey/leagues/nhl',
    'NCAAF': 'football/leagues/college-football',
    'NCAAB': 'basketball/leagues/mens-college-basketball',
  };

  /// Fetches comprehensive odds data for a specific game
  /// 
  /// Returns odds from all available ESPN sportsbook providers
  /// along with additional betting insights like win probabilities
  Future<Map<String, dynamic>> fetchGameOdds(String eventId, String sport) async {
    final cacheKey = '${sport}_${eventId}_odds';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _oddsCache[cacheKey] ?? {};
    }

    try {
      // Handle both converted sport names (like 'MLB') and original paths (like 'baseball/mlb')
      String sportPath;
      if (_sportPaths.containsKey(sport)) {
        sportPath = _sportPaths[sport]!;
      } else if (sport.contains('/')) {
        // Already a sport path, use directly
        sportPath = sport;
      } else {
        debugPrint('Unknown sport format: $sport');
        return {};
      }

      // Fetch multiple types of betting data in parallel
      // Note: Probabilities and predictor might not be available for all games
      final results = await Future.wait([
        _fetchOddsFromAllProviders(eventId, sportPath),
        _fetchWinProbabilities(eventId, sportPath),
        _fetchPredictorData(eventId, sportPath),
      ]);

      final combinedData = {
        'odds': results[0],
        'probabilities': results[1],
        'predictor': results[2],
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Cache the result
      _oddsCache[cacheKey] = combinedData;
      _lastCacheUpdate = DateTime.now();

      return combinedData;
    } catch (e) {
      debugPrint('ESPN Odds Service Error: $e');
      return {};
    }
  }

  /// Fetches odds from all available ESPN sportsbook providers using correct API patterns
  Future<Map<String, dynamic>> _fetchOddsFromAllProviders(String eventId, String sportPath) async {
    
    // Try the primary core API odds endpoint
    try {
      Uri coreOddsUri;
      Map<String, String> headers = {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      };
      
      if (kIsWeb) {
        // Use CORS proxy for web platform
        final targetUrl = 'https://$_coreApiUrl/v2/sports/$sportPath/events/$eventId/competitions/$eventId/odds';
        coreOddsUri = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}');
      } else {
        coreOddsUri = Uri.parse('https://$_coreApiUrl/v2/sports/$sportPath/events/$eventId/competitions/$eventId/odds');
      }
      
      debugPrint('ESPN Core Odds API Call: $coreOddsUri');
      
      final coreResponse = await http.get(coreOddsUri, headers: headers);
      
      debugPrint('ESPN Core Odds API Response Status: ${coreResponse.statusCode}');
      if (coreResponse.statusCode == 200) {
        debugPrint('ESPN Core Odds API Response Body Length: ${coreResponse.body.length}');
        final data = jsonDecode(coreResponse.body);
        debugPrint('ESPN Core Odds API Response Keys: ${data.keys.toList()}');
        
        final result = _parseESPNOddsResponse(data);
        if (result['odds'] != null && result['odds'] is Map && (result['odds'] as Map).isNotEmpty) {
          debugPrint('Found odds data from core API with ${(result['odds'] as Map).length} providers');
          return result;
        }
      } else {
        debugPrint('ESPN Core Odds API failed with status: ${coreResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('ESPN Core Odds API Error: $e');
    }
    
    // Try the alternative site API summary endpoint which might contain odds
    try {
      Uri siteUri;
      Map<String, String> headers = {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      };
      
      if (kIsWeb) {
        final targetUrl = 'https://$_siteApiUrl/apis/site/v2/sports/$sportPath/summary?event=$eventId';
        siteUri = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}');
      } else {
        siteUri = Uri.parse('https://$_siteApiUrl/apis/site/v2/sports/$sportPath/summary?event=$eventId');
      }
      
      debugPrint('ESPN Site Summary API Call: $siteUri');
      
      final siteResponse = await http.get(siteUri, headers: headers);

      debugPrint('ESPN Site Summary API Response Status: ${siteResponse.statusCode}');
      if (siteResponse.statusCode == 200) {
        final data = jsonDecode(siteResponse.body);
        debugPrint('ESPN Site Summary API Response Keys: ${data.keys.toList()}');
        
        if (data['odds'] != null || data['pickcenter'] != null) {
          debugPrint('Found odds data in ESPN site summary response');
          final result = _parseESPNSummaryResponse(data);
          if (result['odds'] != null && result['odds'] is Map && (result['odds'] as Map).isNotEmpty) {
            debugPrint('Parsed odds data from site summary with ${(result['odds'] as Map).length} providers');
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('ESPN Site Summary API Error: $e');
    }

    // Try getting a list of all events and find this specific event with odds
    try {
      Uri eventsUri;
      Map<String, String> headers = {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      };
      
      // Get current date for events endpoint
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      
      if (kIsWeb) {
        final targetUrl = 'https://$_coreApiUrl/v2/sports/$sportPath/events?dates=$dateStr&limit=100';
        eventsUri = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}');
      } else {
        eventsUri = Uri.parse('https://$_coreApiUrl/v2/sports/$sportPath/events?dates=$dateStr&limit=100');
      }
      
      debugPrint('ESPN Events List API Call: $eventsUri');
      
      final eventsResponse = await http.get(eventsUri, headers: headers);
      
      debugPrint('ESPN Events List API Response Status: ${eventsResponse.statusCode}');
      if (eventsResponse.statusCode == 200) {
        final data = jsonDecode(eventsResponse.body);
        debugPrint('ESPN Events List API Response Keys: ${data.keys.toList()}');
        
        // Look for our specific event in the list
        if (data['items'] != null && data['items'] is List) {
          final events = data['items'] as List;
          debugPrint('Found ${events.length} events in list');
          
          for (var event in events) {
            if (event['id']?.toString() == eventId) {
              debugPrint('Found matching event with ID: $eventId');
              if (event['competitions'] != null && (event['competitions'] as List).isNotEmpty) {
                final competition = (event['competitions'] as List).first;
                if (competition['odds'] != null) {
                  debugPrint('Found odds in event competition data');
                  return {
                    'odds': _convertOddsListToMap(competition['odds'] is List ? competition['odds'] : [competition['odds']])
                  };
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ESPN Events List API Error: $e');
    }
    
    debugPrint('No odds data found from any ESPN API endpoint for event: $eventId');
    return {};
  }

  /// Fetches odds from a specific sportsbook provider
  Future<Map<String, dynamic>> fetchProviderOdds(String eventId, String sport, int providerId) async {
    final sportPath = _sportPaths[sport];
    if (sportPath == null) return {};

    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/events/$eventId/competitions/$eventId/odds/$providerId');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseProviderOddsResponse(data, providerId);
      } else {
        debugPrint('ESPN Provider Odds API Error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('ESPN Provider Odds Error: $e');
      return {};
    }
  }

  /// Fetches win probabilities for a game
  Future<Map<String, dynamic>> _fetchWinProbabilities(String eventId, String sportPath) async {
    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/events/$eventId/competitions/$eventId/probabilities');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseProbabilitiesResponse(data);
      } else {
        debugPrint('ESPN Probabilities API Error: ${response.statusCode} for event $eventId');
        // Don't treat this as a fatal error - probabilities might not be available for all games
        return {};
      }
    } catch (e) {
      debugPrint('ESPN Probabilities Error: $e');
      return {};
    }
  }

  /// Fetches ESPN predictor data for enhanced insights
  Future<Map<String, dynamic>> _fetchPredictorData(String eventId, String sportPath) async {
    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/events/$eventId/competitions/$eventId/predictor');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parsePredictorResponse(data);
      } else {
        // Predictor data might not be available for all games, so don't spam logs
        if (response.statusCode != 404) {
          debugPrint('ESPN Predictor API Error: ${response.statusCode} for event $eventId');
        }
        return {};
      }
    } catch (e) {
      debugPrint('ESPN Predictor Error: $e');
      return {};
    }
  }

  /// Fetches odds movement history for a specific provider
  Future<List<Map<String, dynamic>>> fetchOddsHistory(String eventId, String sport, int providerId) async {
    final sportPath = _sportPaths[sport];
    if (sportPath == null) return [];

    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/events/$eventId/competitions/$eventId/odds/$providerId/history/0/movement');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOddsHistoryResponse(data);
      } else {
        debugPrint('ESPN Odds History API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ESPN Odds History Error: $e');
      return [];
    }
  }

  /// Fetches team ATS (Against The Spread) records
  Future<Map<String, dynamic>> fetchTeamATSRecord(String teamId, String sport, int year, int seasonType) async {
    final sportPath = _sportPaths[sport];
    if (sportPath == null) return {};

    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/seasons/$year/types/$seasonType/teams/$teamId/ats');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseATSResponse(data);
      } else {
        debugPrint('ESPN ATS API Error: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('ESPN ATS Error: $e');
      return {};
    }
  }

  /// Fetches futures betting data for a sport/season
  Future<List<Map<String, dynamic>>> fetchFutures(String sport, int year) async {
    final sportPath = _sportPaths[sport];
    if (sportPath == null) return [];

    try {
      final uri = Uri.https(_coreApiUrl, '/v2/sports/$sportPath/seasons/$year/futures');
      
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseFuturesResponse(data);
      } else {
        debugPrint('ESPN Futures API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('ESPN Futures Error: $e');
      return [];
    }
  }

  // Parsing methods for different ESPN API responses

  /// Parses ESPN summary response for odds/predictor data  
  Map<String, dynamic> _parseESPNSummaryResponse(Map<String, dynamic> data) {
    try {
      final Map<String, dynamic> result = {};
      
      // Debug: Log the actual data structure
      debugPrint('ESPN Summary Data Keys: ${data.keys.toList()}');
      
      // Check multiple possible locations for odds data
      List<dynamic>? oddsItems;
      
      // Try 'odds' field first
      if (data['odds'] != null) {
        final oddsData = data['odds'];
        debugPrint('ESPN Odds Type: ${oddsData.runtimeType}');
        debugPrint('ESPN Odds Content Length: ${oddsData is List ? oddsData.length : 'Not a list'}');
        
        if (oddsData is List && oddsData.isNotEmpty) {
          oddsItems = oddsData;
          debugPrint('Found odds data in "odds" field');
        }
      }
      
      // Try 'pickcenter' field if odds is empty
      if (oddsItems == null || oddsItems.isEmpty) {
        if (data['pickcenter'] != null) {
          final pickcenterData = data['pickcenter'];
          debugPrint('ESPN Pickcenter Type: ${pickcenterData.runtimeType}');
          
          if (pickcenterData is Map) {
            // Look for odds in pickcenter structure
            if (pickcenterData['odds'] != null && pickcenterData['odds'] is List) {
              oddsItems = pickcenterData['odds'];
              debugPrint('Found odds data in "pickcenter.odds" field');
            } else if (pickcenterData['providers'] != null && pickcenterData['providers'] is List) {
              oddsItems = pickcenterData['providers'];
              debugPrint('Found odds data in "pickcenter.providers" field');
            }
          }
        }
      }
      
      // Try 'againstTheSpread' field if still no odds
      if (oddsItems == null || oddsItems.isEmpty) {
        if (data['againstTheSpread'] != null) {
          final atsData = data['againstTheSpread'];
          debugPrint('ESPN ATS Type: ${atsData.runtimeType}');
          
          if (atsData is Map && atsData['odds'] != null && atsData['odds'] is List) {
            oddsItems = atsData['odds'];
            debugPrint('Found odds data in "againstTheSpread.odds" field');
          }
        }
      }
      
      // Convert odds items if found
      if (oddsItems != null && oddsItems.isNotEmpty) {
        result['odds'] = _convertOddsListToMap(oddsItems);
        debugPrint('Converted ${oddsItems.length} odds items to map format');
      } else {
        debugPrint('No odds data found in any expected fields');
        // Create empty odds structure
        result['odds'] = <String, dynamic>{};
      }
      
      // Extract predictor data if available
      if (data['predictor'] != null) {
        final predictorData = data['predictor'];
        debugPrint('ESPN Predictor Type: ${predictorData.runtimeType}');
        result['predictor'] = predictorData is Map ? Map<String, dynamic>.from(predictorData) : {};
        debugPrint('Extracted predictor from ESPN summary');
      }
      
      // Extract win probability if available
      if (data['winprobability'] != null) {
        final winProbData = data['winprobability']; 
        debugPrint('ESPN Win Probability Type: ${winProbData.runtimeType}');
        result['winprobability'] = winProbData is Map ? Map<String, dynamic>.from(winProbData) : {};
        debugPrint('Extracted win probability from ESPN summary');
      }
      
      debugPrint('Final ESPN Summary Parse Result: ${result.keys.toList()}');
      return result;
    } catch (e) {
      debugPrint('ESPN Summary Parse Error: $e');
      return {};
    }
  }
  
  /// Converts ESPN odds list format to map format expected by widget
  Map<String, dynamic> _convertOddsListToMap(List oddsData) {
    try {
      final Map<String, dynamic> result = {};
      
      for (var item in oddsData) {
        if (item is Map<String, dynamic>) {
          // Extract provider/sportsbook information - try different structures
          String providerName = 'Unknown';
          String providerId = 'unknown';
          
          if (item['provider'] != null) {
            final provider = item['provider'];
            if (provider is Map) {
              providerName = provider['name']?.toString() ?? 'Unknown';
              providerId = provider['id']?.toString() ?? 'unknown';
            } else {
              providerName = provider.toString();
            }
          } else if (item['details'] != null) {
            providerName = item['details']?.toString() ?? 'ESPN';
          } else if (item['name'] != null) {
            providerName = item['name']?.toString() ?? 'ESPN';
          } else {
            providerName = 'ESPN';
          }
          
          debugPrint('Processing provider: $providerName (ID: $providerId)');
          
          // Extract betting markets - try multiple formats
          final Map<String, dynamic> markets = {};
          
          // Try format 1: awayTeamOdds/homeTeamOdds structure
          if (item['awayTeamOdds'] != null && item['homeTeamOdds'] != null) {
            // Moneyline odds
            final awayML = item['awayTeamOdds']['moneyLine'];
            final homeML = item['homeTeamOdds']['moneyLine'];
            if (awayML != null && homeML != null) {
              markets['moneyline'] = {
                'away': {
                  'american': _formatOdds(awayML),
                  'odds': awayML,
                },
                'home': {
                  'american': _formatOdds(homeML),
                  'odds': homeML,
                }
              };
              debugPrint('Added moneyline: Away $awayML, Home $homeML');
            }
            
            // Spread odds
            if (item['spread'] != null) {
              final spreadValue = item['spread'];
              final awaySpreadOdds = item['awayTeamOdds']['current']?['spread']?['american'] ?? 
                                    item['awayTeamOdds']['spreadOdds'];
              final homeSpreadOdds = item['homeTeamOdds']['current']?['spread']?['american'] ?? 
                                    item['homeTeamOdds']['spreadOdds'];
              
              markets['spread'] = {
                'spread': spreadValue,
                'away': {
                  'point': '+$spreadValue',
                  'odds': _formatOdds(awaySpreadOdds),
                },
                'home': {
                  'point': '-$spreadValue', 
                  'odds': _formatOdds(homeSpreadOdds),
                }
              };
              debugPrint('Added spread: $spreadValue with odds Away: $awaySpreadOdds, Home: $homeSpreadOdds');
            }
          }
          
          // Try format 2: direct odds structure
          if (item['moneyline'] != null) {
            final ml = item['moneyline'];
            if (ml is Map) {
              markets['moneyline'] = {
                'away': {
                  'american': _formatOdds(ml['away']),
                  'odds': ml['away'],
                },
                'home': {
                  'american': _formatOdds(ml['home']),
                  'odds': ml['home'],
                }
              };
            }
          }
          
          if (item['spread'] != null && item['spread'] is Map) {
            final spread = item['spread'];
            markets['spread'] = {
              'spread': spread['value'] ?? spread['line'],
              'away': {
                'point': '+${spread['value'] ?? spread['line']}',
                'odds': _formatOdds(spread['awayOdds'] ?? spread['away']),
              },
              'home': {
                'point': '-${spread['value'] ?? spread['line']}',
                'odds': _formatOdds(spread['homeOdds'] ?? spread['home']),
              }
            };
          }
          
          // Over/Under (Totals) - try multiple formats
          if (item['overUnder'] != null) {
            final totalValue = item['overUnder'];
            final overOdds = item['current']?['over']?['american'] ?? 
                            item['overOdds'] ?? 
                            item['total']?['over'];
            final underOdds = item['current']?['under']?['american'] ?? 
                             item['underOdds'] ?? 
                             item['total']?['under'];
            
            markets['total'] = {
              'total': totalValue,
              'over': {
                'american': _formatOdds(overOdds),
                'odds': overOdds,
              },
              'under': {
                'american': _formatOdds(underOdds),
                'odds': underOdds,
              }
            };
            debugPrint('Added totals: O/U $totalValue with Over: $overOdds, Under: $underOdds');
          } else if (item['total'] != null && item['total'] is Map) {
            final total = item['total'];
            markets['total'] = {
              'total': total['value'] ?? total['line'],
              'over': {
                'american': _formatOdds(total['over']),
                'odds': total['over'],
              },
              'under': {
                'american': _formatOdds(total['under']),
                'odds': total['under'],
              }
            };
          }
          
          if (markets.isNotEmpty) {
            result[providerName] = {
              'provider': providerName,
              'providerId': providerId,
              'lastUpdated': DateTime.now().toIso8601String(),
              ...markets,
            };
            debugPrint('Added markets for $providerName: ${markets.keys.toList()}');
          } else {
            debugPrint('No valid markets found for $providerName - item keys: ${item.keys.toList()}');
          }
        }
      }
      
      debugPrint('Final conversion result: ${result.keys.toList()}');
      debugPrint('Converted ${oddsData.length} odds items to map with ${result.length} providers');
      return result;
    } catch (e) {
      debugPrint('Error converting odds list to map: $e');
      debugPrint('Odds data causing error: $oddsData');
      return {};
    }
  }
  
  /// Helper method to format odds for display
  String _formatOdds(dynamic odds) {
    if (odds == null) return 'N/A';
    final numOdds = odds is num ? odds : (num.tryParse(odds.toString()) ?? 0);
    return numOdds > 0 ? '+$numOdds' : '$numOdds';
  }

  Map<String, dynamic> _parseESPNOddsResponse(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    try {
      debugPrint('Parsing ESPN Core Odds Response: ${data.keys.toList()}');
      
      // Handle the structure with 'items' array (like your JSON example)
      final items = data['items'] as List? ?? [];
      debugPrint('Found ${items.length} odds items');
      
      if (items.isNotEmpty) {
        result['odds'] = _convertOddsListToMap(items);
        debugPrint('Successfully converted ${items.length} odds items');
      } else {
        debugPrint('No odds items found in response');
      }
      
    } catch (e) {
      debugPrint('ESPN Odds Parse Error: $e');
    }
    
    return result;
  }

  Map<String, dynamic> _parseProviderOddsResponse(Map<String, dynamic> data, int providerId) {
    final providerName = _providerNames[providerId] ?? 'Unknown';
    
    return {
      'provider': providerName,
      'providerId': providerId,
      'moneyline': _parseMoneylineOdds(data),
      'spread': _parseSpreadOdds(data),
      'total': _parseTotalOdds(data),
      'lastUpdated': data['lastModified'] ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _parseProbabilitiesResponse(Map<String, dynamic> data) {
    try {
      return {
        'homeWinProbability': data['homeTeamOdds']?['winPercentage'],
        'awayWinProbability': data['awayTeamOdds']?['winPercentage'],
        'tieWinProbability': data['tieOdds']?['winPercentage'],
        'lastUpdated': data['lastModified'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('ESPN Probabilities Parse Error: $e');
      return {};
    }
  }

  Map<String, dynamic> _parsePredictorResponse(Map<String, dynamic> data) {
    try {
      return {
        'homeTeamRating': data['homeTeam']?['gameProjection'],
        'awayTeamRating': data['awayTeam']?['gameProjection'],
        'predictedWinner': data['gameWinner']?['team']?['displayName'],
        'confidenceScore': data['gameWinner']?['confidence'],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('ESPN Predictor Parse Error: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _parseOddsHistoryResponse(Map<String, dynamic> data) {
    try {
      final items = data['items'] as List? ?? [];
      return items.map((item) => {
        'timestamp': item['timestamp'],
        'moneyline': _parseMoneylineOdds(item),
        'spread': _parseSpreadOdds(item),
        'total': _parseTotalOdds(item),
      }).toList();
    } catch (e) {
      debugPrint('ESPN Odds History Parse Error: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseATSResponse(Map<String, dynamic> data) {
    try {
      return {
        'wins': data['wins'] ?? 0,
        'losses': data['losses'] ?? 0,
        'pushes': data['pushes'] ?? 0,
        'winPercentage': data['winPercentage'] ?? 0.0,
        'averageSpreadDifferential': data['averageSpreadDifferential'],
      };
    } catch (e) {
      debugPrint('ESPN ATS Parse Error: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _parseFuturesResponse(Map<String, dynamic> data) {
    try {
      final items = data['items'] as List? ?? [];
      return items.map((item) => {
        'team': item['team']?['displayName'],
        'odds': item['odds'],
        'description': item['description'],
      }).toList();
    } catch (e) {
      debugPrint('ESPN Futures Parse Error: $e');
      return [];
    }
  }

  // Helper methods for parsing specific bet types

  Map<String, dynamic>? _parseMoneylineOdds(Map<String, dynamic> item) {
    try {
      final moneyline = item['moneyLine'];
      if (moneyline == null) return null;
      
      return {
        'home': _parseOddsValue(moneyline['homeTeamOdds']?['moneyLine']),
        'away': _parseOddsValue(moneyline['awayTeamOdds']?['moneyLine']),
        'draw': _parseOddsValue(moneyline['tieOdds']?['moneyLine']), // For soccer
      };
    } catch (e) {
      debugPrint('Moneyline parse error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseSpreadOdds(Map<String, dynamic> item) {
    try {
      final spread = item['spread'];
      if (spread == null) return null;
      
      return {
        'home': {
          'point': _parseDoubleValue(spread['homeTeamOdds']?['spread']?['pointSpread']),
          'price': _parseOddsValue(spread['homeTeamOdds']?['spread']?['moneyLine']),
        },
        'away': {
          'point': _parseDoubleValue(spread['awayTeamOdds']?['spread']?['pointSpread']),
          'price': _parseOddsValue(spread['awayTeamOdds']?['spread']?['moneyLine']),
        },
      };
    } catch (e) {
      debugPrint('Spread parse error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseTotalOdds(Map<String, dynamic> item) {
    try {
      final total = item['total'];
      if (total == null) return null;
      
      return {
        'over': {
          'point': _parseDoubleValue(total['overUnder']),
          'price': _parseOddsValue(total['overOdds']?['moneyLine']),
        },
        'under': {
          'point': _parseDoubleValue(total['overUnder']),
          'price': _parseOddsValue(total['underOdds']?['moneyLine']),
        },
      };
    } catch (e) {
      debugPrint('Total parse error: $e');
      return null;
    }
  }

  // Utility methods

  bool _isCacheValid(String key) {
    if (!_oddsCache.containsKey(key) || _lastCacheUpdate == null) {
      return false;
    }
    
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!) < _cacheValidity;
  }

  void clearCache() {
    _oddsCache.clear();
    _probabilitiesCache.clear();
    _predictorCache.clear();
    _lastCacheUpdate = null;
  }

  /// Gets available sportsbook providers
  Map<int, String> get availableProviders => Map.from(_providerNames);

  /// Gets formatted odds display for UI
  String formatOdds(dynamic odds) {
    if (odds == null) return 'N/A';
    
    try {
      final oddsValue = odds is int ? odds : int.tryParse(odds.toString()) ?? 0;
      return oddsValue >= 0 ? '+$oddsValue' : '$oddsValue';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Gets formatted probability display for UI
  String formatProbability(dynamic probability) {
    if (probability == null) return 'N/A';
    
    try {
      final probValue = probability is double ? probability : double.tryParse(probability.toString()) ?? 0.0;
      return '${(probValue * 100).toStringAsFixed(1)}%';
    } catch (e) {
      return 'N/A';
    }
  }

  /// Test method to debug ESPN API responses
  Future<void> debugESPNAPI() async {
    try {
      debugPrint('=== ESPN API DEBUG TEST ===');
      
      // Test different endpoints for NFL
      final endpoints = [
        'https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard',
        'https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events',
      ];
      
      for (String endpoint in endpoints) {
        try {
          debugPrint('\n--- Testing endpoint: $endpoint ---');
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'WagerLoop/1.0',
            },
          );
          
          debugPrint('Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            debugPrint('Response keys: ${data.keys.toList()}');
            
            if (data['events'] != null && (data['events'] as List).isNotEmpty) {
              final firstEvent = (data['events'] as List).first;
              debugPrint('First event keys: ${firstEvent.keys.toList()}');
              debugPrint('First event ID: ${firstEvent['id']}');
              
              if (firstEvent['competitions'] != null && (firstEvent['competitions'] as List).isNotEmpty) {
                final competition = (firstEvent['competitions'] as List).first;
                debugPrint('Competition keys: ${competition.keys.toList()}');
                
                if (competition['odds'] != null) {
                  debugPrint('FOUND ODDS! Type: ${competition['odds'].runtimeType}');
                  debugPrint('Odds content: ${competition['odds']}');
                } else {
                  debugPrint('No odds in competition');
                }
              }
            }
          } else {
            debugPrint('Failed with status: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error testing $endpoint: $e');
        }
      }
      
      debugPrint('=== END ESPN API DEBUG TEST ===');
    } catch (e) {
      debugPrint('Debug test error: $e');
    }
  }

  /// Helper method to safely parse odds values from ESPN API
  /// ESPN sometimes returns odds as strings, so we need to convert them to integers
  int? _parseOddsValue(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        // Try parsing as double first, then convert to int
        final doubleValue = double.tryParse(value);
        return doubleValue?.round();
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing odds value $value: $e');
      return null;
    }
  }

  /// Helper method to safely parse double values from ESPN API
  double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing double value $value: $e');
      return null;
    }
  }

  /// Fetch current games with odds from ESPN scoreboard
  /// This is often more reliable than individual game endpoints
  Future<Map<String, Map<String, dynamic>>> fetchTodaysGamesWithOdds(String sport) async {
    try {
      final sportPath = _sportPaths[sport];
      if (sportPath == null) return {};

      // Get today's date for scoreboard
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      Uri scoreboardUri;
      Map<String, String> headers = {
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      };

      if (kIsWeb) {
        final targetUrl = 'https://$_siteApiUrl/apis/site/v2/sports/$sportPath/scoreboard?dates=$dateStr';
        scoreboardUri = Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}');
      } else {
        scoreboardUri = Uri.parse('https://$_siteApiUrl/apis/site/v2/sports/$sportPath/scoreboard?dates=$dateStr');
      }

      debugPrint('ESPN Scoreboard Odds API Call: $scoreboardUri');

      final response = await http.get(scoreboardUri, headers: headers);

      debugPrint('ESPN Scoreboard API Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('ESPN Scoreboard API Response Keys: ${data.keys.toList()}');

        final Map<String, Map<String, dynamic>> gamesWithOdds = {};

        if (data['events'] != null && data['events'] is List) {
          final events = data['events'] as List;
          debugPrint('Found ${events.length} events in scoreboard');

          for (var event in events) {
            final eventId = event['id']?.toString();
            if (eventId == null) continue;

            // Check if this event has odds in competitions
            if (event['competitions'] != null && (event['competitions'] as List).isNotEmpty) {
              final competition = (event['competitions'] as List).first;
              if (competition['odds'] != null && (competition['odds'] as List).isNotEmpty) {
                debugPrint('Found odds for event $eventId in scoreboard');
                final oddsData = {
                  'odds': _convertOddsListToMap(competition['odds']),
                  'lastUpdated': DateTime.now().toIso8601String(),
                };
                gamesWithOdds[eventId] = oddsData;
              }
            }
          }
        }

        debugPrint('Found odds for ${gamesWithOdds.length} games from scoreboard');
        return gamesWithOdds;
      } else {
        debugPrint('ESPN Scoreboard API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ESPN Scoreboard Odds Error: $e');
    }

    return {};
  }

  /// Creates mock odds data for testing purposes
  Map<String, dynamic> _createMockOddsData() {
    return {
      'odds': {
        'ESPN BET': {
          'provider': 'ESPN BET',
          'providerId': '58',
          'lastUpdated': DateTime.now().toIso8601String(),
          'moneyline': {
            'away': {
              'american': '-120',
              'odds': -120,
            },
            'home': {
              'american': '+100',
              'odds': 100,
            }
          },
          'spread': {
            'spread': 1.5,
            'away': {
              'point': '+1.5',
              'odds': '+140',
            },
            'home': {
              'point': '-1.5',
              'odds': '-165',
            }
          },
          'total': {
            'total': 8.5,
            'over': {
              'american': '-110',
              'odds': -110,
            },
            'under': {
              'american': '-110', 
              'odds': -110,
            }
          },
        }
      },
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
} 