import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sports/game.dart';
import '../models/sports/odds.dart';
import '../models/sports/player.dart';
import 'sports_odds_service.dart';

class SportsApiService {
  // Singleton pattern
  static final SportsApiService _instance = SportsApiService._internal();
  factory SportsApiService() => _instance;
  SportsApiService._internal();

  // TextEditingController for caching search queries
  static TextEditingController? searchController;

  // Cache data to avoid repeated API calls
  final Map<String, List<Game>> _cachedGamesBySport = {};
  DateTime? _lastFetchTime;
  
  // Cache validity period (15 minutes)
  final Duration _cacheValidity = const Duration(minutes: 15);

  // ESPN API base URL
  final String _baseUrl = 'site.api.espn.com';
  
  // API key for paid services (if needed) - get from environment variables
  String? get _apiKey => dotenv.env['ESPN_API_KEY'];

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
    if (query.isEmpty) {
      return [];
    }
    
    final normalizedQuery = query.toLowerCase();
    List<Game> allGames = [];
    
    // The minimum date for returned games
    final minDate = DateTime.now().subtract(const Duration(days: 1));
    
    // Try sports in order of popularity
    List<String> sportsToTry = ['NCAAB', 'NBA', 'NFL', 'NCAAF', 'MLB', 'NHL', 'Soccer'];
    
    for (final sportKey in sportsToTry) {
      try {
        final games = await _fetchGamesFromESPN(sportKey);
        
        // Filter games by team name and date
        for (final game in games) {
          try {
            final homeMatch = game.homeTeam.toLowerCase().contains(normalizedQuery);
            final awayMatch = game.awayTeam.toLowerCase().contains(normalizedQuery);
            
            if (homeMatch || awayMatch) {
              // Check date is on or after minDate
              if (game.gameTime.isAfter(minDate) || game.gameTime.isAtSameMomentAs(minDate)) {
                // Include games that are scheduled or live
                if (game.status == 'scheduled' || game.status == 'live') {
                  allGames.add(game);
                  
                  // Provide immediate feedback
                  if (onIncrementalResults != null) {
                    onIncrementalResults(List.from(allGames));
                  }
                }
              }
            }
          } catch (e) {
            // print('Error checking match in $sportKey: $e');
          }
        }
      } catch (e) {
        // print('Error searching $sportKey: $e');
        continue;
      }
    }
    
    // Sort games by date
    allGames.sort((a, b) => a.gameTime.compareTo(b.gameTime));
    
