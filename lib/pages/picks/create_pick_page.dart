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
  Game? _selectedGame;
  PickType? _selectedPickType;
  PickSide? _selectedPickSide;
  String? _selectedOdds;
  double? _stake;
  bool _isSearching = false;
  bool _isCreatingPost = false;

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
      _selectedGame = game;
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
    if (_selectedGame == null || _selectedPickType == null || _selectedPickSide == null) {
      return;
    }

    // Try to get odds from sportsbook data first
    if (_selectedGame!.sportsbookOdds != null && _selectedGame!.sportsbookOdds!.isNotEmpty) {
      final oddsData = _selectedGame!.sportsbookOdds!.values.first;
      
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

  Future<void> _createPickPost() async {
    if (_selectedGame == null || _selectedPickType == null || _selectedPickSide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a game and make a pick'),
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

      final pick = Pick(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        game: _selectedGame!,
        pickType: _selectedPickType!,
        pickSide: _selectedPickSide!,
        odds: _selectedOdds ?? '-110',
        stake: _stake,
        reasoning: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      );

      // Create the pick post
      final pickPost = PickPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id,
        username: username,
        content: _contentController.text.trim().isEmpty 
            ? 'My pick: ${pick.displayText}' 
            : _contentController.text.trim(),
        timestamp: DateTime.now(),
        picks: [pick],
      );

      // Save to Supabase using social feed service
      await _socialFeedService.createPickPost(pickPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pick posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Create Pick'),
        backgroundColor: Colors.grey[800],
        actions: [
          if (_selectedGame != null && _selectedPickType != null && _selectedPickSide != null)
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
          // Search Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search for a game:',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

          // Search Results
          if (_searchResults.isNotEmpty)
            Expanded(
              child: _selectedGame == null
                  ? _buildGamesList()
                  : _buildPickSelection(),
            )
          else if (_selectedGame != null)
            Expanded(child: _buildPickSelection())
          else
            const Expanded(
              child: Center(
                child: Text(
                  'Search for a team to see available games',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        return Card(
          color: Colors.grey[700],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                game.sport,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            title: Text(
              '${game.awayTeam} @ ${game.homeTeam}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            onTap: () => _selectGame(game),
          ),
        );
      },
    );
  }

  Widget _buildPickSelection() {
    if (_selectedGame == null) return const SizedBox.shrink();

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
                          '${_selectedGame!.awayTeam} @ ${_selectedGame!.homeTeam}',
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
                            _selectedGame = null;
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
                    _selectedGame!.formattedGameTime,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '${_selectedGame!.sport} • ${_selectedGame!.status.toUpperCase()}',
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
            // Content/Reasoning
            const Text(
              'Add a comment (optional):',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why do you like this pick?',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.grey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

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
        if (_selectedGame!.sport == 'Soccer') {
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
        return _selectedGame?.homeTeam ?? 'Home';
      case PickSide.away:
        return _selectedGame?.awayTeam ?? 'Away';
      case PickSide.over:
        return 'Over';
      case PickSide.under:
        return 'Under';
      case PickSide.draw:
        return 'Draw';
    }
  }

  String _getPickDisplayText() {
    if (_selectedGame == null || _selectedPickType == null || _selectedPickSide == null) {
      return '';
    }

    switch (_selectedPickType!) {
      case PickType.moneyline:
        String team = _selectedPickSide == PickSide.home ? _selectedGame!.homeTeam : 
                     _selectedPickSide == PickSide.away ? _selectedGame!.awayTeam : 'Draw';
        return '$team Moneyline';
      
      case PickType.spread:
        String team = _selectedPickSide == PickSide.home ? _selectedGame!.homeTeam : _selectedGame!.awayTeam;
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
