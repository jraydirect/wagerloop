// Enhanced Game Details Page Integration Guide for WagerLoop
// 
// This file demonstrates how to properly integrate ESPN Odds API 
// into your game details page using the existing ESPN Odds Service

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/espn_odds_service.dart';
import '../widgets/espn_odds_display_widget.dart';

class ESPNOddsIntegrationGuide {
  
  // Key Integration Points for Game Details Page:
  
  // 1. Add ESPN Odds Service instance to your GameDetailsPage state
  static const String addToState = '''
  class _GameDetailsPageState extends State<GameDetailsPage> {
    final ESPNOddsService _espnOddsService = ESPNOddsService();
    
    // ... existing state variables
    Map<String, dynamic>? espnOddsData;
    bool isLoadingOdds = false;
  ''';

  // 2. Modify the sport conversion method to match ESPN Odds Service format
  static const String sportConversion = '''
  String _convertSportForESPN(String sport) {
    const sportMapping = {
      'football/nfl': 'NFL',
      'basketball/nba': 'NBA', 
      'basketball/nba-summer-las-vegas': 'NBA',
      'baseball/mlb': 'MLB',
      'hockey/nhl': 'NHL',
      'mma/ufc': 'UFC',
    };
    return sportMapping[sport] ?? 'NFL';
  }
  ''';

  // 3. Add method to load ESPN odds data
  static const String loadOddsMethod = '''
  Future<void> _loadESPNOdds() async {
    try {
      setState(() {
        isLoadingOdds = true;
      });

      final eventId = widget.game['id']?.toString();
      final sport = _convertSportForESPN(widget.sport);
      
      if (eventId != null && eventId.isNotEmpty) {
        print('Loading ESPN odds for event: \$eventId, sport: \$sport');
        final odds = await _espnOddsService.fetchGameOdds(eventId, sport);
        
        setState(() {
          espnOddsData = odds;
          isLoadingOdds = false;
        });
        
        print('ESPN odds loaded: \${odds.isNotEmpty ? 'Success' : 'No data'}');
      } else {
        setState(() {
          isLoadingOdds = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingOdds = false;
      });
      print('Error loading ESPN odds: \$e');
    }
  }
  ''';

  // 4. Update the build odds section to use ESPN Odds Display Widget
  static const String buildOddsSection = '''
  Widget _buildESPNOddsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ESPNOddsDisplayWidget(
        eventId: widget.game['id']?.toString() ?? '',
        sport: _convertSportForESPN(widget.sport),
        compact: false,
        showProbabilities: true,
        showPredictor: true,
        preferredProviders: const [2000, 38, 31, 36, 25], // Bet365, Caesars, William Hill, Unibet, Westgate
      ),
    );
  }
  ''';

  // 5. Call the odds loading method in initState or after game details load
  static const String initStateUpdate = '''
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

      // Load ESPN game details first
      final details = await _fetchESPNGameDetails();
      
      setState(() {
        gameDetails = details;
        isLoading = false;
      });

      // Load ESPN odds data after game details load
      _loadESPNOdds();
      
      // Load team rosters in parallel
      _loadTeamRosters();
    } catch (e) {
      setState(() {
        error = 'Failed to load game details: \$e';
        isLoading = false;
      });
    }
  }
  ''';
}

// Troubleshooting Common Issues:

/* 
1. "Odds Not Available" Issue:
   - Check if the eventId is properly extracted from the game object
   - Verify the sport mapping is correct for ESPN Odds Service
   - Ensure the ESPN API endpoints are accessible
   - Check console logs for API errors

2. Performance Optimization:
   - Load odds data asynchronously after game details
   - Use loading states to show progress
   - Cache odds data to avoid repeated API calls
   - Implement error handling with retry functionality

3. UI Integration:
   - The ESPNOddsDisplayWidget handles its own loading and error states
   - It will show "Odds Not Available" if no data is returned
   - The widget supports both compact and full display modes
   - Customize preferredProviders to show specific sportsbooks first

4. API Rate Limiting:
   - ESPN Odds Service includes built-in caching (5-minute validity)
   - Avoid making multiple simultaneous requests for the same event
   - The service handles rate limiting gracefully

5. Data Format Issues:
   - ESPN API sometimes returns odds as strings instead of numbers
   - The service includes parsing helpers for odds values
   - Win probabilities are returned as decimals (0.0 to 1.0)
   - Some games may not have betting data available

To implement this in your existing GameDetailsPage:

1. Import the ESPNOddsService at the top of your file
2. Add the service instance and state variables 
3. Update your _loadGameDetails method to call _loadESPNOdds
4. Ensure your _buildESPNOddsSection is properly configured
5. Test with different sports and game states (scheduled, live, completed)

The ESPN Odds Service supports these features:
- Multiple sportsbook providers (Bet365, Caesars, William Hill, etc.)
- Win probabilities and ESPN predictor data
- Odds history and movement tracking
- Team ATS (Against The Spread) records
- Futures betting data
- Comprehensive error handling and logging

Your existing implementation should work correctly. If you're seeing "Odds Not Available", 
check the console logs for specific error messages that can help debug the issue.
*/
