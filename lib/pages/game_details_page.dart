import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:ui';
import '../utils/team_logo_utils.dart';

class GameDetailsPage extends StatefulWidget {
  final dynamic game; // ESPN game object
  final String sport; // Sport key for API calls
  
  GameDetailsPage({super.key, required this.game, required this.sport});
  
  @override
  _GameDetailsPageState createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  Map<String, dynamic>? gameDetails;
  Map<String, dynamic>? fanDuelOdds;
  Map<String, List<Map<String, dynamic>>>? teamRosters; // Store both teams' rosters
  bool isLoading = true;
  bool isLoadingRosters = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Load ESPN game details and FanDuel odds in parallel
      final results = await Future.wait([
        _fetchESPNGameDetails(),
        _fetchFanDuelOdds(),
      ]);
      
      setState(() {
        gameDetails = results[0];
        fanDuelOdds = results[1];
        isLoading = false;
      });

      // Load team rosters after main data is loaded
      _loadTeamRosters();
    } catch (e) {
      setState(() {
        error = 'Failed to load game details';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTeamRosters() async {
    try {
      setState(() {
        isLoadingRosters = true;
      });

      final homeTeamId = _getTeamId(true);
      final awayTeamId = _getTeamId(false);

      if (homeTeamId != null && awayTeamId != null) {
        // Fetch both team rosters in parallel
        final results = await Future.wait([
          _fetchTeamRoster(homeTeamId, true),
          _fetchTeamRoster(awayTeamId, false),
        ]);

        setState(() {
          teamRosters = {
            'home': results[0],
            'away': results[1],
          };
          isLoadingRosters = false;
        });
      } else {
        print('Could not find team IDs for roster lookup');
        setState(() {
          isLoadingRosters = false;
        });
      }
    } catch (e) {
      print('Error loading team rosters: $e');
      setState(() {
        isLoadingRosters = false;
      });
    }
  }

  String? _getTeamId(bool isHome) {
    final competitions = widget.game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return null;
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return null;
    }

    final team = competitors.firstWhere(
      (comp) => comp['homeAway'] == (isHome ? 'home' : 'away'),
      orElse: () => competitors[isHome ? 0 : 1],
    );

    return team['team']['id']?.toString();
  }

  Future<List<Map<String, dynamic>>> _fetchTeamRoster(String teamId, bool isHome) async {
    try {
      final sportPath = widget.sport; // e.g., 'football/nfl'
      final response = await http.get(Uri.parse(
        'https://site.api.espn.com/apis/site/v2/sports/$sportPath/teams/$teamId/roster'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('ESPN Roster API: Found data for team $teamId');
        
        // Extract athletes from the roster
        final roster = data['athletes'] as List<dynamic>? ?? [];
        return roster.map((athlete) {
          final items = athlete['items'] as List<dynamic>? ?? [];
          return items.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'name': item['displayName'] ?? item['name'] ?? 'Unknown',
              'position': item['position']?['abbreviation'] ?? 'N/A',
              'jerseyNumber': item['jersey']?.toString() ?? '',
              'headshot': item['headshot']?['href'] ?? '',
              'age': item['age']?.toString() ?? '',
              'height': item['displayHeight'] ?? '',
              'weight': item['displayWeight'] ?? '',
            };
          }).toList();
        }).expand((element) => element).toList();
      } else {
        print('ESPN Roster API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('ESPN Roster API Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchESPNGameDetails() async {
    try {
      final eventId = widget.game['id']; // ESPN event ID
      final sportPath = widget.sport; // e.g., 'football/nfl'
      
      final response = await http.get(Uri.parse(
        'https://site.api.espn.com/apis/site/v2/sports/$sportPath/summary?event=$eventId'
      ));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('ESPN Game Details: Found data for event $eventId');
        return data;
      }
      print('ESPN API Error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('ESPN API Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchFanDuelOdds() async {
    try {
      // Convert sport path to Odds API format
      final oddsApiSport = _convertToOddsApiSport(widget.sport);
      
      // Get game date for filtering
      final gameDate = DateTime.parse(widget.game['date']);
      final now = DateTime.now();
      
      // Only fetch odds for upcoming games (not past games)
      if (gameDate.isBefore(now.subtract(const Duration(hours: 2)))) {
        print('FanDuel Odds: Game is in the past, odds not available');
        return null;
      }
      
      final dateStart = DateTime(gameDate.year, gameDate.month, gameDate.day);
      final dateEnd = dateStart.add(const Duration(days: 1));
      
      final commenceTimeFrom = dateStart.toUtc().toIso8601String();
      final commenceTimeTo = dateEnd.toUtc().toIso8601String();
      
      print('FanDuel Odds: Fetching odds for $oddsApiSport from $commenceTimeFrom to $commenceTimeTo');
      
      final response = await http.get(Uri.parse(
        'https://api.the-odds-api.com/v4/sports/$oddsApiSport/odds?apiKey=37a6ab2abd9938d21be970bb794eb6a3&regions=us&markets=h2h,spreads,totals&bookmakers=fanduel&commenceTimeFrom=$commenceTimeFrom&commenceTimeTo=$commenceTimeTo'
      ));
      
      if (response.statusCode == 200) {
        final oddsData = json.decode(response.body);
        
        // Match game by team names
        final homeTeam = _getESPNTeamName(widget.game, true);
        final awayTeam = _getESPNTeamName(widget.game, false);
        
        final matchedGame = oddsData.firstWhere(
          (game) => _teamsMatch(game['home_team'], game['away_team'], homeTeam, awayTeam),
          orElse: () => null,
        );
        
        if (matchedGame != null) {
          print('FanDuel Odds: Found match for $homeTeam vs $awayTeam');
        } else {
          print('FanDuel Odds: No match found for $homeTeam vs $awayTeam');
        }
        
        return matchedGame;
      }
      print('Odds API Error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Odds API Error: $e');
      return null;
    }
  }

  String _convertToOddsApiSport(String espnSport) {
    final Map<String, String> sportMapping = {
      'football/nfl': 'americanfootball_nfl',
      'basketball/nba': 'basketball_nba',
      'baseball/mlb': 'baseball_mlb',
      'hockey/nhl': 'icehockey_nhl',
      'mma/ufc': 'mma_mixed_martial_arts',
    };
    return sportMapping[espnSport] ?? 'americanfootball_nfl';
  }

  String _getESPNTeamName(dynamic game, bool isHome) {
    final competitions = game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return '';
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return '';
    }

    final team = competitors.firstWhere(
      (comp) => comp['homeAway'] == (isHome ? 'home' : 'away'),
      orElse: () => competitors[isHome ? 0 : 1],
    );

    final teamInfo = team['team'] ?? team['athlete'] ?? {};
    return teamInfo['displayName'] ?? teamInfo['name'] ?? teamInfo['shortName'] ?? '';
  }

  bool _teamsMatch(String oddsHome, String oddsAway, String espnHome, String espnAway) {
    return _normalizeTeamName(oddsHome) == _normalizeTeamName(espnHome) &&
           _normalizeTeamName(oddsAway) == _normalizeTeamName(espnAway);
  }

  String _normalizeTeamName(String teamName) {
    // Basic team name normalization
    return teamName
        .toLowerCase()
        .replaceAll('los angeles', 'la')
        .replaceAll('new york', 'ny')
        .replaceAll('san francisco', 'sf')
        .replaceAll('golden state', 'gs')
        .replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        border: null,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Color(0xFF4CAF50),
                size: 18,
              ),
            ),
          ),
        ),
        middle: Text(
          'Game Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const CupertinoActivityIndicator(
                        color: Color(0xFF4CAF50),
                        radius: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading Game Details...',
                      style: const TextStyle(
                        color: Color(0xFFE5E5E7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CupertinoColors.destructiveRed.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.destructiveRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.destructiveRed,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Unable to Load Game',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error ?? 'Unknown error',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          CupertinoButton(
                            color: const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: _loadGameDetails,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildPremiumGameHeader(),
                        _buildPremiumGameScore(),
                        _buildPremiumOddsSection(),
                        _buildGameStats(),
                        _buildTeamRosters(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildPremiumGameHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Game Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isGameCompleted() 
                          ? [const Color(0xFF4CAF50), const Color(0xFF45A049)]
                          : _isGameInProgress()
                              ? [const Color(0xFFFF5722), const Color(0xFFE64A19)]
                              : [const Color(0xFF2C2C2E), const Color(0xFF3C3C3E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isGameCompleted() 
                          ? const Color(0xFF4CAF50) 
                          : _isGameInProgress()
                              ? const Color(0xFFFF5722)
                              : const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isGameCompleted() 
                            ? CupertinoIcons.checkmark_circle_fill
                            : _isGameInProgress()
                                ? CupertinoIcons.play_circle_fill
                                : CupertinoIcons.clock_fill,
                        size: 16,
                        color: (_isGameCompleted() || _isGameInProgress()) 
                            ? Colors.white 
                            : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatGameStatus(),
                        style: TextStyle(
                          color: (_isGameCompleted() || _isGameInProgress()) 
                              ? Colors.white 
                              : const Color(0xFF4CAF50),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Teams Section with improved layout
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildPremiumTeamSection(false), // Away team
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'VS',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatGameDate(),
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildPremiumTeamSection(true), // Home team
                    ),
                  ],
                ),
                // Add venue information if available
                if (gameDetails != null && _getVenueInfo() != 'N/A') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.location,
                          size: 14,
                          color: Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _getVenueInfo(),
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTeamSection(bool isHome) {
    final teamName = _getESPNTeamName(widget.game, isHome);
    final logoPath = _getTeamLogoWithDebug(teamName);
    final score = _getTeamScore(isHome);
    final isWinner = _isGameCompleted() && int.tryParse(score) != null && 
                     int.tryParse(_getTeamScore(!isHome)) != null &&
                     int.parse(score) > int.parse(_getTeamScore(!isHome));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner 
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : const Color(0xFF4CAF50).withOpacity(0.1),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner ? [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Team Logo with better error handling
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: logoPath != null && logoPath.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: logoPath.endsWith('.svg')
                          ? SvgPicture.asset(
                              logoPath, 
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => _buildLogoFallback(),
                            )
                          : Image.asset(
                              logoPath, 
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _buildLogoFallback(),
                            ),
                    )
                  : _buildLogoFallback(),
            ),
          ),
          const SizedBox(height: 16),
          // Team Name with better layout
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            child: Text(
              _formatTeamNameForDisplay(teamName),
              style: TextStyle(
                color: isWinner ? const Color(0xFF4CAF50) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score (if game is completed or in progress)
          if (_isGameCompleted() || _isGameInProgress()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isWinner 
                    ? const Color(0xFF4CAF50).withOpacity(0.15)
                    : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWinner 
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : const Color(0xFF4CAF50).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                score,
                style: TextStyle(
                  color: isWinner ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E7),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
          // Winner indicator
          if (isWinner) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'WINNER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumGameScore() {
    if (!_isGameCompleted() && !_isGameInProgress()) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Score Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.sportscourt_fill,
                        size: 20,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isGameInProgress() ? 'LIVE SCORE' : 'FINAL SCORE',
                      style: TextStyle(
                        color: _isGameInProgress() ? const Color(0xFF4CAF50) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_isGameInProgress()) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                // Score Display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPremiumScoreDisplay(false), // Away team
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '-',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      _buildPremiumScoreDisplay(true), // Home team
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumScoreDisplay(bool isHome) {
    final score = _getTeamScore(isHome);
    final teamName = _getESPNTeamName(widget.game, isHome);
    final isWinner = _isGameCompleted() && int.tryParse(score) != null && 
                     int.tryParse(_getTeamScore(!isHome)) != null &&
                     int.parse(score) > int.parse(_getTeamScore(!isHome));
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isWinner 
                ? const Color(0xFF4CAF50).withOpacity(0.15)
                : const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWinner 
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            score,
            style: TextStyle(
              color: isWinner ? const Color(0xFF4CAF50) : Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          teamName,
          style: TextStyle(
            color: isWinner ? const Color(0xFF4CAF50) : const Color(0xFFE5E5E7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPremiumOddsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Odds Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_alt_fill,
                        size: 20,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Betting Odds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Odds Content
                if (fanDuelOdds != null)
                  _buildFanDuelOddsContent()
                else
                  _buildNoOddsAvailable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFanDuelOddsContent() {
    final bookmaker = fanDuelOdds!['bookmakers']?.firstWhere(
      (book) => book['key'] == 'fanduel',
      orElse: () => null,
    );

    if (bookmaker == null) {
      return _buildNoOddsAvailable();
    }

    return Column(
      children: [
        _buildPremiumOddsMarket(bookmaker, 'h2h', 'Moneyline', CupertinoIcons.money_dollar_circle),
        const SizedBox(height: 16),
        _buildPremiumOddsMarket(bookmaker, 'spreads', 'Point Spread', CupertinoIcons.chart_bar),
        const SizedBox(height: 16),
        _buildPremiumOddsMarket(bookmaker, 'totals', 'Over/Under', CupertinoIcons.arrow_up_arrow_down),
      ],
    );
  }

  Widget _buildNoOddsAvailable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.info_circle,
              size: 32,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Odds Not Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Betting odds are not available for this game',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOddsMarket(Map<String, dynamic> bookmaker, String marketKey, String marketName, IconData icon) {
    final markets = bookmaker['markets'] as List<dynamic>?;
    if (markets == null) return const SizedBox();

    final market = markets.firstWhere(
      (m) => m['key'] == marketKey,
      orElse: () => null,
    );

    if (market == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                marketName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: (market['outcomes'] as List<dynamic>).map<Widget>((outcome) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF45A049),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatOutcomeName(outcome['name']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatOdds(outcome['price']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    if (gameDetails == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF616161),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('League', _getLeagueInfo()),
          _buildInfoRow('Season', _getSeasonInfo()),
          _buildInfoRow('Week', _getWeekInfo()),
          _buildInfoRow('Venue', _getVenueInfo()),
        ],
      ),
    );
  }

  Widget _buildTeamRosters() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF616161),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Team Rosters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (isLoadingRosters)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CupertinoActivityIndicator(
                  color: Color(0xFF4CAF50),
                ),
              ),
            )
          else if (teamRosters != null)
            Material(
              color: Colors.transparent,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF424242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        tabs: [
                          Tab(text: _getESPNTeamName(widget.game, false)), // Away team
                          Tab(text: _getESPNTeamName(widget.game, true)),  // Home team
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 400, // Fixed height for roster display
                      child: TabBarView(
                        children: [
                          _buildRosterList(teamRosters!['away'] ?? []),
                          _buildRosterList(teamRosters!['home'] ?? []),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.person_3,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                  'Roster information not available',
                  style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                    decoration: TextDecoration.none,
                    ),
                ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRosterList(List<Map<String, dynamic>> roster) {
    if (roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_3,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No roster data available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roster.length,
      itemBuilder: (context, index) {
        final player = roster[index];
        return _buildPlayerCard(player);
      },
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final jerseyNumber = player['jerseyNumber'] ?? '';
    final name = player['name'] ?? 'Unknown';
    final position = player['position'] ?? 'N/A';
    final height = player['height'] ?? '';
    final weight = player['weight'] ?? '';
    final age = player['age'] ?? '';
    final headshot = player['headshot'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Player headshot or jersey number
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(25),
            ),
            child: headshot.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      headshot,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildJerseyNumberWidget(jerseyNumber);
                      },
                    ),
                  )
                : _buildJerseyNumberWidget(jerseyNumber),
          ),
          const SizedBox(width: 12),
          // Player information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  position,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (height.isNotEmpty || weight.isNotEmpty || age.isNotEmpty)
                  const SizedBox(height: 4),
                if (height.isNotEmpty || weight.isNotEmpty || age.isNotEmpty)
                  Text(
                    [height, weight, age.isNotEmpty ? '${age}y' : '']
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJerseyNumberWidget(String jerseyNumber) {
    return Center(
      child: Text(
        jerseyNumber.isNotEmpty ? '#$jerseyNumber' : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isGameCompleted() {
    final status = widget.game['status'];
    return status != null && status['type'] != null && status['type']['completed'] == true;
  }

  bool _isGameInProgress() {
    final status = widget.game['status'];
    return status != null && status['type'] != null && status['type']['state'] == 'in';
  }

  String _formatGameStatus() {
    final status = widget.game['status'];
    if (status == null) return 'Scheduled';
    
    final type = status['type'];
    if (type == null) return 'Scheduled';
    
    if (type['completed'] == true) {
      return 'Final';
    } else if (type['state'] == 'in') {
      return 'Live';
    } else {
      return 'Scheduled';
    }
  }

  String _formatGameDate() {
    final gameTime = DateTime.parse(widget.game['date']).toLocal();
    final hour = gameTime.hour > 12 ? gameTime.hour - 12 : (gameTime.hour == 0 ? 12 : gameTime.hour);
    final minute = gameTime.minute.toString().padLeft(2, '0');
    final period = gameTime.hour >= 12 ? 'PM' : 'AM';
    return '${gameTime.month}/${gameTime.day}/${gameTime.year} $hour:$minute $period';
  }

  String _getTeamScore(bool isHome) {
    final competitions = widget.game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return '0';
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return '0';
    }

    final team = competitors.firstWhere(
      (comp) => comp['homeAway'] == (isHome ? 'home' : 'away'),
      orElse: () => competitors[isHome ? 0 : 1],
    );

    return team['score']?.toString() ?? '0';
  }

  String _getLeagueInfo() {
    return gameDetails?['header']?['league']?['name'] ?? 'N/A';
  }

  String _getSeasonInfo() {
    return gameDetails?['header']?['season']?['year']?.toString() ?? 'N/A';
  }

  String _getWeekInfo() {
    return gameDetails?['header']?['week']?.toString() ?? 'N/A';
  }

  String _getVenueInfo() {
    final venue = gameDetails?['gameInfo']?['venue'];
    if (venue == null) return 'N/A';
    return venue['fullName'] ?? venue['name'] ?? 'N/A';
  }

  String _formatOutcomeName(String name) {
    // Shorten team names for display
    return name.length > 15 ? name.substring(0, 15) + '...' : name;
  }

  String _formatOdds(dynamic price) {
    if (price == null) return 'N/A';
    final odds = price is int ? price : int.tryParse(price.toString()) ?? 0;
    return odds > 0 ? '+$odds' : '$odds';
  }

  // Helper method to get team logo with debugging
  String? _getTeamLogoWithDebug(String teamName) {
    final logoPath = TeamLogoUtils.getTeamLogo(teamName);
    print('Team: $teamName -> Logo: $logoPath'); // Debug logging
    return logoPath;
  }

  // Helper method to build logo fallback
  Widget _buildLogoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF4CAF50).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        CupertinoIcons.sportscourt,
        size: 32,
        color: Color(0xFF4CAF50),
      ),
    );
  }

  // Helper method to format team names for better display
  String _formatTeamNameForDisplay(String teamName) {
    if (teamName.isEmpty) return 'Team';
    
    // Handle common abbreviations and formatting
    if (teamName.length > 20) {
      // For very long names, try to use a shorter version
      final parts = teamName.split(' ');
      if (parts.length > 2) {
        return '${parts.first} ${parts.last}';
      }
    }
    
    return teamName;
  }
} 