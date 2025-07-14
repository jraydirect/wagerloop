import 'package:flutter/material.dart'; // Import Flutter's core material design widgets and framework
import '../models/pick_post.dart'; // Import the Pick model class for use in displaying picks

class PicksDisplayWidget extends StatelessWidget { // Define PicksDisplayWidget as a stateless widget for displaying betting picks
  final List<Pick> picks; // Declare final list field for the picks to display
  final bool showParlayBadge; // Declare boolean field for whether to show parlay badge
  final bool compact; // Declare boolean field for whether to use compact display mode

  const PicksDisplayWidget({ // Constructor for PicksDisplayWidget with required and optional parameters
    Key? key, // Optional key parameter for widget identification
    required this.picks, // Initialize required picks parameter
    this.showParlayBadge = true, // Initialize showParlayBadge parameter with default value of true
    this.compact = false, // Initialize compact parameter with default value of false
  }) : super(key: key); // Call parent constructor with key

  @override // Override the build method from StatelessWidget
  Widget build(BuildContext context) { // Build method that returns the widget tree for the picks display
    if (picks.isEmpty) { // Check if picks list is empty
      return const SizedBox.shrink(); // Return empty widget if no picks to display
    } // End of empty picks check

    final isParlay = picks.length > 1; // Determine if this is a parlay bet (multiple picks)

    return Column( // Return a column layout for the picks display
      crossAxisAlignment: CrossAxisAlignment.start, // Align column children to the start (left)
      children: [ // List of widgets to display in the column
        // Parlay badge (only show if requested and it's a parlay)
        if (showParlayBadge && isParlay) ...[ // Conditionally show parlay badge if requested and is parlay
          Container( // Create a container for the parlay badge
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Set padding for badge content
            decoration: BoxDecoration( // Define decoration for the badge container
              color: Colors.green.withOpacity(0.2), // Set background color to semi-transparent green
              borderRadius: BorderRadius.circular(16), // Set border radius to 16 pixels for rounded corners
              border: Border.all(color: Colors.green.withOpacity(0.5)), // Set border to semi-transparent green
            ), // End of BoxDecoration
            child: Row( // Create a row layout for badge content
              mainAxisSize: MainAxisSize.min, // Set row to minimum size
              children: [ // List of widgets to display in the row
                const Icon(Icons.layers, color: Colors.green, size: 18), // Add layers icon with green color and 18px size
                const SizedBox(width: 4), // Add horizontal spacing of 4 pixels
                Text( // Display text for parlay description
                  '${picks.length}-Leg Parlay', // Show number of legs in the parlay
                  style: const TextStyle( // Define text style for parlay text
                    color: Colors.green, // Set text color to green
                    fontWeight: FontWeight.bold, // Set font weight to bold
                    fontSize: 14, // Set font size to 14 pixels
                  ), // End of TextStyle
                ), // End of parlay text
                if (_getParlayOdds(picks) != null) ...[ // Conditionally show parlay odds if available
                  const SizedBox(width: 8), // Add horizontal spacing of 8 pixels
                  Text( // Display text for parlay odds
                    _getParlayOdds(picks)!, // Get calculated parlay odds (non-null assertion)
                    style: const TextStyle( // Define text style for odds text
                      color: Colors.green, // Set text color to green
                      fontWeight: FontWeight.bold, // Set font weight to bold
                      fontSize: 14, // Set font size to 14 pixels
                    ), // End of TextStyle
                  ), // End of odds text
                ], // End of conditional odds widgets
              ], // End of row children
            ), // End of row widget
          ), // End of container widget
          const SizedBox(height: 12), // Add vertical spacing of 12 pixels after badge
        ], // End of conditional parlay badge widgets
        
        // Picks list
        if (compact) ...[ // Conditionally use compact version for profile page
          // Compact version for profile page
          ...picks.asMap().entries.map<Widget>((entry) { // Map picks with index to widgets
            final index = entry.key; // Get the index of the pick
            final pick = entry.value; // Get the pick object
            return _buildCompactPickCard(pick, index); // Build compact pick card
          }).toList(), // Convert mapped entries to list
        ] else ...[ // Use full version for social feed
          // Full version for social feed
          ...picks.asMap().entries.map<Widget>((entry) { // Map picks with index to widgets
            final index = entry.key; // Get the index of the pick
            final pick = entry.value; // Get the pick object
            return _buildFullPickCard(pick, index); // Build full pick card
          }).toList(), // Convert mapped entries to list
        ], // End of conditional display mode widgets
      ], // End of column children
    ); // End of column widget
  } // End of build method

