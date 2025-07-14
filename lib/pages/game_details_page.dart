import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../utils/team_logo_utils.dart';

class GameDetailsPage extends StatefulWidget {
  final dynamic game; // ESPN game object
  final String sport; // Sport key for API calls
  
  const GameDetailsPage({Key? key, required this.game, required this.sport}) : super(key: key);
  
  @override
  _GameDetailsPageState createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage> {
  Map<String, dynamic>? gameDetails;
  Map<String, dynamic>? fanDuelOdds;
  bool isLoading = true;
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

      // Load both ESPN game details and FanDuel odds in parallel
      final results = await Future.wait([
        _fetchESPNGameDetails(),
        _fetchFanDuelOdds(),
      ]);
      
      setState(() {
        gameDetails = results[0];
        fanDuelOdds = results[1];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load game details';
        isLoading = false;
      });
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
      final dateStart = DateTime(gameDate.year, gameDate.month, gameDate.day);
      final dateEnd = dateStart.add(const Duration(days: 1));
      
      final commenceTimeFrom = dateStart.toUtc().toIso8601String();
      final commenceTimeTo = dateEnd.toUtc().toIso8601String();
      
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

    return team['team']['displayName'] ?? team['team']['name'] ?? '';
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
      backgroundColor: const Color(0xFF424242),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF424242),
        border: null,
        leading: CupertinoNavigationBarBackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text(
          'Game Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(
                  color: Color(0xFF4CAF50),
                  radius: 20,
                ),
              )
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.destructiveRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          color: const Color(0xFF4CAF50),
                          onPressed: _loadGameDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildGameHeader(),
                        _buildGameScore(),
                        _buildFanDuelOdds(),
                        _buildGameStats(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF616161),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Game status and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isGameCompleted() 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF757575),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatGameStatus(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatGameDate(),
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamHeader(true),
              Column(
                children: [
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (gameDetails != null)
                    Text(
                      _getVenueInfo(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
              _buildTeamHeader(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(bool isHome) {
    final teamName = _getESPNTeamName(widget.game, isHome);
    final logoPath = TeamLogoUtils.getTeamLogo(teamName);
    
    return Column(
      children: [
        if (logoPath != null && logoPath.isNotEmpty)
          Container(
            width: 60,
            height: 60,
            child: logoPath.endsWith('.svg')
                ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                : Image.asset(logoPath, fit: BoxFit.contain),
          ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGameScore() {
    if (!_isGameCompleted() && !_isGameInProgress()) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF616161),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'SCORE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreDisplay(true),
              const Text(
                '-',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildScoreDisplay(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(bool isHome) {
    final score = _getTeamScore(isHome);
    final teamName = _getESPNTeamName(widget.game, isHome);
    
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          teamName,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFanDuelOdds() {
    if (fanDuelOdds == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF616161),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.info_circle,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'FanDuel odds not available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final bookmaker = fanDuelOdds!['bookmakers']?.firstWhere(
      (book) => book['key'] == 'fanduel',
      orElse: () => null,
    );

    if (bookmaker == null) {
      return const SizedBox();
    }

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
            'FanDuel Odds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOddsMarket(bookmaker, 'h2h', 'Moneyline'),
          _buildOddsMarket(bookmaker, 'spreads', 'Point Spread'),
          _buildOddsMarket(bookmaker, 'totals', 'Over/Under'),
        ],
      ),
    );
  }

  Widget _buildOddsMarket(Map<String, dynamic> bookmaker, String marketKey, String marketName) {
    final markets = bookmaker['markets'] as List<dynamic>?;
    if (markets == null) return const SizedBox();

    final market = markets.firstWhere(
      (m) => m['key'] == marketKey,
      orElse: () => null,
    );

    if (market == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            marketName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: (market['outcomes'] as List<dynamic>).map<Widget>((outcome) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatOutcomeName(outcome['name']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatOdds(outcome['price']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
} 