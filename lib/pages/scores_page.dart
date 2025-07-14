import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../utils/team_logo_utils.dart';

class ScoresPage extends StatefulWidget {
  @override
  _ScoresPageState createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  List<dynamic> scores = [];
  String selectedSport = 'americanfootball_nfl';
  bool isLoading = true;
  String? error;

  final Map<String, String> sportsMap = {
    'americanfootball_nfl': 'NFL',
    'basketball_nba': 'NBA',
    'baseball_mlb': 'MLB',
    'icehockey_nhl': 'NHL',
  };

  // Helper method to get league logo path
  String getLeagueLogoPath(String sportKey) {
    final Map<String, String> leagueLogos = {
      'americanfootball_nfl': 'assets/leagueLogos/nfl.png',
      'basketball_nba': 'assets/leagueLogos/nba.png',
      'baseball_mlb': 'assets/leagueLogos/mlb.png',
      'icehockey_nhl': 'assets/leagueLogos/nhl.png',
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

    try {
      final response = await http.get(Uri.parse(
          'https://api.the-odds-api.com/v4/sports/$selectedSport/scores?apiKey=d759f3f3cec2c2aaf1f987c54a0d4a13&daysFrom=2'));

      if (response.statusCode == 200) {
        setState(() {
          scores = json.decode(response.body);
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

  Widget buildTeamInfo(String teamName, bool isHome) {
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
    if (game['completed']) {
      return 'Final';
    } else if (game['commence_time'] != null) {
      final gameTime = DateTime.parse(game['commence_time']).toLocal();
      // Format in 12-hour format
      final hour = gameTime.hour > 12 ? gameTime.hour - 12 : (gameTime.hour == 0 ? 12 : gameTime.hour);
      final minute = gameTime.minute.toString().padLeft(2, '0');
      final period = gameTime.hour >= 12 ? 'PM' : 'AM';
      return '${gameTime.month}/${gameTime.day} $hour:$minute $period';
    }
    return '';
  }

  String formatScore(dynamic game) {
    // First check if the game object exists
    if (game == null) {
      return '-';
    }

    // Check for scores field
    final scores = game['scores'];
    if (scores == null || !(scores is List) || scores.length < 2) {
      return '-';
    }

    // Safely access the scores
    final homeScore = scores[0]['score']?.toString() ?? '0';
    final awayScore = scores[1]['score']?.toString() ?? '0';

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
            // Sports Filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ? const Color(0xFF4CAF50) // Same green as Colors.green
                          : const Color(0xFF616161), // Same as Colors.grey[700]
                      onPressed: () {
                        setState(() {
                          selectedSport = entry.key;
                          fetchScores();
                        });
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
                              color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
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

            // Scores List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: Color(0xFF4CAF50), // Same green
                        radius: 15,
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
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              CupertinoButton(
                                color: const Color(0xFF4CAF50),
                                onPressed: fetchScores,
                                child: const Text('Retry'),
                              ),
                            ],
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
                                            CupertinoIcons.game_controller,
                                            color: Colors.grey[400],
                                            size: 64,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No scores available',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Pull down to refresh',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final game = scores[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF616161), // Same as Colors.grey[700]
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: game['completed'] 
                        ? const Color(0xFF4CAF50) // Green for completed games
                        : const Color(0xFF616161), // Gray for upcoming games
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formatGameStatus(game),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (game['completed'])
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  )
                else
                  Icon(
                    CupertinoIcons.clock,
                    color: const Color(0xFF616161), // Gray instead of blue
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Teams and Score Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildTeamInfo(game['home_team'] ?? '', true),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242), // Darker background for score
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formatScore(game),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                buildTeamInfo(game['away_team'] ?? '', false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
