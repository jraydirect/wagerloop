// Import Cupertino design components for iOS-style UI
import 'package:flutter/cupertino.dart';
// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import HTTP library for making API requests
import 'package:http/http.dart' as http;
// Import flutter_svg for SVG image support
import 'package:flutter_svg/flutter_svg.dart';
// Import dart:convert for JSON parsing
import 'dart:convert';
// Import team logo utilities for team logo paths
import '../utils/team_logo_utils.dart';

// ScoresPage class definition - a stateful widget for displaying sports scores
class ScoresPage extends StatefulWidget {
  // Override createState method to return the state class instance
  @override
  _ScoresPageState createState() => _ScoresPageState();
}

// Private state class that manages the scores page's state and functionality
class _ScoresPageState extends State<ScoresPage> {
  // List to store fetched scores data
  List<dynamic> scores = [];
  // Currently selected sport (default to NFL)
  String selectedSport = 'americanfootball_nfl';
  // Boolean flag to track loading state
  bool isLoading = true;
  // String to store error message if any
  String? error;

  // Map of sport keys to display names
  final Map<String, String> sportsMap = {
    'americanfootball_nfl': 'NFL',
    'basketball_nba': 'NBA',
    'baseball_mlb': 'MLB',
    'icehockey_nhl': 'NHL',
  };