    return allGames;
  }

  /// Fetch upcoming games for a specific sport
  Future<List<Game>> fetchUpcomingGames({String? sport}) async {
    // Check if we have valid cached data
    final now = DateTime.now();
    final cacheIsValid = _lastFetchTime != null && 
                         now.difference(_lastFetchTime!) < _cacheValidity;
    
    if (sport != null && _cachedGamesBySport.containsKey(sport) && cacheIsValid) {
      return _cachedGamesBySport[sport]!;
    }
    
    try {
      List<Game> games = [];
      
      if (sport != null) {
        // Fetch games for a specific sport
        games = await _fetchGamesFromESPN(sport);
      } else {
        // Fetch games for all supported sports
        for (final sportKey in _sportCodes.keys) {
          final sportGames = await _fetchGamesFromESPN(sportKey);
          games.addAll(sportGames);
        }
      }
      
      // Update cache
      if (sport != null) {
        _cachedGamesBySport[sport] = games;
      } else {
        // Group games by sport
        final gamesBySport = <String, List<Game>>{};
        for (final game in games) {
          gamesBySport.putIfAbsent(game.sport, () => []).add(game);
        }
        _cachedGamesBySport.addAll(gamesBySport);
      }
      
      _lastFetchTime = now;
      return games;
    } catch (e) {
      // print('Error fetching games: $e');
      return [];
    }
  }

  /// Fetch game with detailed sportsbook odds
  Future<Game?> fetchGameWithSportsbookOdds(String gameId, String sport, {List<String>? sportsbooks}) async {
    try {
      // print('Fetching game with sportsbook odds for gameId: $gameId, sport: $sport');
      
      // First fetch the game details from the standard API
      final games = await _fetchGamesFromESPN(sport);
      
      // Try to find by exact ID match first
      int gameIndex = games.indexWhere((game) => game.id == gameId);
      
      // If not found by ID, try to match by team names
      if (gameIndex == -1) {
        // print('Game not found by ID in ESPN data, trying alternative matching');
        
        // Extract team names from the search query if available
        String? teamQuery;
        if (searchController != null && searchController!.text.isNotEmpty) {
          teamQuery = searchController!.text;
          // print('Using search text to match: $teamQuery');
        }
        
        if (teamQuery != null && teamQuery.contains('vs')) {
          // Extract team names from search query
          final teamParts = teamQuery.split('vs');
          if (teamParts.length >= 2) {
            final homeTeam = teamParts[0].trim();
            String awayTeam = teamParts[1].trim();
            // Remove game time if it's in parentheses
            if (awayTeam.contains('(')) {
              awayTeam = awayTeam.split('(')[0].trim();
            }
            
            // print('Trying to match: $homeTeam vs $awayTeam');
            
            // Try to find a match by team names
            for (var game in games) {
              if ((game.homeTeam.toLowerCase().contains(homeTeam.toLowerCase()) && 
                   game.awayTeam.toLowerCase().contains(awayTeam.toLowerCase())) ||
                  (game.homeTeam.toLowerCase().contains(awayTeam.toLowerCase()) && 
                   game.awayTeam.toLowerCase().contains(homeTeam.toLowerCase()))) {
                
                // print('Found match by team names: ${game.homeTeam} vs ${game.awayTeam}');
                gameIndex = games.indexOf(game);
                break;
              }
            }
          }
        }
      }
      
      // If still not found, log error and return null
      if (gameIndex == -1) {
        // print('Game not found with ID: $gameId in $sport');
        return null;
      }
      
      final game = games[gameIndex];
      // print('Found game: ${game.homeTeam} vs ${game.awayTeam} at ${game.gameTime}');
      
      // Get the sportsbooks odds service
      final sportsOddsService = SportsOddsService();
      
      // Try to directly fetch odds for just this game first
      // print('Fetching odds directly for gameId: $gameId');
      final directOdds = await sportsOddsService.fetchOddsForGame(gameId, sport, sportsbooks: sportsbooks);
      
      if (directOdds.isNotEmpty) {
        // print('Got direct odds for game from ${directOdds.length} sportsbooks');
        // Create a new game object with the sportsbook odds included
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
        
        return gameWithOdds;
      }
      
      // If direct fetch fails, try getting all odds for the sport
      // print('Direct odds fetch failed or empty, trying to fetch all odds for sport');
      final allOddsForSport = await sportsOddsService.fetchOddsForSport(sport);
      // print('Fetched odds for ${allOddsForSport.length} games in $sport');
      
      // Extract the odds for this specific game
      Map<String, OddsData>? sportsbookOdds = allOddsForSport[gameId];
      
      // Create a new game object with the sportsbook odds included
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
      
      if (sportsbookOdds == null || sportsbookOdds.isEmpty) {
        // print('No sportsbook odds found for game: $gameId');
      } else {
        // print('Retrieved odds from ${sportsbookOdds.length} sportsbooks for game');
      }
      
      return gameWithOdds;
    } catch (e) {
      // print('Error fetching game with sportsbook odds: $e');
      return null;
    }
  }

  /// Fetch games from ESPN API for a specific sport via scoreboard
  Future<List<Game>> _fetchGamesFromESPN(String sport) async {
    if (!_sportCodes.containsKey(sport)) {
      return _getMockGamesForSport(sport);
    }
  
    final sportCode = _sportCodes[sport]!;
    final uri = Uri.https(_baseUrl, '/apis/site/v2/sports/$sportCode/scoreboard');
  
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'WagerLoop/1.0',
      };
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_apiKey';
      }
  
      final response = await http.get(uri, headers: headers);
  
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseESPNGames(data, sport);
      } else {
        print('ESPN API request failed: Status: ${response.statusCode}. Using mock data.');
        return _getMockGamesForSport(sport);
      }
    } catch (e) {
      print('ESPN API call failed: $e. Using mock data.');
      return _getMockGamesForSport(sport);
    }
  }

  /// Parse ESPN API response into Game objects
  List<Game> _parseESPNGames(Map<String, dynamic> data, String sport) {
    final List<Game> games = [];
    
    try {
      final events = data['events'] as List? ?? [];
      
      if (events.isEmpty) {
        // print('No events found in $sport scoreboard API');
        return [];
      }
      
      // print('Found ${events.length} events in $sport scoreboard');
      
      for (var event in events) {
        try {
          final id = event['id'] as String? ?? '';
          final competitions = event['competitions'] as List? ?? [];
          
          if (competitions.isEmpty) {
            continue;
          }
          
          final competition = competitions[0];
          final competitors = competition['competitors'] as List? ?? [];
          
          if (competitors.length < 2) {
            continue;
          }
          
          // Get teams
          String homeTeam = '';
          String awayTeam = '';
          String homeTeamId = '';
          String awayTeamId = '';
          
          for (var team in competitors) {
            final isHome = team['homeAway'] == 'home';
            final teamData = team['team'] as Map<String, dynamic>? ?? {};
            final teamName = teamData['displayName'] as String? ?? 'Unknown Team';
            final teamId = teamData['id'] as String? ?? '';
            
            if (isHome) {
              homeTeam = teamName;
              homeTeamId = teamId;
            } else {
              awayTeam = teamName;
              awayTeamId = teamId;
            }
          }
          
          // Get game time
          final dateString = competition['date'] as String? ?? DateTime.now().toIso8601String();
          DateTime gameTime;
          try {
            gameTime = DateTime.parse(dateString);
          } catch (e) {
            // print('Error parsing date for $id: $e');
            gameTime = DateTime.now().add(const Duration(days: 1));
          }
          
          // Get game status
          final statusData = competition['status'] as Map<String, dynamic>? ?? {};
          final statusType = statusData['type'] as Map<String, dynamic>? ?? {};
          final status = statusType['state'] as String? ?? 'SCHEDULED';
          
          // Get scores for live games
          int? homeScore;
          int? awayScore;
          String? period;
          
          if (status.toUpperCase() == 'IN' || status.toUpperCase() == 'LIVE') {
            try {
              // Extract scores from competitors
              for (var team in competitors) {
                final isHome = team['homeAway'] == 'home';
                final score = int.tryParse(team['score'] ?? '') ?? 0;
                
                if (isHome) {
                  homeScore = score;
                } else {
                  awayScore = score;
                }
              }
              
              // Try to get period/quarter/inning information
              final displayPeriod = statusData['displayPeriod'] as int? ?? 0;
              final displayClock = statusData['displayClock'] as String? ?? '';
              
              // Convert period data to readable format based on sport
              switch (sport) {
                case 'NBA':
                case 'NCAAB':
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'NFL':
                case 'NCAAF':
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Quarter' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'MLB':
                  final inningHalf = statusData['period'] == 'T' ? 'Top' : 'Bottom';
                  period = displayPeriod > 0 ? '$inningHalf ${_getOrdinal(displayPeriod)}' : '';
                  if (displayClock.isNotEmpty && period.isEmpty) {
                    period = displayClock;
                  }
                  break;
                  
                case 'NHL':
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Period' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                case 'Soccer':
                  period = displayPeriod > 0 ? '${_getOrdinal(displayPeriod)} Half' : '';
                  if (displayClock.isNotEmpty) {
                    period = '$period - $displayClock';
                  }
                  break;
                  
                default:
                  if (displayClock.isNotEmpty) {
                    period = displayClock;
                  }
              }
            } catch (e) {
              // print('Error parsing live game data: $e');
              // Leave scores and period as null if parsing fails
            }
          }
          
          // Get odds if available
          Map<String, dynamic>? odds;
          final oddsData = competition['odds'] as List? ?? [];
          
          if (oddsData.isNotEmpty) {
            final oddDetails = oddsData[0] as Map<String, dynamic>? ?? {};
            odds = _parseOddsFromESPN(oddDetails, sport);
          }
          
          // Create game object
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
          
          games.add(game);
        } catch (e) {
          // print('Error parsing ESPN game data: $e');
          continue;
        }
      }
    } catch (e) {
      // print('Error parsing ESPN games response: $e');
    }
    
    // print('Parsed ${games.length} games for $sport from scoreboard API');
    return games;
  }

  /// Parse odds data from ESPN format
  Map<String, dynamic>? _parseOddsFromESPN(Map<String, dynamic> oddsData, String sport) {
    try {
      final result = <String, dynamic>{};
      
      // Parse spread
      final spread = oddsData['spread'] as double? ?? 0;
      result['spread'] = {
        'home': -spread,
        'away': spread,
      };
      
      // Parse over/under
      final overUnder = oddsData['overUnder'] as double? ?? 0;
      result['total'] = overUnder;
      
      // Set default moneyline (ESPN doesn't always provide this)
      result['moneyline'] = {
        'home': -110,
        'away': -110,
      };
      
      // Add draw for soccer
      if (sport == 'Soccer') {
        result['moneyline']['draw'] = 220;
      }
      
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Map ESPN status to app status
  String _mapESPNStatusToApp(String espnStatus) {
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
    if (number <= 0) return number.toString();
    
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
    return '${number}th';
  }

  /// Get league name from sport
  String _getLeagueFromSport(String sport) {
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

  /// Provides mock game data when ESPN API is unavailable (e.g., due to CORS issues in web)
  List<Game> _getMockGamesForSport(String sport) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final dayAfter = now.add(const Duration(days: 2));
    
    switch (sport) {
      case 'NBA':
        return [
          Game(
            id: 'mock_nba_1',
            homeTeam: 'Los Angeles Lakers',
            awayTeam: 'Boston Celtics',
            homeTeamId: '1610612747',
            awayTeamId: '1610612738',
            gameTime: tomorrow.copyWith(hour: 20, minute: 0),
            sport: 'NBA',
            league: 'NBA',
            status: 'scheduled',
          ),
          Game(
            id: 'mock_nba_2',
            homeTeam: 'Golden State Warriors',
            awayTeam: 'Chicago Bulls',
            homeTeamId: '1610612744',
            awayTeamId: '1610612741',
            gameTime: tomorrow.copyWith(hour: 22, minute: 30),
            sport: 'NBA',
            league: 'NBA',
            status: 'scheduled',
          ),
        ];
      case 'NFL':
        return [
          Game(
            id: 'mock_nfl_1',
            homeTeam: 'Kansas City Chiefs',
            awayTeam: 'Buffalo Bills',
            homeTeamId: '2',
            awayTeamId: '2',
            gameTime: dayAfter.copyWith(hour: 16, minute: 0),
            sport: 'NFL',
            league: 'NFL',
            status: 'scheduled',
          ),
          Game(
            id: 'mock_nfl_2',
            homeTeam: 'Green Bay Packers',
            awayTeam: 'Dallas Cowboys',
            homeTeamId: '2',
            awayTeamId: '2',
            gameTime: dayAfter.copyWith(hour: 20, minute: 0),
            sport: 'NFL',
            league: 'NFL',
            status: 'scheduled',
          ),
        ];
      case 'MLB':
        return [
          Game(
            id: 'mock_mlb_1',
            homeTeam: 'New York Yankees',
            awayTeam: 'Houston Astros',
            homeTeamId: '147',
            awayTeamId: '117',
            gameTime: tomorrow.copyWith(hour: 19, minute: 0),
            sport: 'MLB',
            league: 'MLB',
            status: 'scheduled',
          ),
          Game(
            id: 'mock_mlb_2',
            homeTeam: 'Los Angeles Dodgers',
            awayTeam: 'Atlanta Braves',
            homeTeamId: '119',
            awayTeamId: '144',
            gameTime: tomorrow.copyWith(hour: 22, minute: 0),
            sport: 'MLB',
            league: 'MLB',
            status: 'scheduled',
          ),
        ];
      case 'NHL':
        return [
          Game(
            id: 'mock_nhl_1',
            homeTeam: 'Toronto Maple Leafs',
            awayTeam: 'Montreal Canadiens',
            homeTeamId: '10',
            awayTeamId: '8',
            gameTime: tomorrow.copyWith(hour: 19, minute: 0),
            sport: 'NHL',
            league: 'NHL',
            status: 'scheduled',
          ),
          Game(
            id: 'mock_nhl_2',
            homeTeam: 'Tampa Bay Lightning',
            awayTeam: 'Boston Bruins',
            homeTeamId: '14',
            awayTeamId: '6',
            gameTime: tomorrow.copyWith(hour: 19, minute: 30),
            sport: 'NHL',
            league: 'NHL',
            status: 'scheduled',
          ),
        ];
      case 'NCAAB':
        return [
          Game(
            id: 'mock_ncaab_1',
            homeTeam: 'Duke Blue Devils',
            awayTeam: 'North Carolina Tar Heels',
            homeTeamId: '150',
            awayTeamId: '153',
            gameTime: tomorrow.copyWith(hour: 18, minute: 0),
            sport: 'NCAAB',
            league: 'NCAAB',
            status: 'scheduled',
          ),
          Game(
            id: 'mock_ncaab_2',
            homeTeam: 'Kentucky Wildcats',
            awayTeam: 'Louisville Cardinals',
            homeTeamId: '96',
            awayTeamId: '97',
            gameTime: tomorrow.copyWith(hour: 20, minute: 0),
            sport: 'NCAAB',
            league: 'NCAAB',
            status: 'scheduled',
          ),
        ];
      default:
        return [
          Game(
            id: 'mock_${sport.toLowerCase()}_1',
            homeTeam: 'Home Team',
            awayTeam: 'Away Team',
            homeTeamId: '1',
            awayTeamId: '2',
            gameTime: tomorrow.copyWith(hour: 19, minute: 0),
            sport: sport,
            league: sport,
            status: 'scheduled',
          ),
                 ];
     }
   }
}
