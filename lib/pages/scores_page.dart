import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:ui';
import '../utils/team_logo_utils.dart';
import 'game_details_page.dart';

class ScoresPage extends StatefulWidget {
  @override
  _ScoresPageState createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  Map<String, List<dynamic>> allScores = {};
  Map<String, bool> sportLoading = {};
  Map<String, String?> sportErrors = {};
  Map<String, bool> sportExpanded = {};
  Map<String, String> selectedGameType = {};
  bool isLoading = true;

  final Map<String, String> sportsMap = {
    'football/nfl': 'NFL',
    'basketball/nba': 'NBA',
    'basketball/nba-summer-las-vegas': 'NBA Summer',
    'baseball/mlb': 'MLB',
    'hockey/nhl': 'NHL',
    'mma/ufc': 'UFC',
  };

  // Helper method to get league logo path
  String getLeagueLogoPath(String sportKey) {
    final Map<String, String> leagueLogos = {
      'football/nfl': 'assets/leagueLogos/nfl.png',
      'basketball/nba': 'assets/leagueLogos/nba.png',
      'basketball/nba-summer-las-vegas': 'assets/leagueLogos/nba.png',
      'baseball/mlb': 'assets/leagueLogos/mlb.png',
      'hockey/nhl': 'assets/leagueLogos/nhl.png',
      'mma/ufc': 'assets/leagueLogos/UFC_Logo.svg',
    };
    return leagueLogos[sportKey] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _initializeSports();
    fetchAllScores();
  }

  void _initializeSports() {
    for (String sport in sportsMap.keys) {
      allScores[sport] = [];
      sportLoading[sport] = false;
      sportErrors[sport] = null;
      sportExpanded[sport] = false;
      selectedGameType[sport] = 'all';
    }
  }

  Future<void> fetchAllScores() async {
    setState(() {
      isLoading = true;
    });

    // Fetch scores for all sports in parallel
    await Future.wait(
      sportsMap.keys.map((sport) => fetchSportScores(sport)),
    );

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSportScores(String sport) async {
    setState(() {
      sportLoading[sport] = true;
      sportErrors[sport] = null;
    });

    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      
      // Format dates for ESPN API (YYYYMMDD)
      final yesterdayFormatted = yesterday.toIso8601String().split('T')[0].replaceAll('-', '');
      final tomorrowFormatted = tomorrow.toIso8601String().split('T')[0].replaceAll('-', '');
      
      final response = await http.get(Uri.parse(
          'https://site.api.espn.com/apis/site/v2/sports/$sport/scoreboard?dates=$yesterdayFormatted-$tomorrowFormatted'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] ?? [];
        
        setState(() {
          allScores[sport] = events;
          sportLoading[sport] = false;
        });
      } else {
        setState(() {
          sportErrors[sport] = 'Failed to load scores';
          sportLoading[sport] = false;
        });
      }
    } catch (e) {
      setState(() {
        sportErrors[sport] = 'Error connecting to server';
        sportLoading[sport] = false;
      });
    }
  }

  List<dynamic> getLiveGames(String sport) {
    final games = allScores[sport] ?? [];
    return games.where((game) {
      final status = game['status'];
      if (status == null || status['type'] == null) return false;
      return status['type']['state'] == 'in';
    }).toList();
  }

  List<dynamic> getUpcomingGames(String sport) {
    final games = allScores[sport] ?? [];
    final now = DateTime.now();
    final twelveHoursFromNow = now.add(const Duration(hours: 12));
    
    return games.where((game) {
      final status = game['status'];
      if (status == null || status['type'] == null) return false;
      
      // Only include games that are scheduled/pre-game
      if (status['type']['state'] != 'pre') return false;
      
      // Check if game is within the next 12 hours
      try {
        final gameTime = DateTime.parse(game['date']).toLocal();
        return gameTime.isAfter(now) && gameTime.isBefore(twelveHoursFromNow);
      } catch (e) {
        // If we can't parse the date, exclude the game
        return false;
      }
    }).toList();
  }

  List<dynamic> getTodayGames(String sport) {
    final games = allScores[sport] ?? [];
    return games.where((game) {
      final status = game['status'];
      if (status == null || status['type'] == null) return false;
      return status['type']['completed'] == true;
    }).toList();
  }

  bool hasAnyGames(String sport) {
    final games = allScores[sport] ?? [];
    return games.isNotEmpty;
  }

  bool hasLiveGames(String sport) {
    return getLiveGames(sport).isNotEmpty;
  }

