// Import Flutter material library for UI components - provides widgets and styling
import 'package:flutter/material.dart';
// Import PickPost model for betting picks - provides data structure for picks
import '../models/pick_post.dart';

// Widget that displays a list of betting picks with different layout options - shows user's betting selections
class PicksDisplayWidget extends StatelessWidget {
  // List of betting picks to display - contains all the picks to show
  final List<Pick> picks;
  // Whether to show parlay badge for multiple picks - indicates if this is a parlay bet
  final bool showParlayBadge;
  // Whether to use compact layout - controls display density
  final bool compact;

  // Constructor that initializes all widget properties - creates new PicksDisplayWidget
  const PicksDisplayWidget({
    Key? key,
    required this.picks,
    this.showParlayBadge = true,
    this.compact = false,
  }) : super(key: key);

  // Build the widget UI - creates the visual representation of the picks
  @override
  Widget build(BuildContext context) {
    // Return empty widget if no picks to display - handles empty state
    if (picks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine if this is a parlay (multiple picks) - checks if multiple picks exist
    final isParlay = picks.length > 1;

    // Return column layout with picks - creates the main widget structure
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parlay badge (only show if requested and it's a parlay) - displays parlay indicator
        if (showParlayBadge && isParlay) ...[
          // Container for parlay badge styling - creates visual badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2), // Semi-transparent green background
              borderRadius: BorderRadius.circular(16), // Rounded corners
              border: Border.all(color: Colors.green.withOpacity(0.5)), // Green border
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Only take needed space
              children: [
                const Icon(Icons.layers, color: Colors.green, size: 18), // Layers icon for parlay
                const SizedBox(width: 4), // Small spacing
                Text(
                  '${picks.length}-Leg Parlay', // Display parlay leg count
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                // Show calculated parlay odds if available - displays combined odds
                if (_getParlayOdds(picks) != null) ...[
                  const SizedBox(width: 8), // Spacing between text and odds
                  Text(
                    _getParlayOdds(picks)!, // Display calculated parlay odds
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
          const SizedBox(height: 12), // Spacing after parlay badge
        ],
        
        // Picks list - displays all individual picks
        if (compact) ...[
          // Compact version for profile page - uses smaller, condensed layout
          ...picks.asMap().entries.map<Widget>((entry) {
            final index = entry.key; // Get pick index
            final pick = entry.value; // Get pick object
            return _buildCompactPickCard(pick, index); // Build compact card
          }).toList(),
        ] else ...[
          // Full version for social feed - uses larger, detailed layout
          ...picks.asMap().entries.map<Widget>((entry) {
            final index = entry.key; // Get pick index
            final pick = entry.value; // Get pick object
            return _buildFullPickCard(pick, index); // Build full card
          }).toList(),
        ],
      ],
    );
  }

  // Build compact pick card for profile page - creates condensed pick display
  Widget _buildCompactPickCard(Pick pick, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Bottom margin for spacing
      padding: const EdgeInsets.all(12), // Internal padding
      decoration: BoxDecoration(
        color: Colors.grey[800], // Dark background
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(
          color: Colors.green.withOpacity(0.3), // Green border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_basketball, color: Colors.green, size: 16), // Sport icon
              const SizedBox(width: 8), // Spacing after icon
              Expanded(
                child: Text(
                  '${pick.game.awayTeam} @ ${pick.game.homeTeam}', // Team matchup
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                pick.game.sport.toUpperCase(), // Sport name
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Spacing after header
          Text(
            pick.displayText, // Pick details (bet type, team, odds)
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Show reasoning if available - displays user's betting logic
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 4), // Small spacing
            Text(
              pick.reasoning!, // User's reasoning for the pick
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic, // Italic for reasoning
              ),
            ),
          ],
          const SizedBox(height: 4), // Small spacing
          Text(
            pick.game.formattedGameTime, // Game time
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Build full pick card for social feed - creates detailed pick display
  Widget _buildFullPickCard(Pick pick, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Bottom margin for spacing
      padding: const EdgeInsets.all(16), // Internal padding
      decoration: BoxDecoration(
        color: Colors.grey[800], // Dark background
        borderRadius: BorderRadius.circular(8), // Rounded corners
        border: Border.all(
          color: Colors.green.withOpacity(0.3), // Green border
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
                      '${pick.game.awayTeam} @ ${pick.game.homeTeam}', // Team matchup
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4), // Small spacing
                    Text(
                      '${pick.game.formattedGameTime} • ${pick.game.sport}', // Time and sport
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
          const SizedBox(height: 12), // Spacing after header
          // Container for pick details with highlighted background
          Container(
            padding: const EdgeInsets.all(12), // Internal padding
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1), // Light green background
              borderRadius: BorderRadius.circular(8), // Rounded corners
              border: Border.all(
                color: Colors.green.withOpacity(0.3), // Green border
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between elements
              children: [
                Expanded(
                  child: Text(
                    pick.displayText, // Pick details (bet type, team, odds)
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Container for odds display with yellow highlighting
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.2), // Light yellow background
                    borderRadius: BorderRadius.circular(6), // Rounded corners
                  ),
                  child: Text(
                    pick.odds, // Display the odds
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
          // Show reasoning if available - displays user's betting logic
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[
            const SizedBox(height: 8), // Spacing before reasoning
            Text(
              pick.reasoning!, // User's reasoning for the pick
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                fontStyle: FontStyle.italic, // Italic for reasoning
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for parlay odds calculation - calculates combined odds for multiple picks
  String? _getParlayOdds(List<Pick> picks) {
    // Return null if not enough picks for parlay - handles single pick case
    if (picks.length < 2) return null;
    // Start with 1.0 for multiplication - initial value for odds calculation
    double product = 1.0;
    // Multiply all decimal odds together - calculates combined parlay odds
    for (var pick in picks) {
      double decimal = _americanToDecimal(pick.odds); // Convert American to decimal
      product *= decimal; // Multiply with running product
    }
    // Convert back to American odds format - returns readable odds format
    return _decimalToAmerican(product);
  }

  // Convert American odds to decimal format - handles positive and negative odds
  double _americanToDecimal(String americanOdds) {
    int odds = int.tryParse(americanOdds) ?? 0; // Parse odds string to integer
    if (odds > 0) {
      // Positive odds conversion - calculates decimal for positive American odds
      return (odds / 100) + 1;
    } else {
      // Negative odds conversion - calculates decimal for negative American odds
      return (100 / odds.abs()) + 1;
    }
  }

  // Convert decimal odds to American format - handles positive and negative results
  String _decimalToAmerican(double decimal) {
    if (decimal >= 2) {
      // Positive American odds - returns positive odds format
      return '+${((decimal - 1) * 100).round()}';
    } else {
      // Negative American odds - returns negative odds format
      return '-${(100 / (1 - decimal)).round()}';
    }
  }
} 