import 'package:flutter/material.dart';
import '../models/pick_post.dart';

class PicksDisplayWidget extends StatelessWidget {
  final List<Pick> picks;
  final bool showParlayBadge;
  final bool compact;

  const PicksDisplayWidget({
    Key? key,
    required this.picks,
    this.showParlayBadge = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (picks.isEmpty) {
      return const SizedBox.shrink();
    }

    final isParlay = picks.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parlay badge (only show if requested and it's a parlay)
        if (showParlayBadge && isParlay) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${picks.length}-Leg Parlay',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (_getParlayOdds(picks) != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _getParlayOdds(picks)!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Picks list
        if (compact) ...[
          // Compact version for profile page
          ...picks.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final pick = entry.value;
            return _buildCompactPickCard(pick, index);
          }).toList(),
        ] else ...[
          // Full version for social feed
          ...picks.asMap().entries.map<Widget>((entry) {
            final index = entry.key;
            final pick = entry.value;
            return _buildFullPickCard(pick, index);
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildCompactPickCard(Pick pick, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_basketball, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                pick.game.sport.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pick.displayText,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pick.reasoning!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            pick.game.formattedGameTime,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPickCard(Pick pick, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
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
                    Text(
                      '${pick.game.awayTeam} @ ${pick.game.homeTeam}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pick.game.formattedGameTime} • ${pick.game.sport}',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
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
                    pick.displayText,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              pick.reasoning!,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for parlay odds calculation
  String? _getParlayOdds(List<Pick> picks) {
    if (picks.length < 2) return null;
    double product = 1.0;
    for (var pick in picks) {
      double decimal = _americanToDecimal(pick.odds);
      product *= decimal;
    }
    return _decimalToAmerican(product);
  }

  double _americanToDecimal(String americanOdds) {
    int odds = int.tryParse(americanOdds) ?? 0;
    if (odds > 0) {
      return (odds / 100) + 1;
    } else {
      return (100 / odds.abs()) + 1;
    }
  }

  String _decimalToAmerican(double decimal) {
    if (decimal >= 2) {
      return '+${((decimal - 1) * 100).round()}';
    } else {
      return '-${(100 / (1 - decimal)).round()}';
    }
  }
} 