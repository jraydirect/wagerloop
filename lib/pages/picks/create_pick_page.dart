import 'package:flutter/material.dart';
import '../../models/sports/game.dart';
import '../../models/pick_post.dart';
import '../../services/sports_api_service.dart';
import '../../services/supabase_config.dart';
import '../../services/auth_service.dart';

class CreatePickPage extends StatefulWidget {
  const CreatePickPage({Key? key}) : super(key: key);

  @override
  _CreatePickPageState createState() => _CreatePickPageState();
}

class _CreatePickPageState extends State<CreatePickPage> {
  final _searchController = TextEditingController();
  final _contentController = TextEditingController();
  final _sportsApiService = SportsApiService();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _authService = AuthService();
  
  List<Game> _searchResults = [];
  List<Pick> _selectedPicks = []; // Changed: Now storing multiple picks
  Game? _currentGame; // Currently selected game for making a pick
  PickType? _selectedPickType;
  PickSide? _selectedPickSide;
  String? _selectedOdds;
  double? _stake;
  bool _isSearching = false;
  bool _isCreatingPost = false;
  bool _isParlay = false; // New: Track if this is a parlay

  @override
  void initState() {
    super.initState();
    // Set the search controller for the sports API service
    SportsApiService.searchController = _searchController;
  }

