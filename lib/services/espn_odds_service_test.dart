import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'espn_odds_service.dart';

/// Simple test for ESPN Odds Service
/// 
/// This can be run to verify that the odds parsing logic works correctly
/// with different ESPN API response formats.
void main() async {
  final service = ESPNOddsService();
  
  print('=== ESPN Odds Service Test ===');
  
  // Test with a sample MLB game ID
  try {
    print('Testing with sample MLB game (Giants vs Blue Jays)...');
    final result = await service.fetchGameOdds('401696382', 'baseball/mlb');
    
    print('Result keys: ${result.keys.toList()}');
    
    if (result['odds'] != null) {
      print('Odds data type: ${result['odds'].runtimeType}');
      print('Odds available: ${result['odds'] is Map && (result['odds'] as Map).isNotEmpty}');
      
      if (result['odds'] is Map && (result['odds'] as Map).isNotEmpty) {
        final odds = result['odds'] as Map;
        print('Sportsbooks available: ${odds.keys.toList()}');
      }
    }
    
    if (result['predictor'] != null) {
      print('Predictor data available: ${result['predictor'] is Map && (result['predictor'] as Map).isNotEmpty}');
    }
    
    if (result['winprobability'] != null) {
      print('Win probability data available: ${result['winprobability'] is Map && (result['winprobability'] as Map).isNotEmpty}');
    }
    
    print('✅ Test completed successfully');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
