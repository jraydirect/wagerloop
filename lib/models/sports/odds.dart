import 'sportsbook.dart';

class OddsData {
  final Sportsbook sportsbook;
  final Map<String, dynamic>? moneyline;
  final Map<String, dynamic>? spread;
  final Map<String, dynamic>? total;
  final DateTime lastUpdated;
  final int? homeScore;
  final int? awayScore;
  final String? period;

  OddsData({
    required this.sportsbook,
    this.moneyline,
    this.spread,
    this.total,
    required this.lastUpdated,
    this.homeScore,
    this.awayScore,
    this.period,
  });

  factory OddsData.fromJson(Map<String, dynamic> json) {
    return OddsData(
      sportsbook: Sportsbook.fromJson(json['sportsbook']),
      moneyline: json['moneyline'],
      spread: json['spread'],
      total: json['total'],
      lastUpdated: DateTime.parse(json['last_updated']),
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      period: json['period'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sportsbook': sportsbook.toJson(),
      'moneyline': moneyline,
      'spread': spread,
      'total': total,
      'last_updated': lastUpdated.toIso8601String(),
      'home_score': homeScore,
      'away_score': awayScore,
      'period': period,
    };
  }

  /// Get formatted spread with odds for display
  String getSpreadDisplay(String side) {
    if (spread == null || !spread!.containsKey(side)) {
      return 'N/A';
    }
    
    try {
      final point = spread![side]?['point'];
      final price = spread![side]?['price'];
      
      if (point == null || price == null) {
        return 'N/A';
      }
      
      // Convert to the right types
      final pointValue = (point is double) ? point : (point is int) ? point.toDouble() : null;
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null;
      
      if (pointValue == null || priceValue == null) {
        return 'N/A';
      }
      
      final pointSign = pointValue >= 0 ? '+' : '';
      return '$pointSign$pointValue ($priceValue)';
    } catch (e) {
      // Return a default value if we encounter any parsing errors
      return 'N/A';
    }
  }

  /// Get formatted moneyline for display
  String getMoneylineDisplay(String side) {
    if (moneyline == null || !moneyline!.containsKey(side)) {
      return 'N/A';
    }
    
    try {
      final price = moneyline![side];
      
      if (price == null) {
        return 'N/A';
      }
      
      // Convert to the right type
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null;
      
      if (priceValue == null) {
        return 'N/A';
      }
      
      final sign = priceValue >= 0 ? '+' : '';
      return '$sign$priceValue';
    } catch (e) {
      // Return a default value if we encounter any parsing errors
      return 'N/A';
    }
  }

  /// Get formatted total with odds for display
  String getTotalDisplay(String side) {
    if (total == null || !total!.containsKey(side)) {
      return 'N/A';
    }
    
    try {
      final point = total![side]?['point'];
      final price = total![side]?['price'];
      
      if (point == null || price == null) {
        return 'N/A';
      }
      
      // Convert to the right types
      final pointValue = (point is double) ? point : (point is int) ? point.toDouble() : null;
      final priceValue = (price is int) ? price : (price is String) ? int.tryParse(price) : null;
      
      if (pointValue == null || priceValue == null) {
        return 'N/A';
      }
      
      return '${side.capitalize()} $pointValue ($priceValue)';
    } catch (e) {
      // Return a default value if we encounter any parsing errors
      return 'N/A';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
