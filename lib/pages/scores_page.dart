import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:wagerloop1/utils/team_logo_utils.dart'; // Update this import to match your app name

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
    final logoPath = TeamLogoUtils.getLogoPath(teamName, selectedSport);

    return Expanded(
      child: Row(
        mainAxisAlignment:
            isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isHome)
            Expanded(
              child: Text(
                teamName,
                style: TextStyle(
                  color: Colors.white, // Changed from grey to white
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          if (logoPath.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
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
                style: TextStyle(
                  color: Colors.white, // Changed from grey to white
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
      final gameTime = DateTime.parse(game['commence_time']);
      return '${gameTime.month}/${gameTime.day} ${gameTime.hour}:${gameTime.minute.toString().padLeft(2, '0')}';
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
    return Scaffold(
      backgroundColor: Colors.grey[800], // Add gray background
      appBar: AppBar(
        title: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40, // Adjust height as needed
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[800], // Match background
      ),
      body: Column(
        children: [
          // Sports Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: sportsMap.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: selectedSport == entry.key,
                          label: Row(
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
                                  color: selectedSport == entry.key ? Colors.white : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          selectedColor: Colors.green, // Green background when selected
                          backgroundColor: Colors.grey[700], // Dark gray background when unselected
                          onSelected: (bool selected) {
                            setState(() {
                              selectedSport = entry.key;
                              fetchScores();
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Scores List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : error != null
                    ? Center(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchScores,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: scores.length,
                          itemBuilder: (context, index) {
                            final game = scores[index];
                            return Card(
                              color: Colors.grey[700], // Dark gray card background
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatGameStatus(game),
                                      style: TextStyle(
                                        color: Colors.white, // Changed from gray to white
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        buildTeamInfo(
                                            game['home_team'] ?? '', true),
                                        Text(
                                          formatScore(game),
                                          style: const TextStyle(
                                            color: Colors.white, // Changed from black to white
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        buildTeamInfo(
                                            game['away_team'] ?? '', false),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
