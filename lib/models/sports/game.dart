import 'odds.dart';

class Game {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime gameTime;
  final String sport;
  final String league;
  final Map<String, dynamic>? odds;
  final Map<String, OddsData>? sportsbookOdds;
  final String status; // scheduled, live, finished
  final int? homeScore;
  final int? awayScore;
  final String? period; // Quarter, Half, Period, Inning, etc.

  Game({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId = '',
    this.awayTeamId = '',
    required this.gameTime,
    required this.sport,
    required this.league,
    this.odds,
    this.sportsbookOdds,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.period,
  });

  String get matchupString => '$homeTeam vs $awayTeam';
  
  String get formattedGameTime {
    // Convert to Central Time
    final centralTime = _convertToCentralTime(gameTime);
    
    // Get current time in Central Time for comparison
    final now = _convertToCentralTime(DateTime.now());
    
    // Check if game is today or tomorrow
    final isToday = centralTime.year == now.year && 
                    centralTime.month == now.month && 
                    centralTime.day == now.day;
    final isTomorrow = centralTime.year == now.year && 
                       centralTime.month == now.month && 
                       centralTime.day == now.day + 1;
    
    // Format date and time
    final date = '${centralTime.month}/${centralTime.day}';
    
    // Format time in 12-hour format with AM/PM
    String formattedTime;
    int hour = centralTime.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    formattedTime = '$hour:${centralTime.minute.toString().padLeft(2, '0')} $amPm CT';
    
    // Return formatted string
    if (isToday) {
      return 'Today - $date - $formattedTime';
    } else if (isTomorrow) {
      return 'Tomorrow - $date - $formattedTime';
    } else {
      return '$date - $formattedTime';
    }
  }
  
  // Helper method to convert UTC time to Central Time
  DateTime _convertToCentralTime(DateTime dateTime) {
    // ESPN API provides times in UTC
    // Central Time is UTC-6 for CST or UTC-5 for CDT
    // For simplicity, we'll use a fixed offset of -6 hours (CST)
    // In a production app, you'd want to properly handle daylight saving time
    return dateTime.subtract(const Duration(hours: 6));
  }
  
  // Check if game is scheduled within the next month
  bool get isWithinNextMonth {
    try {
      final now = DateTime.now();
      
      // Create a date one month from now
      // We need to handle month overflow (e.g., month 12 + 1)
      DateTime oneMonthFromNow;
      if (now.month == 12) {
        oneMonthFromNow = DateTime(now.year + 1, 1, now.day);
      } else {
        oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);
      }
      
      // Convert UTC game time to local time for fair comparison
      final localGameTime = gameTime.toLocal();
      // Convert to date only (no time) for comparison
      final gameDate = DateTime(localGameTime.year, localGameTime.month, localGameTime.day);
      final nowDate = DateTime(now.year, now.month, now.day);
      final oneMonthFromNowDate = DateTime(oneMonthFromNow.year, oneMonthFromNow.month, oneMonthFromNow.day);
      
      // Game should be today or later, and earlier than one month from now
      final result = (gameDate.isAfter(nowDate) || gameDate.isAtSameMomentAs(nowDate)) && 
                     (gameDate.isBefore(oneMonthFromNowDate) || gameDate.isAtSameMomentAs(oneMonthFromNowDate));
      
      return result;
    } catch (e) {
      // Default to true to include games with date calculation issues
      return true;
    }
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    // Parse sportsbookOdds if available
    Map<String, OddsData>? sportsbookOdds;
    if (json.containsKey('sportsbook_odds') && json['sportsbook_odds'] != null) {
      sportsbookOdds = <String, OddsData>{};
      final oddsMap = json['sportsbook_odds'] as Map<String, dynamic>;
      oddsMap.forEach((key, value) {
        sportsbookOdds![key] = OddsData.fromJson(value);
      });
    }
    
    return Game(
      id: json['id'],
      homeTeam: json['home_team'],
      awayTeam: json['away_team'],
      homeTeamId: json['home_team_id'] ?? '',
      awayTeamId: json['away_team_id'] ?? '',
      gameTime: DateTime.parse(json['game_time']),
      sport: json['sport'],
      league: json['league'],
      odds: json['odds'],
      sportsbookOdds: sportsbookOdds,
      status: json['status'],
      homeScore: json['home_score'],
      awayScore: json['away_score'],
      period: json['period'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'game_time': gameTime.toIso8601String(),
      'sport': sport,
      'league': league,
      'odds': odds,
      'status': status,
      'home_score': homeScore,
      'away_score': awayScore,
      'period': period,
    };
    
    if (sportsbookOdds != null) {
      final sportsbookOddsJson = <String, dynamic>{};
      sportsbookOdds!.forEach((key, value) {
        sportsbookOddsJson[key] = value.toJson();
      });
      json['sportsbook_odds'] = sportsbookOddsJson;
    }
    
    return json;
  }
}
