import 'package:flutter/material.dart';
import '../../models/sports/game.dart';
import '../../models/pick_post.dart';

import '../../services/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_odds_display_widget.dart';
import '../../widgets/pick_slip_widget.dart';

class CreatePickPage extends StatefulWidget {
  const CreatePickPage({Key? key}) : super(key: key);

  @override
  _CreatePickPageState createState() => _CreatePickPageState();
}

class _CreatePickPageState extends State<CreatePickPage> {
  final _contentController = TextEditingController();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _authService = AuthService();
  
  List<Pick> _selectedPicks = []; // Storing multiple picks
  List<Map<String, dynamic>> _oddsPickSlip = []; // New: for odds widget picks
  bool _isCreatingPost = false;
  bool _isParlay = false; // Track if this is a parlay

  @override
  void initState() {
    super.initState();
  }



  // New: Remove pick from list
  void _removePick(int index) {
    setState(() {
      _selectedPicks.removeAt(index);
      
      // If we go below 2 picks, it's no longer a parlay
      if (_selectedPicks.length < 2) {
        _isParlay = false;
      }
    });
  }

  Future<void> _createPickPost() async {
    if (_selectedPicks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one pick'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      // Get current user info
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Get user profile for username
      String username = 'current_user';
      try {
        final profile = await _authService.getCurrentUserProfile();
        username = profile?['username'] ?? currentUser.email ?? 'current_user';
      } catch (e) {
        print('Could not get user profile, using email: $e');
        username = currentUser.email ?? 'current_user';
      }

      // Create default content if none provided
      String content = _contentController.text.trim();
      if (content.isEmpty) {
        if (_isParlay) {
          content = 'My ${_selectedPicks.length}-leg parlay';
        } else {
          content = 'My pick: ${_selectedPicks.first.displayText}';
        }
      }

      // Create the pick post
      final pickPost = PickPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id,
        username: username,
        content: content,
        timestamp: DateTime.now(),
        picks: _selectedPicks,
      );

      // Save to Supabase using social feed service
      final createdPickPost = await _socialFeedService.createPickPost(pickPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isParlay ? 'Parlay posted successfully!' : 'Pick posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, createdPickPost); // Return the created post for instant addition
      }
    } catch (e) {
      print('Error creating pick post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating pick: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPost = false;
        });
      }
    }
  }

  double americanToDecimal(String oddsStr) {
    int odds = int.parse(oddsStr);
    if (odds > 0) {
      return (odds / 100) + 1;
    } else {
      return 1 + (100 / -odds);
    }
  }

  String decimalToAmerican(double dec) {
    if (dec >= 2) {
      return '+${((dec - 1) * 100).round()}';
    } else {
      return '-${(100 / (dec - 1)).round()}';
    }
  }

  String? getParlayOdds() {
    if (!_isParlay) return null;
    double product = 1.0;
    for (var pick in _selectedPicks) {
      double decimal = americanToDecimal(pick.odds);
      product *= decimal;
    }
    return decimalToAmerican(product);
  }

  // Handle pick selection from custom odds widget
  void _onOddsPickSelected(Map<String, dynamic> pickData) {
    debugPrint('🎯 CreatePickPage received pick data: $pickData');
    
    setState(() {
      // Avoid duplicates by checking if similar pick already exists
      bool isDuplicate = _oddsPickSlip.any((existing) =>
          existing['gameText'] == pickData['gameText'] &&
          existing['oddsText'] == pickData['oddsText']);
      
      debugPrint('🔍 Duplicate check: $isDuplicate');
      debugPrint('📋 Current slip size: ${_oddsPickSlip.length}');
      
      if (!isDuplicate) {
        _oddsPickSlip.add(pickData);
        debugPrint('✅ Added pick to slip. New size: ${_oddsPickSlip.length}');
        
        // Update parlay status
        _isParlay = _oddsPickSlip.length > 1;
        debugPrint('🎰 Parlay status: $_isParlay');
      } else {
        debugPrint('⚠️ Pick already exists in slip');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This pick is already in your slip'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // New: Remove pick from odds pick slip
  void _removeOddsPick(int index) {
    setState(() {
      _oddsPickSlip.removeAt(index);
      _isParlay = _oddsPickSlip.length > 1;
    });
  }

  // New: Clear all odds picks
  void _clearAllOddsPicks() {
    setState(() {
      _oddsPickSlip.clear();
      _isParlay = false;
    });
  }

  // Show pick creation dialog with caption input
  void _createPostFromOddsPicks() async {
    if (_oddsPickSlip.isEmpty) return;

    // Convert odds picks to standard Pick objects
    List<Pick> picks = _oddsPickSlip.map((oddsData) {
      return Pick(
        id: 'odds_${DateTime.now().millisecondsSinceEpoch}_${_oddsPickSlip.indexOf(oddsData)}',
        game: Game(
          id: 'odds_${DateTime.now().millisecondsSinceEpoch}',
          homeTeam: oddsData['team2'] ?? 'Unknown',
          awayTeam: oddsData['team1'] ?? 'Unknown',
          sport: 'Unknown',
          league: 'Unknown',
          gameTime: DateTime.now(),
          status: 'upcoming',
        ),
        pickType: _parsePickType(oddsData['marketType']),
        pickSide: PickSide.home, // Default, could be improved with better parsing
        odds: oddsData['odds'] ?? 'N/A',
        stake: 0, // Default
      );
    }).toList().cast<Pick>();

    setState(() {
      _selectedPicks = picks;
      _isParlay = picks.length > 1;
    });

    // Show the picks summary screen instead of immediately creating post
    _showPicksSummaryScreen();
  }

  // Show the picks summary screen for caption input
  void _showPicksSummaryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _buildPicksSummaryPage(),
      ),
    ).then((result) {
      // If user created a post, navigate back with the result
      if (result != null) {
        Navigator.pop(context, result);
      }
    });
  }

  // Build the picks summary page as a separate screen
  Widget _buildPicksSummaryPage() {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text(_isParlay ? 'Create Parlay' : 'Create Pick'),
        backgroundColor: Colors.grey[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isCreatingPost ? null : () async {
              await _createPickPost();
            },
            child: _isCreatingPost
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _buildSelectedPicksSummary(),
        ),
      ),
    );
  }

  // Helper: Parse market type to PickType
  PickType _parsePickType(String? marketType) {
    switch (marketType?.toLowerCase()) {
      case 'moneyline':
        return PickType.moneyline;
      case 'spread':
        return PickType.spread;
      case 'total':
        return PickType.total;
      default:
        return PickType.moneyline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Create Pick'),
        backgroundColor: Colors.grey[800],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area - custom odds display
            Expanded(
              child: CustomOddsDisplayWidget(
                onOddsSelected: _onOddsPickSelected,
                preferredBookmaker: 'fanduel', // User's preferred bookmaker
                markets: ['h2h', 'spreads', 'totals'], // Markets to show
              ),
            ),
            
            // Pick slip at bottom
            PickSlipWidget(
              picks: _oddsPickSlip,
              onClearAll: _clearAllOddsPicks,
              onRemovePick: _removeOddsPick,
              onCreatePost: _createPostFromOddsPicks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPicksSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with parlay info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isParlay ? Colors.green.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              border: Border.all(
                color: _isParlay ? Colors.green.withOpacity(0.5) : Colors.green.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _isParlay ? Icons.layers : Icons.sports_basketball,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isParlay ? '${_selectedPicks.length}-Leg Parlay' : 'Single Pick',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isParlay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: Text(
                      getParlayOdds() ?? '+0',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Picks list with improved formatting
          ..._selectedPicks.asMap().entries.map((entry) {
            final index = entry.key;
            final pick = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[600]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Game matchup
                            Text(
                              '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Game time and sport
                            Text(
                              'Today • ${pick.game.sport}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePick(index),
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pick details with better layout
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getPickDisplayText(pick),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pick.odds,
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 16),
          
          // Comment text field
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _isParlay ? 'Add a comment about your parlay...' : 'Add a comment about your pick...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.grey[700],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          // Parlay odds summary (larger display)
          if (_isParlay) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.green.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Parlay Odds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getParlayOdds() ?? '+0',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedPicks.length} legs',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }





  String _getPickDisplayText(Pick pick) {
    final game = pick.game;
    final pickType = pick.pickType;
    final pickSide = pick.pickSide;

    switch (pickType) {
      case PickType.moneyline:
        String team = pickSide == PickSide.home ? game.homeTeam : 
                     pickSide == PickSide.away ? game.awayTeam : 'Draw';
        return '$team Moneyline';
      
      case PickType.spread:
        String team = pickSide == PickSide.home ? game.homeTeam : game.awayTeam;
        return '$team Spread';
      
      case PickType.total:
        String side = pickSide == PickSide.over ? 'Over' : 'Under';
        return '$side Total';
      
      case PickType.playerProp:
        if (pick.playerName != null && pick.propType != null && pick.propValue != null) {
          String side = pickSide == PickSide.over ? 'Over' : 'Under';
          return '${pick.playerName} $side ${pick.propValue} ${pick.propType}';
        }
        String side = pickSide == PickSide.over ? 'Over' : 'Under';
        return 'Player Prop $side';
    }
  }



  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
