import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:ui';
import '../utils/team_logo_utils.dart';
import 'game_details_page.dart';

enum GameTimeFilter { today, upcoming }

class ScoresPage extends StatefulWidget {
  @override
  _ScoresPageState createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  List<dynamic> scores = [];
  String selectedSport = 'football/nfl';
  bool isLoading = true;
  String? error;
  GameTimeFilter selectedTimeFilter = GameTimeFilter.today;

  final Map<String, String> sportsMap = {
    'football/nfl': 'NFL',
    'basketball/nba': 'NBA',
    'baseball/mlb': 'MLB',
    'hockey/nhl': 'NHL',
  };

  // Helper method to get league logo path
  String getLeagueLogoPath(String sportKey) {
    final Map<String, String> leagueLogos = {
      'football/nfl': 'assets/leagueLogos/nfl.png',
      'basketball/nba': 'assets/leagueLogos/nba.png',
      'baseball/mlb': 'assets/leagueLogos/mlb.png',
      'hockey/nhl': 'assets/leagueLogos/nhl.png',
    };
    return leagueLogos[sportKey] ?? '';
  }

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    switch (selectedTimeFilter) {
      case GameTimeFilter.today:
        await fetchTodayGames();
        break;
      case GameTimeFilter.upcoming:
        await fetchUpcomingGames();
        break;
    }
  }

  Future<void> fetchTodayGames() async {
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Format dates for ESPN API (YYYYMMDD)
      final todayFormatted = today.toIso8601String().split('T')[0].replaceAll('-', '');
      final yesterdayFormatted = yesterday.toIso8601String().split('T')[0].replaceAll('-', '');
      
      final response = await http.get(Uri.parse(
          'https://site.api.espn.com/apis/site/v2/sports/$selectedSport/scoreboard?dates=$yesterdayFormatted-$todayFormatted'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] ?? [];
        print('ESPN API Today Response: Found ${events.length} events');
        setState(() {
          scores = events;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load scores';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to the server';
        isLoading = false;
      });
    }
  }



  Future<void> fetchUpcomingGames() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final futureDate = tomorrow.add(const Duration(days: 7)); // Next 7 days from tomorrow
      
      // Format dates for ESPN API (YYYYMMDD)
      final tomorrowFormatted = tomorrow.toIso8601String().split('T')[0].replaceAll('-', '');
      final futureFormatted = futureDate.toIso8601String().split('T')[0].replaceAll('-', '');

      final response = await http.get(Uri.parse(
          'https://site.api.espn.com/apis/site/v2/sports/$selectedSport/scoreboard?dates=$tomorrowFormatted-$futureFormatted'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] ?? [];
        
        // Filter out completed games and only show upcoming
        final upcomingGames = events.where((game) {
          final status = game['status'];
          if (status == null || status['type'] == null) return true;
          return status['type']['state'] == 'pre'; // Only pre-game status
        }).toList();
        
        print('ESPN API Upcoming Response: Found ${upcomingGames.length} upcoming games');
        setState(() {
          scores = upcomingGames;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load upcoming games';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to the server';
        isLoading = false;
      });
    }
  }

  Widget _buildTeamInfoFromCompetition(dynamic game, bool isHome) {
    final competitions = game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return const Expanded(child: SizedBox());
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return const Expanded(child: SizedBox());
    }

    // Find the appropriate team (home or away)
    final team = competitors.firstWhere(
      (comp) => comp['homeAway'] == (isHome ? 'home' : 'away'),
      orElse: () => competitors[isHome ? 0 : 1],
    );

    final teamName = team['team']['displayName'] ?? team['team']['name'] ?? '';
    final logoPath = TeamLogoUtils.getTeamLogo(teamName);

    return Expanded(
      child: Row(
        mainAxisAlignment:
            isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome)
            Expanded(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          if (logoPath != null && logoPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: logoPath.endsWith('.svg')
                  ? SvgPicture.asset(
                      logoPath,
                      height: 30,
                      width: 30,
                    )
                  : Image.asset(
                      logoPath,
                      height: 30,
                      width: 30,
                      fit: BoxFit.contain,
                    ),
            ),
          if (isHome)
            Expanded(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String formatGameStatus(dynamic game) {
    final status = game['status'];
    if (status == null) return '';
    
    final type = status['type'];
    if (type == null) return '';
    
    // Check if game is completed
    if (type['completed'] == true) {
      return 'Final';
    } else if (type['state'] == 'in') {
      // Game is in progress
      final displayClock = status['displayClock'];
      final period = status['period'];
      if (displayClock != null && period != null) {
        return '$displayClock Q$period';
      }
      return 'Live';
    } else {
      // Game is scheduled
      final gameTime = DateTime.parse(game['date']).toLocal();
      final hour = gameTime.hour > 12 ? gameTime.hour - 12 : (gameTime.hour == 0 ? 12 : gameTime.hour);
      final minute = gameTime.minute.toString().padLeft(2, '0');
      final period = gameTime.hour >= 12 ? 'PM' : 'AM';
      return '${gameTime.month}/${gameTime.day} $hour:$minute $period';
    }
  }

  bool _isGameCompleted(dynamic game) {
    final status = game['status'];
    if (status == null || status['type'] == null) return false;
    return status['type']['completed'] == true;
  }

  String _getEmptyStateMessage() {
    switch (selectedTimeFilter) {
      case GameTimeFilter.today:
        return 'No scores available';
      case GameTimeFilter.upcoming:
        return 'No upcoming games found';
    }
  }

  Widget _buildTimeFilterButton(String label, GameTimeFilter filter) {
    final isSelected = selectedTimeFilter == filter;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          onPressed: () {
            setState(() {
              selectedTimeFilter = filter;
            });
            fetchScores();
          },
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4CAF50),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  String formatScore(dynamic game) {
    // First check if the game object exists
    if (game == null) {
      return '-';
    }

    final competitions = game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return (selectedTimeFilter == GameTimeFilter.upcoming) ? 'vs' : '-';
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return (selectedTimeFilter == GameTimeFilter.upcoming) ? 'vs' : '-';
    }

    // Find home and away teams
    final homeTeam = competitors.firstWhere(
      (comp) => comp['homeAway'] == 'home',
      orElse: () => competitors[0],
    );
    final awayTeam = competitors.firstWhere(
      (comp) => comp['homeAway'] == 'away',
      orElse: () => competitors[1],
    );

    final homeScore = homeTeam['score']?.toString() ?? '0';
    final awayScore = awayTeam['score']?.toString() ?? '0';

    // Check if game has started
    final status = game['status'];
    if (status != null && status['type'] != null) {
      final gameState = status['type']['state'];
      if (gameState == 'pre') {
        return 'vs';
      }
    }

    return '$homeScore - $awayScore';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF424242), // Same gray background as Colors.grey[800]
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF424242), // Same gray background
        border: null, // Remove default border
        middle: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Time Filter Buttons - Enhanced with blur effect
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF525252).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTimeFilterButton('Today', GameTimeFilter.today),
                        _buildTimeFilterButton('Upcoming', GameTimeFilter.upcoming),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sports Filter - Enhanced with blur effect
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF525252).withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sportsMap.entries.length,
                      itemBuilder: (context, index) {
                        final entry = sportsMap.entries.elementAt(index);
                        final isSelected = selectedSport == entry.key;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected 
                                ? const Color(0xFF4CAF50)
                                : Colors.transparent,
                            onPressed: () {
                              setState(() {
                                selectedSport = entry.key;
                              });
                              fetchScores();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  getLeagueLogoPath(entry.key),
                                  height: 20,
                                  width: 20,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : const Color(0xFF4CAF50),
                                    fontWeight: isSelected 
                                        ? FontWeight.w600 
                                        : FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Scores List with enhanced styling
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                            color: Color(0xFF4CAF50),
                            radius: 20,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading ${sportsMap[selectedSport]} scores...',
                            style: const TextStyle(
                              color: Color(0xFFBDBDBD),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF525252),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: CupertinoColors.destructiveRed.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  size: 48,
                                  color: CupertinoColors.destructiveRed,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Unable to load scores',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error!,
                                  style: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                CupertinoButton(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: fetchScores,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            CupertinoSliverRefreshControl(
                              onRefresh: fetchScores,
                            ),
                            scores.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.sportscourt,
                                            size: 64,
                                            color: const Color(0xFF4CAF50).withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No games found',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getEmptyStateMessage(),
                                            style: const TextStyle(
                                              color: Color(0xFFBDBDBD),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final game = scores[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _buildScoreCard(game),
                                          );
                                        },
                                        childCount: scores.length,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(dynamic game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => GameDetailsPage(
              game: game,
              sport: selectedSport,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF525252),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Status Row with enhanced styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isGameCompleted(game) 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isGameCompleted(game)
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF4CAF50).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      formatGameStatus(game),
                      style: TextStyle(
                        color: _isGameCompleted(game) ? Colors.white : const Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isGameCompleted(game)
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isGameCompleted(game)
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.clock,
                      color: _isGameCompleted(game)
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF4CAF50).withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Teams and Score Row with enhanced styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTeamInfoFromCompetition(game, true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      formatScore(game),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildTeamInfoFromCompetition(game, false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
