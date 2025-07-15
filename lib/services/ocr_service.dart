import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sports/game.dart';

/// Service for extracting betting information from images using OCR
/// 
/// This service uses Google Vision API to extract text from betting slips
/// and then parses the text to identify teams, odds, and bet types.
class OcrService {
  /// Gets the Google Vision API key from environment variables
  static String? get _apiKey => dotenv.env['GOOGLE_VISION_API_KEY'];
  
  /// Gets the Vision API URL with the API key
  static String? get _visionApiUrl {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) return null;
    return 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
  }

  /// Extracts text from an image using Google Vision API
  /// Falls back to mock data for development when API key is not configured
  Future<String?> extractTextFromImage(dynamic imageFile) async {
    try {
      
      // Check if API key is configured
      final apiKey = _apiKey;
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_google_vision_api_key_here') {
        // Return mock betting slip text for development
        return _getMockBettingSlipText();
      }
      
      // Convert image to base64
      Uint8List imageBytes;
      if (kIsWeb && imageFile is XFile) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        // For mobile, we'd need to handle File differently
        // For now, we'll focus on web implementation
        return null;
      }
      
      final base64Image = base64Encode(imageBytes);
      
      // Prepare the request body for Google Vision API
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              },
            ],
          },
        ],
      };

      // Make the API request
      final visionApiUrl = _visionApiUrl;
      if (visionApiUrl == null) {
        return null;
      }
      
      final response = await http.post(
        Uri.parse(visionApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textAnnotations = data['responses'][0]['textAnnotations'];
        
        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          final extractedText = textAnnotations[0]['description'] as String;
          return extractedText;
        }
      } else {
        // print('OCR API error: ${response.statusCode} - ${response.body}');
      }
      
      return null;
    } catch (e) {
      // print('Error in OCR text extraction: $e');
      return null;
    }
  }

  /// Returns mock betting slip text for development
  String _getMockBettingSlipText() {
    // Simulate different betting slip formats
    final mockSlips = [
      '''
Lakers vs Warriors
Moneyline +150
      ''',
      '''
Chiefs -110
Bills +120
Spread
      ''',
      '''
NBA: Celtics vs Heat
ML: +180
      ''',
      '''
Dodgers -125
Yankees +105
Moneyline
      ''',
    ];
    
    // Return a random mock slip
    final random = DateTime.now().millisecond % mockSlips.length;
    final mockText = mockSlips[random];
    return mockText;
  }

  /// Parses extracted text to find betting information
  List<ExtractedBet> parseBettingInformation(String text) {
    
    final List<ExtractedBet> bets = [];
    final lines = text.split('\n');
    
    // Common team name patterns for different sports (with abbreviations)
    final nbaTeams = [
      'Lakers', 'Warriors', 'Celtics', 'Bulls', 'Heat', 'Knicks', 'Nets', 'Bucks',
      'Suns', 'Mavericks', 'Clippers', 'Rockets', 'Thunder', 'Jazz', 'Nuggets',
      'Trail Blazers', 'Spurs', 'Grizzlies', 'Pelicans', 'Kings', 'Timberwolves',
      'Hornets', 'Magic', 'Pistons', 'Cavaliers', 'Pacers', 'Hawks', 'Wizards',
      'Raptors', '76ers', 'Knicks'
    ];
    
    // Team abbreviations mapping
    final teamAbbreviations = {
      'MIN': 'Timberwolves',
      'DET': 'Pistons',
      'LAL': 'Lakers',
      'GSW': 'Warriors',
      'BOS': 'Celtics',
      'CHI': 'Bulls',
      'MIA': 'Heat',
      'NYK': 'Knicks',
      'BKN': 'Nets',
      'MIL': 'Bucks',
      'PHX': 'Suns',
      'DAL': 'Mavericks',
      'LAC': 'Clippers',
      'HOU': 'Rockets',
      'OKC': 'Thunder',
      'UTA': 'Jazz',
      'DEN': 'Nuggets',
      'POR': 'Trail Blazers',
      'SAS': 'Spurs',
      'MEM': 'Grizzlies',
      'NOP': 'Pelicans',
      'SAC': 'Kings',
      'CHA': 'Hornets',
      'ORL': 'Magic',
      'CLE': 'Cavaliers',
      'IND': 'Pacers',
      'ATL': 'Hawks',
      'WAS': 'Wizards',
      'TOR': 'Raptors',
      'PHI': '76ers',
    };
    
    final nflTeams = [
      'Chiefs', 'Bills', 'Patriots', 'Dolphins', 'Jets', 'Steelers', 'Ravens',
      'Bengals', 'Browns', 'Titans', 'Colts', 'Jaguars', 'Texans', 'Raiders',
      'Broncos', 'Chargers', 'Cowboys', 'Eagles', 'Giants', 'Commanders',
      'Bears', 'Lions', 'Packers', 'Vikings', 'Buccaneers', 'Falcons',
      'Panthers', 'Saints', 'Rams', '49ers', 'Seahawks', 'Cardinals'
    ];
    
    final mlbTeams = [
      'Yankees', 'Red Sox', 'Blue Jays', 'Orioles', 'Rays', 'White Sox',
      'Indians', 'Tigers', 'Twins', 'Royals', 'Astros', 'Rangers', 'Angels',
      'Athletics', 'Mariners', 'Braves', 'Marlins', 'Mets', 'Phillies',
      'Nationals', 'Cubs', 'Reds', 'Brewers', 'Pirates', 'Cardinals',
      'Dodgers', 'Giants', 'Padres', 'Rockies', 'Diamondbacks'
    ];

    // Patterns for different bet types and odds
    final oddsPattern = RegExp(r'[+-]?\d+(?:\.\d+)?');
    final betTypePatterns = {
      'moneyline': RegExp(r'moneyline|ml', caseSensitive: false),
      'spread': RegExp(r'spread|ats', caseSensitive: false),
      'total': RegExp(r'total|o/u|over/under', caseSensitive: false),
      'prop': RegExp(r'prop|player\s+prop', caseSensitive: false),
    };

    // First pass: look for betting slip patterns
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Look for "vs" pattern to find team matchups
      if (line.contains('vs')) {
        
        // Extract team names from the line
        final teamNames = _extractTeamNamesFromLine(line, teamAbbreviations, nbaTeams);
        
        if (teamNames.length >= 2) {
          final team1 = teamNames[0];
          final team2 = teamNames[1];
          
          
          // Check if these are valid team names
          final allTeams = [...nbaTeams, ...nflTeams, ...mlbTeams];
          if (allTeams.any((team) => team.toLowerCase() == team1.toLowerCase()) &&
              allTeams.any((team) => team.toLowerCase() == team2.toLowerCase())) {
            
            // Look for betting information in surrounding lines
            String? odds;
            String? betType;
            String? risk;
            String? payout;
            
            // Search in a window around the current line (5 lines before and after)
            final searchStart = (i - 5).clamp(0, lines.length - 1);
            final searchEnd = (i + 5).clamp(0, lines.length - 1);
            
            for (int j = searchStart; j <= searchEnd; j++) {
              final searchLine = lines[j].trim();
              
              // Look for odds
              if (odds == null) {
                final oddsMatch = oddsPattern.firstMatch(searchLine);
                if (oddsMatch != null && searchLine.length < 10) { // Odds are usually short
                  odds = oddsMatch.group(0);
                }
              }
              
              // Look for bet type
              if (betType == null) {
                for (final entry in betTypePatterns.entries) {
                  if (entry.value.hasMatch(searchLine)) {
                    betType = entry.key;
                    break;
                  }
                }
              }
              
              // Look for risk amount
              if (risk == null && searchLine.contains('Risk:')) {
                final riskMatch = RegExp(r'Risk:\s*(\d+\.?\d*)').firstMatch(searchLine);
                if (riskMatch != null) {
                  risk = riskMatch.group(1);
                }
              }
              
              // Look for payout amount
              if (payout == null && searchLine.contains('Payout:')) {
                final payoutMatch = RegExp(r'Payout:\s*(\d+\.?\d*)').firstMatch(searchLine);
                if (payoutMatch != null) {
                  payout = payoutMatch.group(1);
                }
              }
            }
            
            // If we found odds, create the bet
            if (odds != null) {
              final bet = ExtractedBet(
                team1: _findExactTeamName(team1, allTeams),
                team2: _findExactTeamName(team2, allTeams),
                odds: odds,
                betType: betType ?? 'moneyline',
                confidence: 0.9,
              );
              
              bets.add(bet);
            }
          }
        }
      }
      
      // Look for individual team lines with odds
      for (final team in [...nbaTeams, ...nflTeams, ...mlbTeams]) {
        if (line.contains(team)) {
          final oddsMatch = oddsPattern.firstMatch(line);
          if (oddsMatch != null) {
            // This might be a single team bet, but we need to find the opponent
            // For now, we'll skip this and focus on the vs pattern
            // print('Found team with odds but no opponent: $team ${oddsMatch.group(0)}');
          }
        }
      }
    }
    
    return bets;
  }

  /// Helper method to find exact team name (case-insensitive)
  String _findExactTeamName(String partialName, List<String> allTeams) {
    for (final team in allTeams) {
      if (team.toLowerCase() == partialName.toLowerCase()) {
        return team;
      }
    }
    return partialName; // Return original if not found
  }

  /// Helper method to resolve team names from abbreviations
  String _resolveTeamName(String teamText, Map<String, String> abbreviations, List<String> fullTeamNames) {
    // First, try to match the exact text as an abbreviation
    if (abbreviations.containsKey(teamText.toUpperCase())) {
      return abbreviations[teamText.toUpperCase()]!;
    }
    
    // If it's not an abbreviation, try to find a full team name that contains the text
    for (final fullTeam in fullTeamNames) {
      if (fullTeam.toLowerCase().contains(teamText.toLowerCase()) ||
          teamText.toLowerCase().contains(fullTeam.toLowerCase())) {
        return fullTeam;
      }
    }
    
    // If no match found, return the original text
    return teamText;
  }

  /// Helper method to extract team names from a line containing "vs"
  List<String> _extractTeamNamesFromLine(String line, Map<String, String> abbreviations, List<String> fullTeamNames) {
    final List<String> teamNames = [];
    
    // Split by "vs" and process each part
    final parts = line.split('vs');
    if (parts.length >= 2) {
      // Process first team
      final team1Part = parts[0].trim();
      final team1 = _resolveTeamName(team1Part, abbreviations, fullTeamNames);
      teamNames.add(team1);
      
      // Process second team
      final team2Part = parts[1].trim();
      final team2 = _resolveTeamName(team2Part, abbreviations, fullTeamNames);
      teamNames.add(team2);
    }
    
    return teamNames;
  }

  /// Determines the sport based on team names
  String determineSport(String team1, String team2) {
    final nbaTeams = [
      'Lakers', 'Warriors', 'Celtics', 'Bulls', 'Heat', 'Knicks', 'Nets', 'Bucks',
      'Suns', 'Mavericks', 'Clippers', 'Rockets', 'Thunder', 'Jazz', 'Nuggets',
      'Trail Blazers', 'Spurs', 'Grizzlies', 'Pelicans', 'Kings', 'Timberwolves',
      'Hornets', 'Magic', 'Pistons', 'Cavaliers', 'Pacers', 'Hawks', 'Wizards',
      'Raptors', '76ers'
    ];
    
    final nflTeams = [
      'Chiefs', 'Bills', 'Patriots', 'Dolphins', 'Jets', 'Steelers', 'Ravens',
      'Bengals', 'Browns', 'Titans', 'Colts', 'Jaguars', 'Texans', 'Raiders',
      'Broncos', 'Chargers', 'Cowboys', 'Eagles', 'Giants', 'Commanders',
      'Bears', 'Lions', 'Packers', 'Vikings', 'Buccaneers', 'Falcons',
      'Panthers', 'Saints', 'Rams', '49ers', 'Seahawks', 'Cardinals'
    ];
    
    final mlbTeams = [
      'Yankees', 'Red Sox', 'Blue Jays', 'Orioles', 'Rays', 'White Sox',
      'Indians', 'Tigers', 'Twins', 'Royals', 'Astros', 'Rangers', 'Angels',
      'Athletics', 'Mariners', 'Braves', 'Marlins', 'Mets', 'Phillies',
      'Nationals', 'Cubs', 'Reds', 'Brewers', 'Pirates', 'Cardinals',
      'Dodgers', 'Giants', 'Padres', 'Rockies', 'Diamondbacks'
    ];

    if (nbaTeams.contains(team1) || nbaTeams.contains(team2)) {
      return 'Basketball';
    } else if (nflTeams.contains(team1) || nflTeams.contains(team2)) {
      return 'Football';
    } else if (mlbTeams.contains(team1) || mlbTeams.contains(team2)) {
      return 'Baseball';
    }
    
    return 'Unknown';
  }

  /// Determines the league based on sport
  String determineLeague(String sport) {
    switch (sport) {
      case 'Basketball':
        return 'NBA';
      case 'Football':
        return 'NFL';
      case 'Baseball':
        return 'MLB';
      default:
        return 'Unknown';
    }
  }
}

/// Represents a single bet extracted from OCR text
class ExtractedBet {
  final String team1;
  final String team2;
  final String odds;
  final String betType;
  final double confidence;

  ExtractedBet({
    required this.team1,
    required this.team2,
    required this.odds,
    required this.betType,
    required this.confidence,
  });

  @override
  String toString() {
    return '$team1 vs $team2 - $odds ($betType)';
  }
} 