  Future<void> _searchGames(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _sportsApiService.searchGamesByTeam(
        query,
        onIncrementalResults: (games) {
          if (mounted) {
            setState(() {
              _searchResults = games;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('Error searching games: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectGame(Game game) {
    setState(() {
      _currentGame = game;
      _selectedPickType = null;
      _selectedPickSide = null;
      _selectedOdds = null;
    });
  }

  void _selectPickType(PickType pickType) {
    setState(() {
      _selectedPickType = pickType;
      _selectedPickSide = null;
      _selectedOdds = null;
    });
  }

  void _selectPickSide(PickSide pickSide) {
    setState(() {
      _selectedPickSide = pickSide;
      _updateOdds();
    });
  }

  void _updateOdds() {
    if (_currentGame == null || _selectedPickType == null || _selectedPickSide == null) {
      return;
    }

    // Try to get odds from sportsbook data first
    if (_currentGame!.sportsbookOdds != null && _currentGame!.sportsbookOdds!.isNotEmpty) {
      final oddsData = _currentGame!.sportsbookOdds!.values.first;
      
      switch (_selectedPickType!) {
        case PickType.moneyline:
          _selectedOdds = oddsData.getMoneylineDisplay(_selectedPickSide!.name);
          break;
        case PickType.spread:
          _selectedOdds = oddsData.getSpreadDisplay(_selectedPickSide!.name);
          break;
        case PickType.total:
          _selectedOdds = oddsData.getTotalDisplay(_selectedPickSide!.name);
          break;
        case PickType.playerProp:
          _selectedOdds = '-110'; // Default for player props
          break;
      }
    } else {
      // Fallback to default odds
      _selectedOdds = '-110';
    }
  }

  // New: Add current pick to the list
  void _addPickToList() {
    if (_currentGame == null || _selectedPickType == null || _selectedPickSide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your pick selection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pick = Pick(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      game: _currentGame!,
      pickType: _selectedPickType!,
      pickSide: _selectedPickSide!,
      odds: _selectedOdds ?? '-110',
      stake: _stake,
    );

    setState(() {
      _selectedPicks.add(pick);
      _currentGame = null;
      _selectedPickType = null;
      _selectedPickSide = null;
      _selectedOdds = null;
      _stake = null;
      _searchController.clear();
      _searchResults.clear();
      
      // If this is the second pick, automatically make it a parlay
      if (_selectedPicks.length >= 2) {
        _isParlay = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pick added! (${_selectedPicks.length} total)'),
        backgroundColor: Colors.green,
      ),
    );
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
      await _socialFeedService.createPickPost(pickPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isParlay ? 'Parlay posted successfully!' : 'Pick posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text(_isParlay ? 'Create Parlay' : 'Create Pick'),
        backgroundColor: Colors.grey[800],
        actions: [
          if (_selectedPicks.isNotEmpty)
            TextButton(
              onPressed: _isCreatingPost ? null : _createPickPost,
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
      body: Column(
        children: [
          // Show selected picks summary if any
          if (_selectedPicks.isNotEmpty) _buildSelectedPicksSummary(),

          // Search Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPicks.isEmpty 
                      ? 'Search for a game:' 
                      : 'Add another game:',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter team name (e.g., "Kentucky", "Lakers")',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[700],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _searchGames(value);
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPicksSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isParlay ? Colors.purple.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        border: Border.all(
          color: _isParlay ? Colors.purple.withOpacity(0.5) : Colors.green.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isParlay ? Icons.layers : Icons.sports_basketball,
                color: _isParlay ? Colors.purple : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isParlay ? '${_selectedPicks.length}-Leg Parlay' : 'Single Pick',
                style: TextStyle(
                  color: _isParlay ? Colors.purple : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedPicks.length} pick${_selectedPicks.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _selectedPicks.asMap().entries.map((entry) {
              final index = entry.key;
              final pick = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                pick.displayText,
                                style: TextStyle(
                                  color: _isParlay ? Colors.purple : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pick.odds,
                                style: TextStyle(
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removePick(index),
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (_selectedPicks.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _isParlay ? 'Add a comment about your parlay...' : 'Add a comment about your pick...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.grey[600],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          if (_isParlay)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Parlay Odds: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    getParlayOdds() ?? '',
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_searchResults.isNotEmpty) {
      return _currentGame == null
          ? _buildGamesList()
          : _buildPickSelection();
    } else if (_currentGame != null) {
      return _buildPickSelection();
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedPicks.isEmpty ? Icons.search : Icons.add,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedPicks.isEmpty 
                  ? 'Search for a team to see available games'
                  : 'Search for another team to add more picks',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGamesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        
        // Check if this game is already selected
        final isAlreadySelected = _selectedPicks.any((pick) => pick.game.id == game.id);
        
        return Card(
          color: isAlreadySelected ? Colors.grey[600] : Colors.grey[700],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAlreadySelected ? Colors.grey : Colors.blue,
              child: Text(
                game.sport,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            title: Text(
              '${game.awayTeam} @ ${game.homeTeam}',
              style: TextStyle(
                color: isAlreadySelected ? Colors.grey[400] : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.formattedGameTime,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                Text(
                  '${game.sport} • ${game.status.toUpperCase()}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                if (isAlreadySelected)
                  Text(
                    'Already selected',
                    style: TextStyle(
                      color: Colors.orange[300],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              isAlreadySelected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isAlreadySelected ? Colors.orange : Colors.white,
              size: 16,
            ),
            onTap: isAlreadySelected ? null : () => _selectGame(game),
          ),
        );
      },
    );
  }

  Widget _buildPickSelection() {
    if (_currentGame == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Game Info
          Card(
            color: Colors.grey[700],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${_currentGame!.awayTeam} @ ${_currentGame!.homeTeam}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentGame = null;
                            _selectedPickType = null;
                            _selectedPickSide = null;
                            _selectedOdds = null;
                          });
                        },
                        child: const Text('Change Game', style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentGame!.formattedGameTime,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '${_currentGame!.sport} • ${_currentGame!.status.toUpperCase()}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pick Type Selection
          const Text(
            'Choose bet type:',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PickType.values.map((type) {
              final isSelected = _selectedPickType == type;
              return ChoiceChip(
                label: Text(_getPickTypeDisplayName(type)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) _selectPickType(type);
                },
                selectedColor: Colors.green,
                backgroundColor: Colors.grey[600],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                ),
              );
            }).toList(),
          ),

          if (_selectedPickType != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Choose your pick:',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPickSideSelection(),
          ],

          if (_selectedPickSide != null) ...[
            const SizedBox(height: 16),

            // Pick Summary
            Card(
              color: Colors.green.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Pick:',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPickDisplayText(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    if (_selectedOdds != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Odds: $_selectedOdds',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add Pick Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPickToList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _selectedPicks.isEmpty ? 'Add Pick' : 'Add Another Pick',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickSideSelection() {
    if (_selectedPickType == null) return const SizedBox.shrink();

    List<PickSide> availableSides;
    switch (_selectedPickType!) {
      case PickType.moneyline:
        availableSides = [PickSide.home, PickSide.away];
        if (_currentGame!.sport == 'Soccer') {
          availableSides.add(PickSide.draw);
        }
        break;
      case PickType.spread:
        availableSides = [PickSide.home, PickSide.away];
        break;
      case PickType.total:
        availableSides = [PickSide.over, PickSide.under];
        break;
      case PickType.playerProp:
        availableSides = [PickSide.over, PickSide.under];
        break;
    }

    return Wrap(
      spacing: 8,
      children: availableSides.map((side) {
        final isSelected = _selectedPickSide == side;
        return ChoiceChip(
          label: Text(_getPickSideDisplayName(side)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) _selectPickSide(side);
          },
          selectedColor: Colors.green,
          backgroundColor: Colors.grey[600],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
          ),
        );
      }).toList(),
    );
  }

  String _getPickTypeDisplayName(PickType type) {
    switch (type) {
      case PickType.moneyline:
        return 'Moneyline';
      case PickType.spread:
        return 'Spread';
      case PickType.total:
        return 'Over/Under';
      case PickType.playerProp:
        return 'Player Prop';
    }
  }

  String _getPickSideDisplayName(PickSide side) {
    switch (side) {
      case PickSide.home:
        return _currentGame?.homeTeam ?? 'Home';
      case PickSide.away:
        return _currentGame?.awayTeam ?? 'Away';
      case PickSide.over:
        return 'Over';
      case PickSide.under:
        return 'Under';
      case PickSide.draw:
        return 'Draw';
    }
  }

  String _getPickDisplayText() {
    if (_currentGame == null || _selectedPickType == null || _selectedPickSide == null) {
      return '';
    }

    switch (_selectedPickType!) {
      case PickType.moneyline:
        String team = _selectedPickSide == PickSide.home ? _currentGame!.homeTeam : 
                     _selectedPickSide == PickSide.away ? _currentGame!.awayTeam : 'Draw';
        return '$team Moneyline';
      
      case PickType.spread:
        String team = _selectedPickSide == PickSide.home ? _currentGame!.homeTeam : _currentGame!.awayTeam;
        return '$team Spread';
      
      case PickType.total:
        String side = _selectedPickSide == PickSide.over ? 'Over' : 'Under';
        return '$side Total';
      
      case PickType.playerProp:
        String side = _selectedPickSide == PickSide.over ? 'Over' : 'Under';
        return 'Player Prop $side';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