  List<dynamic> getFilteredGames(String sport) {
    final gameType = selectedGameType[sport] ?? 'all';
    switch (gameType) {
      case 'live':
        return getLiveGames(sport);
      case 'upcoming':
        return getUpcomingGames(sport);
      case 'today':
        return getTodayGames(sport);
      default:
        return allScores[sport] ?? [];
    }
  }

  Widget _buildTeamInfoFromCompetition(dynamic game, bool isHome) {
    final competitions = game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return const Flexible(child: SizedBox());
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return const Flexible(child: SizedBox());
    }

    // Find the appropriate team (home or away)
    final team = competitors.firstWhere(
      (comp) => comp['homeAway'] == (isHome ? 'home' : 'away'),
      orElse: () => competitors[isHome ? 0 : 1],
    );

    final teamInfo = team['team'] ?? team['athlete'] ?? {};
    final teamName = teamInfo['displayName'] ?? teamInfo['name'] ?? teamInfo['shortName'] ?? '';
    final logoPath = (team['team'] != null) ? TeamLogoUtils.getTeamLogo(teamName) : null; // Skip logo for non-team sports like UFC

    return Flexible(
      child: Row(
        mainAxisAlignment:
            isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome)
            Flexible(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          if (logoPath != null && logoPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: logoPath.endsWith('.svg')
                  ? SvgPicture.asset(
                      logoPath,
                      height: 24,
                      width: 24,
                    )
                  : Image.asset(
                      logoPath,
                      height: 24,
                      width: 24,
                      fit: BoxFit.contain,
                    ),
            ),
          if (isHome)
            Flexible(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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

  bool _isGameLive(dynamic game) {
    final status = game['status'];
    if (status == null || status['type'] == null) return false;
    return status['type']['state'] == 'in';
  }

  String _getEmptyStateMessage(String sport) {
    if (sportLoading[sport] == true) {
      return 'Loading ${sportsMap[sport]} games...';
    } else if (sportErrors[sport] != null) {
      return 'Failed to load ${sportsMap[sport]} games';
    } else {
      return 'No games found for ${sportsMap[sport]}';
    }
  }

  String _getLoadingMessage() {
    return 'Loading games...';
  }



  String formatScore(dynamic game) {
    // First check if the game object exists
    if (game == null) {
      return '-';
    }

    final competitions = game['competitions'];
    if (competitions == null || !(competitions is List) || competitions.isEmpty) {
      return '-';
    }

    final competition = competitions[0];
    final competitors = competition['competitors'];
    if (competitors == null || !(competitors is List) || competitors.length < 2) {
      return '-';
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
      backgroundColor: const Color(0xFF424242),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF424242),
        border: null,
        middle: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: fetchAllScores,
          child: const Icon(
            CupertinoIcons.refresh,
            color: Color(0xFF4CAF50),
          ),
        ),
      ),
      child: SafeArea(
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
                      'Loading all sports...',
                      style: const TextStyle(
                        color: Color(0xFFBDBDBD),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: fetchAllScores,
                  ),
                  // Quick Stats Header
                  SliverToBoxAdapter(
                    child: _buildQuickStatsHeader(),
                  ),
                  // Sports Sections
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sport = sportsMap.keys.elementAt(index);
                          return _buildSportSection(sport);
                        },
                        childCount: sportsMap.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickStatsHeader() {
    int totalLiveGames = 0;
    int totalUpcomingGames = 0;
    
    for (String sport in sportsMap.keys) {
      totalLiveGames += getLiveGames(sport).length;
      totalUpcomingGames += getUpcomingGames(sport).length;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF525252).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'LIVE NOW',
            totalLiveGames.toString(),
            const Color(0xFFFF5722),
            CupertinoIcons.antenna_radiowaves_left_right,
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
          _buildStatCard(
            'NEXT 12H',
            totalUpcomingGames.toString(),
            const Color(0xFF4CAF50),
            CupertinoIcons.clock,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSportSection(String sport) {
    final sportName = sportsMap[sport]!;
    final liveGames = getLiveGames(sport);
    final upcomingGames = getUpcomingGames(sport);
    final todayGames = getTodayGames(sport);
    final hasGames = hasAnyGames(sport);
    final isLoading = sportLoading[sport] ?? false;
    final error = sportErrors[sport];
    final isExpanded = sportExpanded[sport] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF525252).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLiveGames(sport)
              ? const Color(0xFFFF5722).withOpacity(0.3)
              : const Color(0xFF4CAF50).withOpacity(0.1),
          width: hasLiveGames(sport) ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Collapsible Header
          GestureDetector(
            onTap: () {
              setState(() {
                sportExpanded[sport] = !(sportExpanded[sport] ?? false);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  getLeagueLogoPath(sport).isNotEmpty
                      ? (getLeagueLogoPath(sport).endsWith('.svg')
                          ? SvgPicture.asset(
                              getLeagueLogoPath(sport),
                              height: 28,
                              width: 28,
                              fit: BoxFit.contain,
                              colorFilter: hasGames ? null : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                            )
                          : Image.asset(
                              getLeagueLogoPath(sport),
                              height: 28,
                              width: 28,
                              fit: BoxFit.contain,
                              color: hasGames ? null : Colors.grey,
                            ))
                      : Container(
                          height: 28,
                          width: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            CupertinoIcons.sportscourt,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sportName,
                          style: TextStyle(
                            color: hasGames ? Colors.white : Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (hasGames)
                          Text(
                            '${getFilteredGames(sport).length} ${sport.contains('ufc') ? 'fights' : 'games'} available',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  if (hasLiveGames(sport))
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.antenna_radiowaves_left_right,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${liveGames.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: hasGames ? const Color(0xFF4CAF50) : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable Content
          if (isExpanded) ...[
            Container(
              height: 1,
              color: const Color(0xFF4CAF50).withOpacity(0.1),
            ),
            
            // Filter Tabs
            if (hasGames) _buildFilterTabs(sport),
            
            // Games Content
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildGamesContent(sport, isLoading, error, hasGames),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTabs(String sport) {
    final selectedType = selectedGameType[sport] ?? 'all';
    final liveCount = getLiveGames(sport).length;
    final upcomingCount = getUpcomingGames(sport).length;
    final todayCount = getTodayGames(sport).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(
              'All',
              'all',
              selectedType,
              (allScores[sport] ?? []).length,
              sport,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab(
              'Live',
              'live',
              selectedType,
              liveCount,
              sport,
              color: const Color(0xFFFF5722),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab(
              'Next 12H',
              'upcoming',
              selectedType,
              upcomingCount,
              sport,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterTab(
              'Today',
              'today',
              selectedType,
              todayCount,
              sport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value, String selected, int count, String sport, {Color? color}) {
    final isSelected = selected == value;
    final tabColor = color ?? const Color(0xFF4CAF50);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGameType[sport] = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? tabColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tabColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? tabColor : Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? tabColor : Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesContent(String sport, bool isLoading, String? error, bool hasGames) {
    if (isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }
    
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.destructiveRed.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.destructiveRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 14,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => fetchSportScores(sport),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (!hasGames) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No games available',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    final filteredGames = getFilteredGames(sport);
    if (filteredGames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No games in this category',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: filteredGames.map((game) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildScoreCard(game, sport),
      )).toList(),
    );
  }



  Widget _buildScoreCard(dynamic game, String sport) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => GameDetailsPage(
              game: game,
              sport: sport,
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
            color: _isGameLive(game)
                ? const Color(0xFFFF5722).withOpacity(0.6)
                : const Color(0xFF4CAF50).withOpacity(0.1),
            width: _isGameLive(game) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isGameLive(game)
                  ? const Color(0xFFFF5722).withOpacity(0.3)
                  : Colors.black.withOpacity(0.15),
              blurRadius: _isGameLive(game) ? 8 : 12,
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
                      color: _isGameLive(game)
                          ? const Color(0xFFFF5722)
                          : _isGameCompleted(game) 
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isGameLive(game)
                            ? const Color(0xFFFF5722)
                            : _isGameCompleted(game)
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF4CAF50).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      formatGameStatus(game),
                      style: TextStyle(
                        color: _isGameLive(game) 
                            ? Colors.white 
                            : _isGameCompleted(game) 
                                ? Colors.white 
                                : const Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isGameLive(game)
                          ? const Color(0xFFFF5722).withOpacity(0.1)
                          : _isGameCompleted(game)
                              ? const Color(0xFF4CAF50).withOpacity(0.1)
                              : const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isGameLive(game)
                          ? CupertinoIcons.antenna_radiowaves_left_right
                          : _isGameCompleted(game)
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.clock,
                      color: _isGameLive(game)
                          ? const Color(0xFFFF5722)
                          : _isGameCompleted(game)
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
                    width: 100,  // Fixed width for score
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
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