  // Helper method to get league logo path
  String getLeagueLogoPath(String sportKey) {
    // Map of sport keys to league logo paths
    final Map<String, String> leagueLogos = {
      'americanfootball_nfl': 'assets/leagueLogos/nfl.png',
      'basketball_nba': 'assets/leagueLogos/nba.png',
      'baseball_mlb': 'assets/leagueLogos/mlb.png',
      'icehockey_nhl': 'assets/leagueLogos/nhl.png',
    };
    // Return logo path or empty string if not found
    return leagueLogos[sportKey] ?? '';
  }

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Fetch scores on initialization
    fetchScores();
  }

  // Async method to fetch scores from the API
  Future<void> fetchScores() async {
    // Set loading state and clear error
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Make HTTP GET request to the odds API
      final response = await http.get(Uri.parse(
          'https://api.the-odds-api.com/v4/sports/$selectedSport/scores?apiKey=37a6ab2abd9938d21be970bb794eb6a3&daysFrom=2'));

      // Check if request was successful
      if (response.statusCode == 200) {
        // Parse JSON response and update state
        setState(() {
          scores = json.decode(response.body);
          isLoading = false;
        });
      } else {
        // Handle HTTP error
        setState(() {
          error = 'Failed to load scores';
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle network or parsing errors
      setState(() {
        error = 'Error connecting to the server';
        isLoading = false;
      });
    }
  }

  // Method to build team information widget
  Widget buildTeamInfo(String teamName, bool isHome) {
    // Get team logo path using utility function
    final logoPath = TeamLogoUtils.getTeamLogo(teamName);

    // Return expanded widget with team info
    return Expanded(
      child: Row(
        // Align based on home/away status
        mainAxisAlignment:
            isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // Show team name on left for away team
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
          // Show team logo if available
          if (logoPath != null && logoPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              // Handle SVG and regular images
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
          // Show team name on right for home team
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

  // Method to format game status text
  String formatGameStatus(dynamic game) {
    // Check if game is completed
    if (game['completed']) {
      return 'Final';
    } else if (game['commence_time'] != null) {
      // Parse and format game time
      final gameTime = DateTime.parse(game['commence_time']).toLocal();
      // Format in 12-hour format
      final hour = gameTime.hour > 12 ? gameTime.hour - 12 : (gameTime.hour == 0 ? 12 : gameTime.hour);
      final minute = gameTime.minute.toString().padLeft(2, '0');
      final period = gameTime.hour >= 12 ? 'PM' : 'AM';
      return '${gameTime.month}/${gameTime.day} $hour:$minute $period';
    }
    // Return empty string if no time available
    return '';
  }

  // Method to format score display
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

    // Return formatted score
    return '$homeScore - $awayScore';
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return Cupertino page scaffold for iOS-style design
    return CupertinoPageScaffold(
      // Same gray background as Colors.grey[800]
      backgroundColor: const Color(0xFF424242),
      // Cupertino navigation bar
      navigationBar: CupertinoNavigationBar(
        // Same gray background
        backgroundColor: const Color(0xFF424242),
        // Remove default border
        border: null,
        // App logo in center
        middle: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
      ),
      // Safe area body
      child: SafeArea(
        // Column to arrange main content
        child: Column(
          children: [
            // Sports Filter
            // Container for horizontal sports filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Horizontal list of sport filter buttons
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sportsMap.entries.length,
                // Builder function for each sport filter
                itemBuilder: (context, index) {
                  // Get sport entry at current index
                  final entry = sportsMap.entries.elementAt(index);
                  // Check if this sport is selected
                  final isSelected = selectedSport == entry.key;

                  // Return padded button
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    // Cupertino button for sport filter
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(20),
                      // Green for selected, gray for unselected
                      color: isSelected 
                          ? const Color(0xFF4CAF50) // Same green as Colors.green
                          : const Color(0xFF616161), // Same as Colors.grey[700]
                      // Handle sport selection
                      onPressed: () {
                        setState(() {
                          selectedSport = entry.key;
                          fetchScores();
                        });
                      },
                      // Button content with logo and text
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // League logo
                          Image.asset(
                            getLeagueLogoPath(entry.key),
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                          // Spacing between logo and text
                          const SizedBox(width: 8),
                          // Sport name text
                          Text(
                            entry.value,
                            style: TextStyle(
                              // White for selected, green for unselected
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
            // Expanded area for scores content
            Expanded(
              // Conditional rendering based on loading state
              child: isLoading
                  // Show loading indicator when loading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        // Same green color
                        color: Color(0xFF4CAF50),
                        radius: 15,
                      ),
                    )
                  // Show error state if error occurred
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Error icon
                              Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: CupertinoColors.destructiveRed,
                                size: 48,
                              ),
                              // Spacing after icon
                              const SizedBox(height: 16),
                              // Error message text
                              Text(
                                error!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              // Spacing before retry button
                              const SizedBox(height: 16),
                              // Retry button
                              CupertinoButton(
                                color: const Color(0xFF4CAF50),
                                onPressed: fetchScores,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      // Show scores list with pull-to-refresh
                      : CustomScrollView(
                          // iOS-style bouncing scroll physics
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // Pull-to-refresh control
                            CupertinoSliverRefreshControl(
                              onRefresh: fetchScores,
                            ),
                            // Conditional rendering based on scores availability
                            scores.isEmpty
                                // Show empty state if no scores
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Game controller icon
                                          Icon(
                                            CupertinoIcons.game_controller,
                                            color: Colors.grey[400],
                                            size: 64,
                                          ),
                                          // Spacing after icon
                                          const SizedBox(height: 16),
                                          // No scores available text
                                          Text(
                                            'No scores available',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          // Spacing before instruction text
                                          const SizedBox(height: 8),
                                          // Pull to refresh instruction
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
                                // Show scores list if scores exist
                                : SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    // Sliver list for scores
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        // Builder function for each score card
                                        (context, index) {
                                          // Get game data at current index
                                          final game = scores[index];
                                          // Return padded score card
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

  // Method to build individual score card widget
  Widget _buildScoreCard(dynamic game) {
    // Return container with score card styling
    return Container(
      // Card decoration with background and shadow
      decoration: BoxDecoration(
        // Same as Colors.grey[700]
        color: const Color(0xFF616161),
        borderRadius: BorderRadius.circular(12),
        // Shadow for depth effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Card content padding
      child: Padding(
        padding: const EdgeInsets.all(16),
        // Column to arrange card content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Status Row
            // Row for game status and completion indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Game status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // Green for completed games, gray for upcoming
                    color: game['completed'] 
                        ? const Color(0xFF4CAF50) // Green for completed games
                        : const Color(0xFF616161), // Gray for upcoming games
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Game status text
                  child: Text(
                    formatGameStatus(game),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Status icon based on completion
                if (game['completed'])
                  // Checkmark for completed games
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: const Color(0xFF4CAF50),
                    size: 20,
                  )
                else
                  // Clock icon for upcoming games
                  Icon(
                    CupertinoIcons.clock,
                    // Gray instead of blue
                    color: const Color(0xFF616161),
                    size: 20,
                  ),
              ],
            ),
            // Spacing between status and teams
            const SizedBox(height: 12),
            // Teams and Score Row
            // Row to display teams and score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home team information
                buildTeamInfo(game['home_team'] ?? '', true),
                // Score display container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    // Darker background for score
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                    // Green border
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1,
                    ),
                  ),
                  // Score text
                  child: Text(
                    formatScore(game),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Away team information
                buildTeamInfo(game['away_team'] ?? '', false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
