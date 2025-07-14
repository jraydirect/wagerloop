/// Utility class for managing team logos and branding in WagerLoop.
/// 
/// Provides consistent team logo assets and colors throughout the app
/// for betting picks, game displays, and user favorite teams. Supports
/// major sports leagues including NFL, NBA, MLB, NHL, and Soccer.
/// 
/// Maintains a centralized mapping of team names to logo assets and
/// brand colors for visual consistency across the betting interface.
class TeamLogoUtils { // Define TeamLogoUtils class to manage team logos and branding
  static final Map<String, String> _teamLogos = { // Define static final map containing team name to logo path mappings
    // NFL Teams
    'Arizona Cardinals': 'assets/logos/nfl/arizona_cardinals.png', // Map Arizona Cardinals to their logo asset path
    'Atlanta Falcons': 'assets/logos/nfl/atlanta_falcons.png', // Map Atlanta Falcons to their logo asset path
    'Baltimore Ravens': 'assets/logos/nfl/baltimore_ravens.png', // Map Baltimore Ravens to their logo asset path
    'Buffalo Bills': 'assets/logos/nfl/buffalo_bills.png', // Map Buffalo Bills to their logo asset path
    'Carolina Panthers': 'assets/logos/nfl/carolina_panthers.png', // Map Carolina Panthers to their logo asset path
    'Chicago Bears': 'assets/logos/nfl/chicago_bears.png', // Map Chicago Bears to their logo asset path
    'Cincinnati Bengals': 'assets/logos/nfl/cincinnati_bengals.png', // Map Cincinnati Bengals to their logo asset path
    'Cleveland Browns': 'assets/logos/nfl/cleveland_browns.png', // Map Cleveland Browns to their logo asset path
    'Dallas Cowboys': 'assets/logos/nfl/dallas_cowboys.png', // Map Dallas Cowboys to their logo asset path
    'Denver Broncos': 'assets/logos/nfl/denver_broncos.png', // Map Denver Broncos to their logo asset path
    'Detroit Lions': 'assets/logos/nfl/detroit_lions.png', // Map Detroit Lions to their logo asset path
    'Green Bay Packers': 'assets/logos/nfl/green_bay_packers.png', // Map Green Bay Packers to their logo asset path
    'Houston Texans': 'assets/logos/nfl/houston_texans.png', // Map Houston Texans to their logo asset path
    'Indianapolis Colts': 'assets/logos/nfl/indianapolis_colts.png', // Map Indianapolis Colts to their logo asset path
    'Jacksonville Jaguars': 'assets/logos/nfl/jacksonville_jaguars.png', // Map Jacksonville Jaguars to their logo asset path
    'Kansas City Chiefs': 'assets/logos/nfl/kansas_city_chiefs.png', // Map Kansas City Chiefs to their logo asset path
    'Las Vegas Raiders': 'assets/logos/nfl/las_vegas_raiders.png', // Map Las Vegas Raiders to their logo asset path
    'Los Angeles Chargers': 'assets/logos/nfl/los_angeles_chargers.png', // Map Los Angeles Chargers to their logo asset path
    'Los Angeles Rams': 'assets/logos/nfl/los_angeles_rams.png', // Map Los Angeles Rams to their logo asset path
    'Miami Dolphins': 'assets/logos/nfl/miami_dolphins.png', // Map Miami Dolphins to their logo asset path
    'Minnesota Vikings': 'assets/logos/nfl/minnesota_vikings.png', // Map Minnesota Vikings to their logo asset path
    'New England Patriots': 'assets/logos/nfl/new_england_patriots.png', // Map New England Patriots to their logo asset path
    'New Orleans Saints': 'assets/logos/nfl/new_orleans_saints.png', // Map New Orleans Saints to their logo asset path
    'New York Giants': 'assets/logos/nfl/new_york_giants.png', // Map New York Giants to their logo asset path
    'New York Jets': 'assets/logos/nfl/new_york_jets.png', // Map New York Jets to their logo asset path
    'Philadelphia Eagles': 'assets/logos/nfl/philadelphia_eagles.png', // Map Philadelphia Eagles to their logo asset path
    'Pittsburgh Steelers': 'assets/logos/nfl/pittsburgh_steelers.png', // Map Pittsburgh Steelers to their logo asset path
    'San Francisco 49ers': 'assets/logos/nfl/san_francisco_49ers.png', // Map San Francisco 49ers to their logo asset path
    'Seattle Seahawks': 'assets/logos/nfl/seattle_seahawks.png', // Map Seattle Seahawks to their logo asset path
    'Tampa Bay Buccaneers': 'assets/logos/nfl/tampa_bay_buccaneers.png', // Map Tampa Bay Buccaneers to their logo asset path
    'Tennessee Titans': 'assets/logos/nfl/tennessee_titans.png', // Map Tennessee Titans to their logo asset path
    'Washington Commanders': 'assets/logos/nfl/washington_commanders.png', // Map Washington Commanders to their logo asset path
    
    // NBA Teams
    'Atlanta Hawks': 'assets/logos/nba/atlanta_hawks.png', // Map Atlanta Hawks to their logo asset path
    'Boston Celtics': 'assets/logos/nba/boston_celtics.png', // Map Boston Celtics to their logo asset path
    'Brooklyn Nets': 'assets/logos/nba/brooklyn_nets.png', // Map Brooklyn Nets to their logo asset path
    'Charlotte Hornets': 'assets/logos/nba/charlotte_hornets.png', // Map Charlotte Hornets to their logo asset path
    'Chicago Bulls': 'assets/logos/nba/chicago_bulls.png', // Map Chicago Bulls to their logo asset path
    'Cleveland Cavaliers': 'assets/logos/nba/cleveland_cavaliers.png', // Map Cleveland Cavaliers to their logo asset path
    'Dallas Mavericks': 'assets/logos/nba/dallas_mavericks.png', // Map Dallas Mavericks to their logo asset path
    'Denver Nuggets': 'assets/logos/nba/denver_nuggets.png', // Map Denver Nuggets to their logo asset path
    'Detroit Pistons': 'assets/logos/nba/detroit_pistons.png', // Map Detroit Pistons to their logo asset path
    'Golden State Warriors': 'assets/logos/nba/golden_state_warriors.png', // Map Golden State Warriors to their logo asset path
    'Houston Rockets': 'assets/logos/nba/houston_rockets.png', // Map Houston Rockets to their logo asset path
    'Indiana Pacers': 'assets/logos/nba/indiana_pacers.png', // Map Indiana Pacers to their logo asset path
    'LA Clippers': 'assets/logos/nba/la_clippers.png', // Map LA Clippers to their logo asset path
    'Los Angeles Lakers': 'assets/logos/nba/los_angeles_lakers.png', // Map Los Angeles Lakers to their logo asset path
    'Memphis Grizzlies': 'assets/logos/nba/memphis_grizzlies.png', // Map Memphis Grizzlies to their logo asset path
    'Miami Heat': 'assets/logos/nba/miami_heat.png', // Map Miami Heat to their logo asset path
    'Milwaukee Bucks': 'assets/logos/nba/milwaukee_bucks.png', // Map Milwaukee Bucks to their logo asset path
    'Minnesota Timberwolves': 'assets/logos/nba/minnesota_timberwolves.png', // Map Minnesota Timberwolves to their logo asset path
    'New Orleans Pelicans': 'assets/logos/nba/new_orleans_pelicans.png', // Map New Orleans Pelicans to their logo asset path
    'New York Knicks': 'assets/logos/nba/new_york_knicks.png', // Map New York Knicks to their logo asset path
    'Oklahoma City Thunder': 'assets/logos/nba/oklahoma_city_thunder.png', // Map Oklahoma City Thunder to their logo asset path
    'Orlando Magic': 'assets/logos/nba/orlando_magic.png', // Map Orlando Magic to their logo asset path
    'Philadelphia 76ers': 'assets/logos/nba/philadelphia_76ers.png', // Map Philadelphia 76ers to their logo asset path
    'Phoenix Suns': 'assets/logos/nba/phoenix_suns.png', // Map Phoenix Suns to their logo asset path
    'Portland Trail Blazers': 'assets/logos/nba/portland_trail_blazers.png', // Map Portland Trail Blazers to their logo asset path
    'Sacramento Kings': 'assets/logos/nba/sacramento_kings.png', // Map Sacramento Kings to their logo asset path
    'San Antonio Spurs': 'assets/logos/nba/san_antonio_spurs.png', // Map San Antonio Spurs to their logo asset path
    'Toronto Raptors': 'assets/logos/nba/toronto_raptors.png', // Map Toronto Raptors to their logo asset path
    'Utah Jazz': 'assets/logos/nba/utah_jazz.png', // Map Utah Jazz to their logo asset path
    'Washington Wizards': 'assets/logos/nba/washington_wizards.png', // Map Washington Wizards to their logo asset path
  }; // End of team logos map

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
  static String? getTeamLogo(String teamName) { // Define static method to get team logo path by team name
    return _teamLogos[teamName]; // Return the logo path from the map for the given team name
  } // End of getTeamLogo method

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
  static String? getSportLogo(String sport) { // Define static method to get sport logo path by sport name
    final Map<String, String> sportLogos = { // Define map containing sport name to logo path mappings
      'NFL': 'assets/logos/leagues/nfl_logo.png', // Map NFL to its logo asset path
      'NBA': 'assets/logos/leagues/nba_logo.png', // Map NBA to its logo asset path
      'MLB': 'assets/logos/leagues/mlb_logo.png', // Map MLB to its logo asset path
      'NHL': 'assets/logos/leagues/nhl_logo.png', // Map NHL to its logo asset path
      'Soccer': 'assets/logos/leagues/soccer_logo.png', // Map Soccer to its logo asset path
      'NCAAF': 'assets/logos/leagues/ncaaf_logo.png', // Map NCAAF to its logo asset path
      'NCAAB': 'assets/logos/leagues/ncaab_logo.png', // Map NCAAB to its logo asset path
    }; // End of sport logos map
    return sportLogos[sport]; // Return the logo path from the map for the given sport
  } // End of getSportLogo method

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
  static Map<String, dynamic>? getTeamColors(String teamName) { // Define static method to get team colors by team name
    final Map<String, Map<String, dynamic>> teamColors = { // Define map containing team name to color mappings
      'Los Angeles Lakers': { // Define color mapping for Los Angeles Lakers
        'primary': 0xFF552583,  // Set primary color to purple using hex color code
        'secondary': 0xFFFDB927, // Set secondary color to gold using hex color code
      }, // End of Lakers color mapping
      'Golden State Warriors': { // Define color mapping for Golden State Warriors
        'primary': 0xFF1D428A,  // Set primary color to blue using hex color code
        'secondary': 0xFFFFC72C, // Set secondary color to yellow using hex color code
      }, // End of Warriors color mapping
      'Dallas Cowboys': { // Define color mapping for Dallas Cowboys
        'primary': 0xFF003594,  // Set primary color to navy blue using hex color code
        'secondary': 0xFF869397, // Set secondary color to silver using hex color code
      }, // End of Cowboys color mapping
      'New England Patriots': { // Define color mapping for New England Patriots
        'primary': 0xFF002244,  // Set primary color to navy blue using hex color code
        'secondary': 0xFFC60C30, // Set secondary color to red using hex color code
      }, // End of Patriots color mapping
      // Add more team colors as needed
    }; // End of team colors map
    return teamColors[teamName]; // Return the color mapping from the map for the given team name
  } // End of getTeamColors method
} // End of TeamLogoUtils class