  Widget _buildCompactPickCard(Pick pick, int index) { // Define method to build compact pick card widget
    return Container( // Return a container for the compact pick card
      margin: const EdgeInsets.only(bottom: 8), // Set bottom margin of 8 pixels
      padding: const EdgeInsets.all(12), // Set padding of 12 pixels on all sides
      decoration: BoxDecoration( // Define decoration for the pick card container
        color: Colors.grey[800], // Set background color to dark gray
        borderRadius: BorderRadius.circular(8), // Set border radius to 8 pixels
        border: Border.all( // Set border for the container
          color: Colors.green.withOpacity(0.3), // Set border color to semi-transparent green
        ), // End of border definition
      ), // End of BoxDecoration
      child: Column( // Create a column layout for pick card content
        crossAxisAlignment: CrossAxisAlignment.start, // Align column children to the start (left)
        children: [ // List of widgets to display in the column
          Row( // Create a row for the game header
            children: [ // List of widgets to display in the row
              const Icon(Icons.sports_basketball, color: Colors.green, size: 16), // Add basketball icon with green color and 16px size
              const SizedBox(width: 8), // Add horizontal spacing of 8 pixels
              Expanded( // Use expanded to take available space
                child: Text( // Display text for team matchup
                  '${pick.game.awayTeam} @ ${pick.game.homeTeam}', // Show away team at home team format
                  style: const TextStyle( // Define text style for matchup
                    color: Colors.white, // Set text color to white
                    fontWeight: FontWeight.bold, // Set font weight to bold
                    fontSize: 14, // Set font size to 14 pixels
                  ), // End of TextStyle
                ), // End of matchup text
              ), // End of expanded widget
              Text( // Display text for sport type
                pick.game.sport.toUpperCase(), // Show sport name in uppercase
                style: TextStyle( // Define text style for sport
                  color: Colors.grey[400], // Set text color to gray
                  fontSize: 12, // Set font size to 12 pixels
                ), // End of TextStyle
              ), // End of sport text
            ], // End of row children
          ), // End of row widget
          const SizedBox(height: 8), // Add vertical spacing of 8 pixels
          Text( // Display text for pick details
            pick.displayText, // Show formatted pick display text
            style: const TextStyle( // Define text style for pick text
              color: Colors.green, // Set text color to green
              fontWeight: FontWeight.bold, // Set font weight to bold
            ), // End of TextStyle
          ), // End of pick text
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[ // Conditionally show reasoning if available
            const SizedBox(height: 4), // Add vertical spacing of 4 pixels
            Text( // Display text for pick reasoning
              pick.reasoning!, // Show pick reasoning (non-null assertion)
              style: TextStyle( // Define text style for reasoning
                color: Colors.grey[300], // Set text color to light gray
                fontSize: 12, // Set font size to 12 pixels
                fontStyle: FontStyle.italic, // Set font style to italic
              ), // End of TextStyle
            ), // End of reasoning text
          ], // End of conditional reasoning widgets
          const SizedBox(height: 4), // Add vertical spacing of 4 pixels
          Text( // Display text for game time
            pick.game.formattedGameTime, // Show formatted game time
            style: TextStyle( // Define text style for game time
              color: Colors.grey[400], // Set text color to gray
              fontSize: 12, // Set font size to 12 pixels
            ), // End of TextStyle
          ), // End of game time text
        ], // End of column children
      ), // End of column widget
    ); // End of container widget
  } // End of _buildCompactPickCard method

