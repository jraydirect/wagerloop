/// Utility class for managing team logos and branding in WagerLoop.
/// 
/// Provides consistent team logo assets and colors throughout the app
/// for betting picks, game displays, and user favorite teams. Supports
/// major sports leagues including NFL, NBA, MLB, NHL, and Soccer.
/// 
/// Maintains a centralized mapping of team names to logo assets and
/// brand colors for visual consistency across the betting interface.
class TeamLogoUtils {
  static final Map<String, String> _teamLogos = {
    // NFL Teams
    'Arizona Cardinals': 'assets/logos/nfl/arizona_cardinals.png',
    'Atlanta Falcons': 'assets/logos/nfl/atlanta_falcons.png',
    'Baltimore Ravens': 'assets/logos/nfl/baltimore_ravens.png',
    'Buffalo Bills': 'assets/logos/nfl/buffalo_bills.png',
    'Carolina Panthers': 'assets/logos/nfl/carolina_panthers.png',
    'Chicago Bears': 'assets/logos/nfl/chicago_bears.png',
    'Cincinnati Bengals': 'assets/logos/nfl/cincinnati_bengals.png',
    'Cleveland Browns': 'assets/logos/nfl/cleveland_browns.png',
    'Dallas Cowboys': 'assets/logos/nfl/dallas_cowboys.png',
    'Denver Broncos': 'assets/logos/nfl/denver_broncos.png',
    'Detroit Lions': 'assets/logos/nfl/detroit_lions.png',
    'Green Bay Packers': 'assets/logos/nfl/green_bay_packers.png',
    'Houston Texans': 'assets/logos/nfl/houston_texans.png',
    'Indianapolis Colts': 'assets/logos/nfl/indianapolis_colts.png',
    'Jacksonville Jaguars': 'assets/logos/nfl/jacksonville_jaguars.png',
    'Kansas City Chiefs': 'assets/logos/nfl/kansas_city_chiefs.png',
    'Las Vegas Raiders': 'assets/logos/nfl/las_vegas_raiders.png',
    'Los Angeles Chargers': 'assets/logos/nfl/los_angeles_chargers.png',
    'Los Angeles Rams': 'assets/logos/nfl/los_angeles_rams.png',
    'Miami Dolphins': 'assets/logos/nfl/miami_dolphins.png',
    'Minnesota Vikings': 'assets/logos/nfl/minnesota_vikings.png',
    'New England Patriots': 'assets/logos/nfl/new_england_patriots.png',
    'New Orleans Saints': 'assets/logos/nfl/new_orleans_saints.png',
    'New York Giants': 'assets/logos/nfl/new_york_giants.png',
    'New York Jets': 'assets/logos/nfl/new_york_jets.png',
    'Philadelphia Eagles': 'assets/logos/nfl/philadelphia_eagles.png',
    'Pittsburgh Steelers': 'assets/logos/nfl/pittsburgh_steelers.png',
    'San Francisco 49ers': 'assets/logos/nfl/san_francisco_49ers.png',
    'Seattle Seahawks': 'assets/logos/nfl/seattle_seahawks.png',
    'Tampa Bay Buccaneers': 'assets/logos/nfl/tampa_bay_buccaneers.png',
    'Tennessee Titans': 'assets/logos/nfl/tennessee_titans.png',
    'Washington Commanders': 'assets/logos/nfl/washington_commanders.png',
    
    // NBA Teams
    'Atlanta Hawks': 'assets/logos/nba/atlanta_hawks.png',
    'Boston Celtics': 'assets/logos/nba/boston_celtics.png',
    'Brooklyn Nets': 'assets/logos/nba/brooklyn_nets.png',
    'Charlotte Hornets': 'assets/logos/nba/charlotte_hornets.png',
    'Chicago Bulls': 'assets/logos/nba/chicago_bulls.png',
    'Cleveland Cavaliers': 'assets/logos/nba/cleveland_cavaliers.png',
    'Dallas Mavericks': 'assets/logos/nba/dallas_mavericks.png',
    'Denver Nuggets': 'assets/logos/nba/denver_nuggets.png',
    'Detroit Pistons': 'assets/logos/nba/detroit_pistons.png',
    'Golden State Warriors': 'assets/logos/nba/golden_state_warriors.png',
    'Houston Rockets': 'assets/logos/nba/houston_rockets.png',
    'Indiana Pacers': 'assets/logos/nba/indiana_pacers.png',
    'LA Clippers': 'assets/logos/nba/la_clippers.png',
    'Los Angeles Lakers': 'assets/logos/nba/los_angeles_lakers.png',
    'Memphis Grizzlies': 'assets/logos/nba/memphis_grizzlies.png',
    'Miami Heat': 'assets/logos/nba/miami_heat.png',
    'Milwaukee Bucks': 'assets/logos/nba/milwaukee_bucks.png',
    'Minnesota Timberwolves': 'assets/logos/nba/minnesota_timberwolves.png',
    'New Orleans Pelicans': 'assets/logos/nba/new_orleans_pelicans.png',
    'New York Knicks': 'assets/logos/nba/new_york_knicks.png',
    'Oklahoma City Thunder': 'assets/logos/nba/oklahoma_city_thunder.png',
    'Orlando Magic': 'assets/logos/nba/orlando_magic.png',
    'Philadelphia 76ers': 'assets/logos/nba/philadelphia_76ers.png',
    'Phoenix Suns': 'assets/logos/nba/phoenix_suns.png',
    'Portland Trail Blazers': 'assets/logos/nba/portland_trail_blazers.png',
    'Sacramento Kings': 'assets/logos/nba/sacramento_kings.png',
    'San Antonio Spurs': 'assets/logos/nba/san_antonio_spurs.png',
    'Toronto Raptors': 'assets/logos/nba/toronto_raptors.png',
    'Utah Jazz': 'assets/logos/nba/utah_jazz.png',
    'Washington Wizards': 'assets/logos/nba/washington_wizards.png',
  };

