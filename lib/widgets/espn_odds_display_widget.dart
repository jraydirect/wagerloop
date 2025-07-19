import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../services/espn_odds_service.dart';

class ESPNOddsDisplayWidget extends StatefulWidget {
  final String eventId;
  final String sport;
  final bool showProbabilities;
  final bool showPredictor;
  final bool compact;
  final List<int>? preferredProviders; // Specific sportsbooks to highlight

  const ESPNOddsDisplayWidget({
    Key? key,
    required this.eventId,
    required this.sport,
    this.showProbabilities = true,
    this.showPredictor = true,
    this.compact = false,
    this.preferredProviders,
  }) : super(key: key);

  @override
  _ESPNOddsDisplayWidgetState createState() => _ESPNOddsDisplayWidgetState();
}

class _ESPNOddsDisplayWidgetState extends State<ESPNOddsDisplayWidget> {
  final ESPNOddsService _espnOddsService = ESPNOddsService();
  
  Map<String, dynamic> oddsData = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchOddsData();
  }

  Future<void> _fetchOddsData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final rawData = await _espnOddsService.fetchGameOdds(widget.eventId, widget.sport);
      
      // Debug logging for received data
      print('ESPN Odds Widget - Received data keys: ${rawData.keys.toList()}');
      if (rawData['odds'] != null) {
        print('ESPN Odds Widget - Odds data type: ${rawData['odds'].runtimeType}');
        if (rawData['odds'] is Map) {
          final oddsMap = rawData['odds'] as Map;
          print('ESPN Odds Widget - Odds providers: ${oddsMap.keys.toList()}');
        }
      }
      
      // Safely convert all data to proper Map<String, dynamic> format
      final data = _deepMapConvert(rawData);
      
      setState(() {
        oddsData = data;
        isLoading = false;
      });
    } catch (e) {
      print('ESPN Odds Widget - Error: $e');
      setState(() {
        error = 'Failed to load ESPN odds: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  /// Helper method to safely check if data is a non-empty Map
  bool _isMapAndNotEmpty(dynamic data) {
    return data is Map && data.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null || oddsData.isEmpty) {
      return _buildErrorState();
    }

    return widget.compact ? _buildCompactView() : _buildFullView();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 12),
            Text(
              'Loading ESPN Odds...',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: Color(0xFF8E8E93),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'ESPN odds not available',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    final oddsRaw = oddsData['odds'];
    final odds = _safeMapConvert(oddsRaw);
    
    if (odds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show best odds from available providers
    final bestOdds = _getBestOddsForDisplay(odds);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(width: 6),
              const Text(
                'ESPN Odds',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bestOdds.isNotEmpty) _buildCompactOddsRow(bestOdds),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                if (widget.showProbabilities && _isMapAndNotEmpty(oddsData['probabilities'])) ...[
                  _buildProbabilitiesSection(),
                  const SizedBox(height: 16),
                ],
                if (widget.showPredictor && _isMapAndNotEmpty(oddsData['predictor'])) ...[
                  _buildPredictorSection(),
                  const SizedBox(height: 16),
                ],
                _buildOddsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.chart_bar_alt_fill,
            size: 20,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'ESPN Betting Odds',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'Live',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProbabilitiesSection() {
    final probabilitiesRaw = oddsData['probabilities'];
    final probabilities = _safeMapConvert(probabilitiesRaw);
    
    if (probabilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.percent,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              const Text(
                'Win Probabilities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProbabilityItem(
                  'Home',
                  _espnOddsService.formatProbability(probabilities['homeWinProbability']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProbabilityItem(
                  'Away',
                  _espnOddsService.formatProbability(probabilities['awayWinProbability']),
                ),
              ),
              if (probabilities['tieWinProbability'] != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProbabilityItem(
                    'Draw',
                    _espnOddsService.formatProbability(probabilities['tieWinProbability']),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityItem(String label, String probability) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            probability,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictorSection() {
    final predictorRaw = oddsData['predictor'];
    final predictor = _safeMapConvert(predictorRaw);
    
    if (predictor.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lightbulb,
                size: 16,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              const Text(
                'ESPN Predictor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (predictor['predictedWinner'] != null) ...[
            Row(
              children: [
                const Text(
                  'Predicted Winner: ',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                Text(
                  predictor['predictedWinner'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (predictor['confidenceScore'] != null) ...[
            Row(
              children: [
                const Text(
                  'Confidence: ',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(predictor['confidenceScore'] * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOddsSection() {
    final oddsRaw = oddsData['odds'];
    final odds = _safeMapConvert(oddsRaw);
    
    if (odds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
                  color: Color(0xFF8E8E93),
                ),
                SizedBox(width: 8),
                Text(
                  'Betting Odds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.chart_bar,
                    size: 32,
                    color: Color(0xFF8E8E93),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Odds not available',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Betting odds may not be available for this game yet',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              CupertinoIcons.money_dollar_circle,
              size: 16,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(width: 8),
            Text(
              'Sportsbook Odds',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...odds.entries.map((entry) => _buildProviderOddsCard(entry.key, entry.value)).toList(),
      ],
    );
  }

  Widget _buildProviderOddsCard(String providerName, dynamic rawProviderOdds) {
    // Safely cast the provider odds to Map<String, dynamic>
    final Map<String, dynamic> providerOdds = _safeMapConvert(rawProviderOdds);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                providerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (providerOdds['lastUpdated'] != null)
                Text(
                  'Updated: ${_formatTimestamp(providerOdds['lastUpdated'])}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOddsTypes(providerOdds),
        ],
      ),
    );
  }

  Widget _buildOddsTypes(Map<String, dynamic> providerOdds) {
    return Column(
      children: [
        if (providerOdds['moneyline'] != null)
          _buildOddsTypeRow('Moneyline', providerOdds['moneyline']),
        if (providerOdds['spread'] != null)
          _buildOddsTypeRow('Spread', providerOdds['spread']),
        if (providerOdds['total'] != null)
          _buildOddsTypeRow('Total', providerOdds['total']),
      ],
    );
  }

  Widget _buildOddsTypeRow(String type, dynamic rawOdds) {
    // Safely cast odds to Map<String, dynamic>
    final Map<String, dynamic> odds = _safeMapConvert(rawOdds);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              type,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildOddsValues(type, odds),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOddsValues(String type, Map<String, dynamic> odds) {
    final List<Widget> widgets = [];
    
    try {
      switch (type) {
        case 'Moneyline':
          // Handle moneyline odds
          if (odds['away'] != null) {
            final awayOdds = odds['away'];
            final display = awayOdds is Map && awayOdds['american'] != null 
                ? awayOdds['american'].toString()
                : _espnOddsService.formatOdds(awayOdds);
            widgets.add(_buildOddsValue('Away', display));
          }
          if (odds['home'] != null) {
            final homeOdds = odds['home'];
            final display = homeOdds is Map && homeOdds['american'] != null 
                ? homeOdds['american'].toString()
                : _espnOddsService.formatOdds(homeOdds);
            widgets.add(_buildOddsValue('Home', display));
          }
          break;
          
        case 'Spread':
          // Handle spread odds
          final spreadValue = odds['spread']?.toString() ?? '0';
          if (odds['away'] != null) {
            final awaySpread = odds['away'];
            final point = awaySpread is Map ? (awaySpread['point']?.toString() ?? '+$spreadValue') : '+$spreadValue';
            final oddsDisplay = awaySpread is Map && awaySpread['odds'] != null 
                ? awaySpread['odds'].toString()
                : 'N/A';
            widgets.add(_buildOddsValue('Away $point', oddsDisplay));
          }
          if (odds['home'] != null) {
            final homeSpread = odds['home'];
            final point = homeSpread is Map ? (homeSpread['point']?.toString() ?? '-$spreadValue') : '-$spreadValue';
            final oddsDisplay = homeSpread is Map && homeSpread['odds'] != null 
                ? homeSpread['odds'].toString()
                : 'N/A';
            widgets.add(_buildOddsValue('Home $point', oddsDisplay));
          }
          break;
          
        case 'Total':
          // Handle totals
          final totalValue = odds['total']?.toString() ?? 'N/A';
          if (odds['over'] != null) {
            final overOdds = odds['over'];
            final oddsDisplay = overOdds is Map && overOdds['american'] != null 
                ? overOdds['american'].toString()
                : _espnOddsService.formatOdds(overOdds);
            widgets.add(_buildOddsValue('Over $totalValue', oddsDisplay));
          }
          if (odds['under'] != null) {
            final underOdds = odds['under'];
            final oddsDisplay = underOdds is Map && underOdds['american'] != null 
                ? underOdds['american'].toString()
                : _espnOddsService.formatOdds(underOdds);
            widgets.add(_buildOddsValue('Under $totalValue', oddsDisplay));
          }
          break;
      }
    } catch (e) {
      print('Error in _buildOddsValues: $e');
      widgets.add(_buildOddsValue('Error', 'N/A'));
    }
    
    return widgets;
  }

  Widget _buildOddsValue(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactOddsRow(Map<String, dynamic> bestOdds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (bestOdds['moneyline'] != null) ...[
          _buildCompactOddsItem('ML', bestOdds['moneyline']),
        ],
        if (bestOdds['spread'] != null) ...[
          _buildCompactOddsItem('Spread', bestOdds['spread']),
        ],
        if (bestOdds['total'] != null) ...[
          _buildCompactOddsItem('Total', bestOdds['total']),
        ],
      ],
    );
  }

  Widget _buildCompactOddsItem(String type, dynamic odds) {
    String display = 'N/A';
    
    try {
      if (odds is Map) {
        if (type == 'ML') {
          // Handle moneyline - get home team odds
          if (odds['home'] != null && odds['home'] is Map) {
            final homeOdds = odds['home'] as Map;
            display = homeOdds['american']?.toString() ?? _espnOddsService.formatOdds(homeOdds['odds']);
          }
        } else if (type == 'Spread') {
          // Handle spread - show the spread value
          final spreadValue = odds['spread']?.toString();
          if (spreadValue != null) {
            display = '±$spreadValue';
          }
        } else if (type == 'Total') {
          // Handle totals - show the total value
          final totalValue = odds['total']?.toString();
          if (totalValue != null) {
            display = 'O/U $totalValue';
          }
        }
      }
    } catch (e) {
      print('Error in _buildCompactOddsItem: $e');
      display = 'N/A';
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          type,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getBestOddsForDisplay(Map<String, dynamic> odds) {
    // For compact display, show the first available odds or preferred provider
    if (odds.isEmpty) return {};
    
    // Check for preferred providers first
    if (widget.preferredProviders != null) {
      for (final providerId in widget.preferredProviders!) {
        // Use provider ID to name mapping from ESPN odds service
        final providerNames = {
          2000: 'Bet365',
          38: 'Caesars', 
          31: 'William Hill',
          36: 'Unibet',
          25: 'Westgate',
          58: 'ESPN BET',
          59: 'ESPN BET - Live Odds',
        };
        final providerName = providerNames[providerId];
        if (providerName != null && odds.containsKey(providerName)) {
          final oddsData = odds[providerName];
          return _safeMapConvert(oddsData);
        }
      }
    }
    
    // Otherwise, return the first available, ensuring it's the right type
    final firstValue = odds.values.first;
    return _safeMapConvert(firstValue);
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  /// Safely converts any Map type to Map<String, dynamic>
  /// This handles LinkedMap, Map<dynamic, dynamic>, and other Map types
  /// that can cause type casting errors in Flutter apps
  Map<String, dynamic> _safeMapConvert(dynamic data) {
    if (data == null) return <String, dynamic>{};
    
    if (data is Map<String, dynamic>) {
      return data;
    }
    
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        // If direct conversion fails, try manual conversion
        final Map<String, dynamic> result = {};
        data.forEach((key, value) {
          final stringKey = key?.toString() ?? '';
          if (stringKey.isNotEmpty) {
            result[stringKey] = value;
          }
        });
        return result;
      }
    }
    
    return <String, dynamic>{};
  }

  /// Recursively converts nested Maps to ensure proper typing
  Map<String, dynamic> _deepMapConvert(dynamic data) {
    if (data == null) return <String, dynamic>{};
    
    if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key?.toString() ?? '';
        if (stringKey.isNotEmpty) {
          if (value is Map) {
            result[stringKey] = _deepMapConvert(value);
          } else if (value is List) {
            result[stringKey] = value.map((item) => 
              item is Map ? _deepMapConvert(item) : item
            ).toList();
          } else {
            result[stringKey] = value;
          }
        }
      });
      return result;
    }
    
    return <String, dynamic>{};
  }
} 