  Widget _buildFullPickCard(Pick pick, int index) { // Define method to build full pick card widget
    return Container( // Return a container for the full pick card
      margin: const EdgeInsets.only(bottom: 12), // Set bottom margin of 12 pixels
      padding: const EdgeInsets.all(16), // Set padding of 16 pixels on all sides
      decoration: BoxDecoration( // Define decoration for the pick card container
        color: Colors.grey[800], // Set background color to dark gray
        borderRadius: BorderRadius.circular(8), // Set border radius to 8 pixels
        border: Border.all( // Set border for the container
          color: Colors.green.withOpacity(0.3), // Set border color to semi-transparent green
        ), // End of border definition
      ), // End of BoxDecoration
      child: Column( // Create a column layout for pick card content
        crossAxisAlignment: CrossAxisAlignment.start, // Align column children to the start (left)
        children: [ // List of widgets to display in the column
          Row( // Create a row for the game header
            children: [ // List of widgets to display in the row
              Expanded( // Use expanded to take available space
                child: Column( // Create a column for game information
                  crossAxisAlignment: CrossAxisAlignment.start, // Align column children to the start (left)
                  children: [ // List of widgets to display in the column
                    Text( // Display text for team matchup
                      '${pick.game.awayTeam} @ ${pick.game.homeTeam}', // Show away team at home team format
                      style: const TextStyle( // Define text style for matchup
                        color: Colors.white, // Set text color to white
                        fontWeight: FontWeight.bold, // Set font weight to bold
                        fontSize: 16, // Set font size to 16 pixels
                      ), // End of TextStyle
                    ), // End of matchup text
                    const SizedBox(height: 4), // Add vertical spacing of 4 pixels
                    Text( // Display text for game time and sport
                      '${pick.game.formattedGameTime} • ${pick.game.sport}', // Show formatted game time and sport
                      style: TextStyle( // Define text style for game info
                        color: Colors.grey[400], // Set text color to gray
                        fontSize: 12, // Set font size to 12 pixels
                      ), // End of TextStyle
                    ), // End of game info text
                  ], // End of inner column children
                ), // End of inner column widget
              ), // End of expanded widget
            ], // End of row children
          ), // End of row widget
          const SizedBox(height: 12), // Add vertical spacing of 12 pixels
          Container( // Create a container for the pick details
            padding: const EdgeInsets.all(12), // Set padding of 12 pixels on all sides
            decoration: BoxDecoration( // Define decoration for the pick container
              color: Colors.green.withOpacity(0.1), // Set background color to semi-transparent green
              borderRadius: BorderRadius.circular(8), // Set border radius to 8 pixels
              border: Border.all( // Set border for the container
                color: Colors.green.withOpacity(0.3), // Set border color to semi-transparent green
              ), // End of border definition
            ), // End of BoxDecoration
            child: Row( // Create a row for pick details and odds
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between pick details and odds
              children: [ // List of widgets to display in the row
                Expanded( // Use expanded to take available space for pick text
                  child: Text( // Display text for pick details
                    pick.displayText, // Show formatted pick display text
                    style: const TextStyle( // Define text style for pick text
                      color: Colors.green, // Set text color to green
                      fontWeight: FontWeight.bold, // Set font weight to bold
                      fontSize: 14, // Set font size to 14 pixels
                    ), // End of TextStyle
                  ), // End of pick text
                ), // End of expanded widget
                Container( // Create a container for the odds badge
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Set padding for odds badge
                  decoration: BoxDecoration( // Define decoration for the odds container
                    color: Colors.yellow.withOpacity(0.2), // Set background color to semi-transparent yellow
                    borderRadius: BorderRadius.circular(6), // Set border radius to 6 pixels
                  ), // End of BoxDecoration
                  child: Text( // Display text for odds
                    pick.odds, // Show the odds value
                    style: const TextStyle( // Define text style for odds
                      color: Colors.yellow, // Set text color to yellow
                      fontWeight: FontWeight.bold, // Set font weight to bold
                      fontSize: 14, // Set font size to 14 pixels
                    ), // End of TextStyle
                  ), // End of odds text
                ), // End of odds container
              ], // End of row children
            ), // End of row widget
          ), // End of pick details container
          if (pick.reasoning != null && pick.reasoning!.isNotEmpty) ...[ // Conditionally show reasoning if available
            const SizedBox(height: 8), // Add vertical spacing of 8 pixels
            Text( // Display text for pick reasoning
              pick.reasoning!, // Show pick reasoning (non-null assertion)
              style: TextStyle( // Define text style for reasoning
                color: Colors.grey[300], // Set text color to light gray
                fontSize: 12, // Set font size to 12 pixels
                fontStyle: FontStyle.italic, // Set font style to italic
              ), // End of TextStyle
            ), // End of reasoning text
          ], // End of conditional reasoning widgets
        ], // End of column children
      ), // End of column widget
    ); // End of container widget
  } // End of _buildFullPickCard method

  // Helper methods for parlay odds calculation
  String? _getParlayOdds(List<Pick> picks) { // Define method to calculate parlay odds from multiple picks
    if (picks.length < 2) return null; // Return null if less than 2 picks (not a parlay)
    double product = 1.0; // Initialize product for decimal odds multiplication
    for (var pick in picks) { // Iterate through each pick in the list
      double decimal = _americanToDecimal(pick.odds); // Convert American odds to decimal odds
      product *= decimal; // Multiply the decimal odds to get parlay odds
    } // End of picks iteration
    return _decimalToAmerican(product); // Convert final decimal odds back to American format
  } // End of _getParlayOdds method

  double _americanToDecimal(String americanOdds) { // Define method to convert American odds to decimal odds
    int odds = int.tryParse(americanOdds) ?? 0; // Parse American odds string to integer with 0 as default
    if (odds > 0) { // Check if odds are positive (underdog)
      return (odds / 100) + 1; // Convert positive American odds to decimal
    } else { // Odds are negative (favorite)
      return (100 / odds.abs()) + 1; // Convert negative American odds to decimal
    } // End of odds sign check
  } // End of _americanToDecimal method

  String _decimalToAmerican(double decimal) { // Define method to convert decimal odds to American odds
    if (decimal >= 2) { // Check if decimal odds are 2 or greater (positive American odds)
      return '+${((decimal - 1) * 100).round()}'; // Convert to positive American odds format
    } else { // Decimal odds are less than 2 (negative American odds)
      return '-${(100 / (1 - decimal)).round()}'; // Convert to negative American odds format
    } // End of decimal odds check
  } // End of _decimalToAmerican method
} // End of PicksDisplayWidget class 