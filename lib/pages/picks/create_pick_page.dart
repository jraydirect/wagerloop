// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import Game model for sports game data
import '../../models/sports/game.dart';
// Import PickPost model for pick post data
import '../../models/pick_post.dart';
// Import SportsApiService for fetching sports data
import '../../services/sports_api_service.dart';
// Import SupabaseConfig for database operations
import '../../services/supabase_config.dart';
// Import AuthService for user authentication
import '../../services/auth_service.dart';

// CreatePickPage class definition - a stateful widget for creating betting picks
class CreatePickPage extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const CreatePickPage({Key? key}) : super(key: key);

  // Override createState method to return the state class instance
  @override
  _CreatePickPageState createState() => _CreatePickPageState();
}

// Private state class that manages the create pick page's state and functionality
class _CreatePickPageState extends State<CreatePickPage> {
  // Text controller for game search input
  final _searchController = TextEditingController();
  // Text controller for pick post content
  final _contentController = TextEditingController();
  // Sports API service instance for fetching game data
  final _sportsApiService = SportsApiService();
  // Social feed service instance for creating pick posts
  final _socialFeedService = SupabaseConfig.socialFeedService;
  // Authentication service instance for user operations
  final _authService = AuthService();
  
  // List to store search results for games
  List<Game> _searchResults = [];
  // List to store selected picks (changed to support multiple picks)
  List<Pick> _selectedPicks = []; // Changed: Now storing multiple picks
  // Currently selected game for making a pick
  Game? _currentGame; // Currently selected game for making a pick
  // Selected pick type (moneyline, spread, total, player prop)
  PickType? _selectedPickType;
  // Selected pick side (home team, away team, over, under)
  PickSide? _selectedPickSide;
  // Selected odds for the pick
  String? _selectedOdds;
  // Stake amount for the pick
  double? _stake;
  // Boolean flag to track search loading state
  bool _isSearching = false;
  // Boolean flag to track post creation loading state
  bool _isCreatingPost = false;
  // Boolean flag to track if this is a parlay bet
  bool _isParlay = false; // New: Track if this is a parlay

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Set the search controller for the sports API service
    SportsApiService.searchController = _searchController;
  }

  // Async method to search for games based on query
  Future<void> _searchGames(String query) async {
    // Clear search results if query is empty
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Set searching state to true
    setState(() {
      _isSearching = true;
    });

    try {
      // Search for games using the sports API service
      final results = await _sportsApiService.searchGamesByTeam(
        query,
        // Callback for incremental results
        onIncrementalResults: (games) {
          // Update search results if widget is still mounted
          if (mounted) {
            setState(() {
              _searchResults = games;
            });
          }
        },
      );

      // Update final search results if widget is still mounted
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      // Log error and show snackbar if search fails
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
      // Reset searching state if widget is still mounted
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Method to select a game for making a pick
  void _selectGame(Game game) {
    setState(() {
      // Set current game and reset pick selections
      _currentGame = game;
      _selectedPickType = null;
      _selectedPickSide = null;
      _selectedOdds = null;
    });
  }

  // Method to select pick type (moneyline, spread, total, player prop)
  void _selectPickType(PickType pickType) {
    setState(() {
      // Set pick type and reset subsequent selections
      _selectedPickType = pickType;
      _selectedPickSide = null;
      _selectedOdds = null;
    });
  }

  // Method to select pick side (home, away, over, under)
  void _selectPickSide(PickSide pickSide) {
    setState(() {
      // Set pick side and update odds
      _selectedPickSide = pickSide;
      _updateOdds();
    });
  }

  // Method to update odds based on current selections
  void _updateOdds() {
    // Return early if required selections are not made
    if (_currentGame == null || _selectedPickType == null || _selectedPickSide == null) {
      return;
    }

    // Try to get odds from sportsbook data first
    if (_currentGame!.sportsbookOdds != null && _currentGame!.sportsbookOdds!.isNotEmpty) {
      // Get odds data from first available sportsbook
      final oddsData = _currentGame!.sportsbookOdds!.values.first;
      
      // Set odds based on pick type
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
      // Fallback to default odds if no sportsbook data available
      _selectedOdds = '-110';
    }
  }

  // Method to add current pick to the list of selected picks
  void _addPickToList() {
    // Validate that all required selections are made
    if (_currentGame == null || _selectedPickType == null || _selectedPickSide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your pick selection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a new pick with current selections
    final pick = Pick(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      game: _currentGame!,
      pickType: _selectedPickType!,
      pickSide: _selectedPickSide!,
      odds: _selectedOdds ?? '-110',
      stake: _stake,
    );

    setState(() {
      // Add pick to the list and reset selections
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

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pick added! (${_selectedPicks.length} total)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Method to remove a pick from the list
  void _removePick(int index) {
    setState(() {
      // Remove pick at specified index
      _selectedPicks.removeAt(index);
      
      // If we go below 2 picks, it's no longer a parlay
      if (_selectedPicks.length < 2) {
        _isParlay = false;
      }
    });
  }

  // Async method to create and post the pick
  Future<void> _createPickPost() async {
    // Validate that at least one pick is selected
    if (_selectedPicks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one pick'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set creating post state to true
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
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isParlay ? 'Parlay posted successfully!' : 'Pick posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate success
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      // Log error and show error message
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
      // Reset creating post state if widget is still mounted
      if (mounted) {
        setState(() {
          _isCreatingPost = false;
        });
      }
    }
  }

  // Method to convert American odds to decimal odds
  double americanToDecimal(String oddsStr) {
    int odds = int.parse(oddsStr);
    if (odds > 0) {
      return (odds / 100) + 1;
    } else {
      return 1 + (100 / -odds);
    }
  }

  // Method to convert decimal odds to American odds
  String decimalToAmerican(double dec) {
    if (dec >= 2) {
      return '+${((dec - 1) * 100).round()}';
    } else {
      return '-${(100 / (dec - 1)).round()}';
    }
  }

  // Method to calculate parlay odds
  String? getParlayOdds() {
    if (!_isParlay) return null;
    double product = 1.0;
    for (var pick in _selectedPicks) {
      double decimal = americanToDecimal(pick.odds);
      product *= decimal;
    }
    return decimalToAmerican(product);
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with create pick interface
    return Scaffold(
      // Set dark background color
      backgroundColor: Colors.grey[800],
      // App bar with title and post action
      appBar: AppBar(
        // Set title based on parlay flag
        title: Text(_isParlay ? 'Create Parlay' : 'Create Pick'),
        // Set app bar background color
        backgroundColor: Colors.grey[800],
        // Actions for app bar
        actions: [
          // Show post button if picks are selected
          if (_selectedPicks.isNotEmpty)
            TextButton(
              // Handle post action, disabled when creating post
              onPressed: _isCreatingPost ? null : _createPickPost,
              // Button content - loading indicator or text
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
      // Safe area body with scrollable content
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Show selected picks summary if any
              if (_selectedPicks.isNotEmpty) _buildSelectedPicksSummary(),

              // Search Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search section title
                    Text(
                      _selectedPicks.isEmpty 
                          ? 'Search for a game:' 
                          : 'Add another pick:',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search input field
                    TextField(
                      controller: _searchController,
                      onChanged: _searchGames,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search teams or games...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Results
              if (_isSearching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                _buildSearchResults(),

              // Current Game Selection
              if (_currentGame != null) _buildGameSelection(),

              // Pick Type Selection
              if (_currentGame != null && _selectedPickType == null) _buildPickTypeSelection(),

              // Pick Side Selection
              if (_currentGame != null && _selectedPickType != null && _selectedPickSide == null)
                _buildPickSideSelection(),

              // Odds and Stake Selection
              if (_currentGame != null && _selectedPickType != null && _selectedPickSide != null)
                _buildOddsAndStakeSelection(),

              // Content Input
              if (_selectedPicks.isNotEmpty) _buildContentInput(),

              // Bottom padding
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build selected picks summary widget
  Widget _buildSelectedPicksSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isParlay ? 'Parlay (${_selectedPicks.length} picks)' : 'Single Pick',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isParlay && getParlayOdds() != null)
                Text(
                  getParlayOdds()!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_selectedPicks.length, (index) {
            final pick = _selectedPicks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pick.displayText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pick.game.awayTeam.name} @ ${pick.game.homeTeam.name}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    pick.odds,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _removePick(index),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Method to build search results widget
  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final game = _searchResults[index];
          return ListTile(
            title: Text(
              '${game.awayTeam.name} @ ${game.homeTeam.name}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              game.startTime != null
                  ? '${game.startTime!.month}/${game.startTime!.day} ${game.startTime!.hour}:${game.startTime!.minute.toString().padLeft(2, '0')}'
                  : 'Time TBD',
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () => _selectGame(game),
          );
        },
      ),
    );
  }

  // Method to build game selection widget
  Widget _buildGameSelection() {
    final game = _currentGame!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Game:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${game.awayTeam.name} @ ${game.homeTeam.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (game.startTime != null)
            Text(
              '${game.startTime!.month}/${game.startTime!.day} ${game.startTime!.hour}:${game.startTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  // Method to build pick type selection widget
  Widget _buildPickTypeSelection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Pick Type:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildPickTypeChip('Moneyline', PickType.moneyline),
              _buildPickTypeChip('Spread', PickType.spread),
              _buildPickTypeChip('Total', PickType.total),
              _buildPickTypeChip('Player Prop', PickType.playerProp),
            ],
          ),
        ],
      ),
    );
  }

  // Method to build pick type chip widget
  Widget _buildPickTypeChip(String label, PickType pickType) {
    return FilterChip(
      label: Text(label),
      selected: _selectedPickType == pickType,
      onSelected: (selected) {
        if (selected) {
          _selectPickType(pickType);
        }
      },
      backgroundColor: Colors.grey[800],
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: _selectedPickType == pickType ? Colors.white : Colors.grey[300],
      ),
    );
  }

  // Method to build pick side selection widget
  Widget _buildPickSideSelection() {
    final game = _currentGame!;
    final pickType = _selectedPickType!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Pick Side:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPickSideOptions(game, pickType),
        ],
      ),
    );
  }

  // Method to build pick side options based on pick type
  Widget _buildPickSideOptions(Game game, PickType pickType) {
    switch (pickType) {
      case PickType.moneyline:
        return Column(
          children: [
            _buildPickSideOption(
              '${game.awayTeam.name} Win',
              PickSide.away,
            ),
            const SizedBox(height: 8),
            _buildPickSideOption(
              '${game.homeTeam.name} Win',
              PickSide.home,
            ),
          ],
        );
      case PickType.spread:
        return Column(
          children: [
            _buildPickSideOption(
              '${game.awayTeam.name} +/-',
              PickSide.away,
            ),
            const SizedBox(height: 8),
            _buildPickSideOption(
              '${game.homeTeam.name} +/-',
              PickSide.home,
            ),
          ],
        );
      case PickType.total:
        return Column(
          children: [
            _buildPickSideOption(
              'Over',
              PickSide.over,
            ),
            const SizedBox(height: 8),
            _buildPickSideOption(
              'Under',
              PickSide.under,
            ),
          ],
        );
      case PickType.playerProp:
        return Column(
          children: [
            _buildPickSideOption(
              'Over',
              PickSide.over,
            ),
            const SizedBox(height: 8),
            _buildPickSideOption(
              'Under',
              PickSide.under,
            ),
          ],
        );
    }
  }

  // Method to build pick side option widget
  Widget _buildPickSideOption(String label, PickSide pickSide) {
    return GestureDetector(
      onTap: () => _selectPickSide(pickSide),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedPickSide == pickSide ? Colors.blue : Colors.grey[600]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: _selectedPickSide == pickSide ? Colors.blue : Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Method to build odds and stake selection widget
  Widget _buildOddsAndStakeSelection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Odds & Stake:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Odds:',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedOdds ?? '-110',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stake (optional):',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _stake = double.tryParse(value);
                        });
                      },
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '\$0.00',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixText: '\$',
                        prefixStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addPickToList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add Pick',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build content input widget
  Widget _buildContentInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a comment (optional):',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your thoughts on this pick...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose text controllers to prevent memory leaks
    _searchController.dispose();
    _contentController.dispose();
    // Call parent dispose
    super.dispose();
  }
}