  /// Retrieves the logo asset path for a given team name.
  /// 
  /// Returns the asset path for the team's logo image, used for displaying
  /// team branding in betting picks, game cards, and user favorites.
  /// 
  /// Parameters:
  ///   - teamName: Full name of the team (e.g., "Los Angeles Lakers")
  /// 
  /// Returns:
  ///   String? containing the asset path or null if team not found
  static String? getTeamLogo(String teamName) {
    return _teamLogos[teamName];
  }

  /// Retrieves the sport-specific logo for league branding.
  /// 
  /// Returns the logo for the sport/league itself (NFL, NBA, etc.)
  /// used in navigation, headers, and sport selection interfaces.
  /// 
  /// Parameters:
  ///   - sport: Sport/league name (e.g., "NFL", "NBA", "MLB")
  /// 
  /// Returns:
  ///   String? containing the sport logo asset path or null if not found
  static String? getSportLogo(String sport) {
    final Map<String, String> sportLogos = {
      'NFL': 'assets/logos/leagues/nfl_logo.png',
      'NBA': 'assets/logos/leagues/nba_logo.png',
      'MLB': 'assets/logos/leagues/mlb_logo.png',
      'NHL': 'assets/logos/leagues/nhl_logo.png',
      'Soccer': 'assets/logos/leagues/soccer_logo.png',
      'NCAAF': 'assets/logos/leagues/ncaaf_logo.png',
      'NCAAB': 'assets/logos/leagues/ncaab_logo.png',
    };
    return sportLogos[sport];
  }

  /// Retrieves the brand colors for a given team.
  /// 
  /// Returns the primary and secondary colors associated with a team
  /// for consistent theming in betting interfaces and team displays.
  /// 
  /// Parameters:
  ///   - teamName: Full name of the team
  /// 
  /// Returns:
  ///   Map<String, dynamic>? containing 'primary' and 'secondary' color values
  ///   or null if team colors not found
  static Map<String, dynamic>? getTeamColors(String teamName) {
    final Map<String, Map<String, dynamic>> teamColors = {
      'Los Angeles Lakers': {
        'primary': 0xFF552583,  // Purple
        'secondary': 0xFFFDB927, // Gold
      },
      'Golden State Warriors': {
        'primary': 0xFF1D428A,  // Blue
        'secondary': 0xFFFFC72C, // Yellow
      },
      'Dallas Cowboys': {
        'primary': 0xFF003594,  // Navy Blue
        'secondary': 0xFF869397, // Silver
      },
      'New England Patriots': {
        'primary': 0xFF002244,  // Navy Blue
        'secondary': 0xFFC60C30, // Red
      },
      // Add more team colors as needed
    };
    return teamColors[teamName];
  }
}
