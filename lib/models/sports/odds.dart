import 'sportsbook.dart'; // Import the Sportsbook model class for use in odds data

class OddsData { // Define OddsData class as a data model for sports betting odds
  final Sportsbook sportsbook; // Declare final Sportsbook field for the sportsbook providing the odds
  final Map<String, dynamic>? moneyline; // Declare optional Map field for moneyline betting odds
  final Map<String, dynamic>? spread; // Declare optional Map field for point spread betting odds
  final Map<String, dynamic>? total; // Declare optional Map field for total/over-under betting odds
  final DateTime lastUpdated; // Declare final DateTime field for when the odds were last updated
  final int? homeScore; // Declare optional int field for the home team's current score
  final int? awayScore; // Declare optional int field for the away team's current score
  final String? period; // Declare optional string field for the current game period

  OddsData({ // Constructor for OddsData class with required and optional parameters
    required this.sportsbook, // Initialize required sportsbook parameter
    this.moneyline, // Initialize optional moneyline parameter
    this.spread, // Initialize optional spread parameter
    this.total, // Initialize optional total parameter
    required this.lastUpdated, // Initialize required lastUpdated parameter
    this.homeScore, // Initialize optional homeScore parameter
    this.awayScore, // Initialize optional awayScore parameter
    this.period, // Initialize optional period parameter
  }); // End of constructor

  factory OddsData.fromJson(Map<String, dynamic> json) { // Define factory constructor to create OddsData from JSON
    return OddsData( // Return a new OddsData instance
      sportsbook: Sportsbook.fromJson(json['sportsbook']), // Create Sportsbook instance from 'sportsbook' JSON
      moneyline: json['moneyline'], // Extract moneyline from 'moneyline' key
      spread: json['spread'], // Extract spread from 'spread' key
      total: json['total'], // Extract total from 'total' key
      lastUpdated: DateTime.parse(json['last_updated']), // Parse lastUpdated from 'last_updated' key
      homeScore: json['home_score'], // Extract homeScore from 'home_score' key
      awayScore: json['away_score'], // Extract awayScore from 'away_score' key
      period: json['period'], // Extract period from 'period' key
    ); // End of OddsData constructor call
  } // End of fromJson factory constructor

  Map<String, dynamic> toJson() { // Define method to convert OddsData instance to JSON
    return { // Return a Map with odds data properties
      'sportsbook': sportsbook.toJson(), // Convert sportsbook to JSON and map to 'sportsbook' key
      'moneyline': moneyline, // Map moneyline field to 'moneyline' key
      'spread': spread, // Map spread field to 'spread' key
      'total': total, // Map total field to 'total' key
      'last_updated': lastUpdated.toIso8601String(), // Convert lastUpdated to ISO string and map to 'last_updated' key
      'home_score': homeScore, // Map homeScore field to 'home_score' key
      'away_score': awayScore, // Map awayScore field to 'away_score' key
      'period': period, // Map period field to 'period' key
    }; // End of Map literal
  } // End of toJson method

  /// Get formatted spread with odds for display
  String getSpreadDisplay(String side) { // Define method to get formatted spread display for a specific side
    if (spread == null || !spread!.containsKey(side)) { // Check if spread is null or doesn't contain the side
      return 'N/A'; // Return 'N/A' if spread data is not available
    } // End of spread availability check
    
    try { // Begin try block for error handling
      final point = spread![side]?['point']; // Extract point value from the spread data for the side
      final price = spread![side]?['price']; // Extract price value from the spread data for the side
      
      if (point == null || price == null) { // Check if point or price is null
        return 'N/A'; // Return 'N/A' if either value is missing
      } // End of null check
      
      // Convert to the right types
      final pointValue = (point is double) ? point : (point is int) ? point.toDouble() : null; // Convert point to double with type checking
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null; // Convert price to int with type checking
      
      if (pointValue == null || priceValue == null) { // Check if type conversion was successful
        return 'N/A'; // Return 'N/A' if conversion failed
      } // End of conversion check
      
      final pointSign = pointValue >= 0 ? '+' : ''; // Add '+' sign for positive point values
      return '$pointSign$pointValue ($priceValue)'; // Return formatted string with point and price
    } catch (e) { // Catch any exceptions during processing
      // Return a default value if we encounter any parsing errors
      return 'N/A'; // Return 'N/A' if any error occurs
    } // End of try-catch block
  } // End of getSpreadDisplay method

  /// Get formatted moneyline for display
  String getMoneylineDisplay(String side) { // Define method to get formatted moneyline display for a specific side
    if (moneyline == null || !moneyline!.containsKey(side)) { // Check if moneyline is null or doesn't contain the side
      return 'N/A'; // Return 'N/A' if moneyline data is not available
    } // End of moneyline availability check
    
    try { // Begin try block for error handling
      final price = moneyline![side]; // Extract price value from the moneyline data for the side
      
      if (price == null) { // Check if price is null
        return 'N/A'; // Return 'N/A' if price is missing
      } // End of null check
      
      // Convert to the right type
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null; // Convert price to int with type checking
      
      if (priceValue == null) { // Check if type conversion was successful
        return 'N/A'; // Return 'N/A' if conversion failed
      } // End of conversion check
      
      final sign = priceValue >= 0 ? '+' : ''; // Add '+' sign for positive price values
      return '$sign$priceValue'; // Return formatted string with price and sign
    } catch (e) { // Catch any exceptions during processing
      // Return a default value if we encounter any parsing errors
      return 'N/A'; // Return 'N/A' if any error occurs
    } // End of try-catch block
  } // End of getMoneylineDisplay method

  /// Get formatted total with odds for display
  String getTotalDisplay(String side) { // Define method to get formatted total display for a specific side
    if (total == null || !total!.containsKey(side)) { // Check if total is null or doesn't contain the side
      return 'N/A'; // Return 'N/A' if total data is not available
    } // End of total availability check
    
    try { // Begin try block for error handling
      final point = total![side]?['point']; // Extract point value from the total data for the side
      final price = total![side]?['price']; // Extract price value from the total data for the side
      
      if (point == null || price == null) { // Check if point or price is null
        return 'N/A'; // Return 'N/A' if either value is missing
      } // End of null check
      
      // Convert to the right types
      final pointValue = (point is double) ? point : (point is int) ? point.toDouble() : null; // Convert point to double with type checking
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null; // Convert price to int with type checking
      
      if (pointValue == null || priceValue == null) { // Check if type conversion was successful
        return 'N/A'; // Return 'N/A' if conversion failed
      } // End of conversion check
      
      return '${side.capitalize()} $pointValue ($priceValue)'; // Return formatted string with capitalized side, point, and price
    } catch (e) { // Catch any exceptions during processing
      // Return a default value if we encounter any parsing errors
      return 'N/A'; // Return 'N/A' if any error occurs
    } // End of try-catch block
  } // End of getTotalDisplay method
} // End of OddsData class

extension StringExtension on String { // Define extension on String class to add capitalize functionality
  String capitalize() { // Define method to capitalize the first letter of a string
    return "${this[0].toUpperCase()}${this.substring(1)}"; // Return string with first letter capitalized and rest unchanged
  } // End of capitalize method
} // End of StringExtension
