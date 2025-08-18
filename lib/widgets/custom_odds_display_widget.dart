import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/the_odds_api_service.dart';

/// Custom odds display widget that replaces TheOddsAPI widget
/// 
/// Fetches odds data directly from TheOddsAPI and displays them
/// in a custom interface with selection functionality
class CustomOddsDisplayWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onOddsSelected;
  final String? preferredBookmaker;
  final List<String>? markets;

  const CustomOddsDisplayWidget({
    Key? key,
    this.onOddsSelected,
    this.preferredBookmaker,
    this.markets,
  }) : super(key: key);

  @override
  State<CustomOddsDisplayWidget> createState() => _CustomOddsDisplayWidgetState();
}

class _CustomOddsDisplayWidgetState extends State<CustomOddsDisplayWidget> {
  final TheOddsApiService _oddsService = TheOddsApiService();
  
  String _selectedSport = 'NFL';
  String _selectedBookmaker = 'fanduel'; // Default to FanDuel per user preference
  List<String> _selectedMarkets = ['h2h', 'spreads', 'totals'];
  
  List<Map<String, dynamic>> _displayOdds = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Available sports
  final List<String> _availableSports = [
    'NFL', 'NBA', 'MLB', 'NHL', 'NCAAF', 'NCAAB', 'Soccer', 'UFC'
  ];

  @override
  void initState() {
    super.initState();
    _selectedBookmaker = widget.preferredBookmaker ?? _oddsService.getPreferredBookmaker();
    if (widget.markets != null) {
      _selectedMarkets = widget.markets!;
    }
    _fetchOdds();
  }

  Future<void> _fetchOdds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Fetching odds for $_selectedSport with bookmaker $_selectedBookmaker');
      
      final oddsData = await _oddsService.fetchOddsForSport(
        _selectedSport,
        bookmakers: [_selectedBookmaker],
        markets: _selectedMarkets,
      );

      if (oddsData.isEmpty) {
        setState(() {
          _errorMessage = 'No odds data available for $_selectedSport';
          _isLoading = false;
        });
        return;
      }

      final parsedOdds = _oddsService.parseOddsForDisplay(oddsData);
      
      setState(() {
        _displayOdds = parsedOdds;
        _isLoading = false;
      });

      debugPrint('Loaded ${parsedOdds.length} odds entries for $_selectedSport');
    } catch (e) {
      debugPrint('Error fetching odds: $e');
      setState(() {
        _errorMessage = 'Failed to load odds: $e';
        _isLoading = false;
      });
    }
  }

  void _onOddsSelected(Map<String, dynamic> oddsData) {
    debugPrint('Odds selected: ${oddsData['outcome']} ${oddsData['odds']}');
    
    // Format odds data for the pick slip
    final pickData = {
      'gameText': oddsData['gameText'],
      'oddsText': '${oddsData['outcome']} ${oddsData['odds']}',
      'odds': oddsData['odds'],
      'team1': oddsData['awayTeam'],
      'team2': oddsData['homeTeam'],
      'marketType': _getMarketDisplayName(oddsData['marketKey']),
      'bookmaker': oddsData['bookmaker'],
      'outcome': oddsData['outcome'],
      'price': oddsData['price'],
      'point': oddsData['point'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    widget.onOddsSelected?.call(pickData);

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to slip: ${oddsData['outcome']} ${oddsData['odds']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getMarketDisplayName(String marketKey) {
    switch (marketKey) {
      case 'h2h':
        return 'Moneyline';
      case 'spreads':
        return 'Spread';
      case 'totals':
        return 'Total';
      default:
        return marketKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(color: Colors.grey[600]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sports Odds',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Sport selection
          Row(
            children: [
              const Text(
                'Sport: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableSports.map((sport) {
                      final isSelected = _selectedSport == sport;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(sport),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected && sport != _selectedSport) {
                              setState(() {
                                _selectedSport = sport;
                              });
                              _fetchOdds();
                            }
                          },
                          selectedColor: Colors.green.withOpacity(0.3),
                          backgroundColor: Colors.grey[700],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.green : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.green : Colors.grey[600]!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Bookmaker and refresh controls
          Row(
            children: [
              const Text(
                'Sportsbook: ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedBookmaker,
                  dropdownColor: Colors.grey[700],
                  style: const TextStyle(color: Colors.white),
                  underline: Container(
                    height: 2,
                    color: Colors.green,
                  ),
                  items: _oddsService.getAvailableBookmakers().map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(_oddsService.getBookmakerDisplayName(key)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != _selectedBookmaker) {
                      setState(() {
                        _selectedBookmaker = newValue;
                      });
                      _fetchOdds();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _isLoading ? null : () {
                  _oddsService.clearOddsCache();
                  _fetchOdds();
                },
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.green),
                tooltip: 'Refresh odds',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Loading odds...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchOdds,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_displayOdds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No odds available for $_selectedSport',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different sport or bookmaker',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return _buildOddsDisplay();
  }

  Widget _buildOddsDisplay() {
    // Group odds by game
    final Map<String, List<Map<String, dynamic>>> gameGroups = {};
    
    for (final odds in _displayOdds) {
      final gameKey = odds['gameText'] as String;
      gameGroups.putIfAbsent(gameKey, () => []).add(odds);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gameGroups.length,
      itemBuilder: (context, index) {
        final gameKey = gameGroups.keys.elementAt(index);
        final gameOdds = gameGroups[gameKey]!;
        
        return _buildGameCard(gameKey, gameOdds);
      },
    );
  }

  Widget _buildGameCard(String gameText, List<Map<String, dynamic>> gameOdds) {
    // Extract game info from first odds entry
    final firstOdds = gameOdds.first;
    final homeTeam = firstOdds['homeTeam'] as String;
    final awayTeam = firstOdds['awayTeam'] as String;
    final gameTime = DateTime.tryParse(firstOdds['gameTime'] as String) ?? DateTime.now();
    final bookmaker = firstOdds['bookmaker'] as String;

    // Group odds by market
    final Map<String, List<Map<String, dynamic>>> marketGroups = {};
    for (final odds in gameOdds) {
      final market = odds['market'] as String;
      marketGroups.putIfAbsent(market, () => []).add(odds);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$awayTeam @ $homeTeam',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatGameTime(gameTime)} • $bookmaker',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Markets
            ...marketGroups.entries.map((entry) {
              final market = entry.key;
              final odds = entry.value;
              
              return _buildMarketSection(market, odds);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSection(String market, List<Map<String, dynamic>> odds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          market,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: odds.map((oddsData) {
            return _buildOddsButton(oddsData);
          }).toList(),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOddsButton(Map<String, dynamic> oddsData) {
    final outcome = oddsData['outcome'] as String;
    final price = oddsData['odds'] as String;
    
    return InkWell(
      onTap: () => _onOddsSelected(oddsData),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              outcome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              price,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGameTime(DateTime gameTime) {
    final now = DateTime.now();
    final difference = gameTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else if (difference.inSeconds > -3600) { // Within last hour
      return 'Live';
    } else {
      return 'Final';
    }
  }
}
