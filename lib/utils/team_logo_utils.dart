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
    // NFL Teams - mapping to actual asset files
    'Arizona Cardinals': 'assets/nflLogos/cardinals.png',
    'Atlanta Falcons': 'assets/nflLogos/falcons.png',
    'Baltimore Ravens': 'assets/nflLogos/ravens.png',
    'Buffalo Bills': 'assets/nflLogos/bills.png',
    'Carolina Panthers': 'assets/nflLogos/panthers.png',
    'Chicago Bears': 'assets/nflLogos/bears.png',
    'Cincinnati Bengals': 'assets/nflLogos/bengals.png',
    'Cleveland Browns': 'assets/nflLogos/browns.png',
    'Dallas Cowboys': 'assets/nflLogos/cowboys.png',
    'Denver Broncos': 'assets/nflLogos/broncos.png',
    'Detroit Lions': 'assets/nflLogos/lions.png',
    'Green Bay Packers': 'assets/nflLogos/packers.png',
    'Houston Texans': 'assets/nflLogos/texans.png',
    'Indianapolis Colts': 'assets/nflLogos/colts.png',
    'Jacksonville Jaguars': 'assets/nflLogos/jaguars.png',
    'Kansas City Chiefs': 'assets/nflLogos/chiefs.png',
    'Las Vegas Raiders': 'assets/nflLogos/raiders.png',
    'Los Angeles Chargers': 'assets/nflLogos/chargers.png',
    'Los Angeles Rams': 'assets/nflLogos/rams.png',
    'Miami Dolphins': 'assets/nflLogos/dolphins.png',
    'Minnesota Vikings': 'assets/nflLogos/vikings.png',
    'New England Patriots': 'assets/nflLogos/patriots.png',
    'New Orleans Saints': 'assets/nflLogos/saints.png',
    'New York Giants': 'assets/nflLogos/giants.png',
    'New York Jets': 'assets/nflLogos/jets.png',
    'Philadelphia Eagles': 'assets/nflLogos/eagles.png',
    'Pittsburgh Steelers': 'assets/nflLogos/steelers.png',
    'San Francisco 49ers': 'assets/nflLogos/49ers.png',
    'Seattle Seahawks': 'assets/nflLogos/seahawks.png',
    'Tampa Bay Buccaneers': 'assets/nflLogos/buccaneers.png',
    'Tennessee Titans': 'assets/nflLogos/titans.png',
    'Washington Commanders': 'assets/nflLogos/commanders.png',
    
    // NFL Teams - shortened names for The Odds API
    'Cardinals': 'assets/nflLogos/cardinals.png',
    'Falcons': 'assets/nflLogos/falcons.png',
    'Ravens': 'assets/nflLogos/ravens.png',
    'Bills': 'assets/nflLogos/bills.png',
    'Panthers': 'assets/nflLogos/panthers.png',
    'Bears': 'assets/nflLogos/bears.png',
    'Bengals': 'assets/nflLogos/bengals.png',
    'Browns': 'assets/nflLogos/browns.png',
    'Cowboys': 'assets/nflLogos/cowboys.png',
    'Broncos': 'assets/nflLogos/broncos.png',
    'Lions': 'assets/nflLogos/lions.png',
    'Packers': 'assets/nflLogos/packers.png',
    'Texans': 'assets/nflLogos/texans.png',
    'Colts': 'assets/nflLogos/colts.png',
    'Jaguars': 'assets/nflLogos/jaguars.png',
    'Chiefs': 'assets/nflLogos/chiefs.png',
    'Raiders': 'assets/nflLogos/raiders.png',
    'Chargers': 'assets/nflLogos/chargers.png',
    'Rams': 'assets/nflLogos/rams.png',
    'Dolphins': 'assets/nflLogos/dolphins.png',
    'Vikings': 'assets/nflLogos/vikings.png',
    'Patriots': 'assets/nflLogos/patriots.png',
    'Saints': 'assets/nflLogos/saints.png',
    'Giants': 'assets/nflLogos/giants.png',
    'Jets': 'assets/nflLogos/jets.png',
    'Eagles': 'assets/nflLogos/eagles.png',
    'Steelers': 'assets/nflLogos/steelers.png',
    '49ers': 'assets/nflLogos/49ers.png',
    'Seahawks': 'assets/nflLogos/seahawks.png',
    'Buccaneers': 'assets/nflLogos/buccaneers.png',
    'Titans': 'assets/nflLogos/titans.png',
    'Commanders': 'assets/nflLogos/commanders.png',
    
    // NBA Teams - mapping to actual asset files
    'Atlanta Hawks': 'assets/nbaLogos/atlanta-hawks-basketball-club.svg',
    'Boston Celtics': 'assets/nbaLogos/boston-celtics.svg',
    'Brooklyn Nets': 'assets/nbaLogos/brooklyn-nets.svg',
    'Charlotte Hornets': 'assets/nbaLogos/charlotte-hornets.svg',
    'Chicago Bulls': 'assets/nbaLogos/chicago-bulls.svg',
    'Cleveland Cavaliers': 'assets/nbaLogos/cleveland-cavaliers.svg',
    'Dallas Mavericks': 'assets/nbaLogos/dallas-mavericks.svg',
    'Denver Nuggets': 'assets/nbaLogos/denver-nuggets.svg',
    'Golden State Warriors': 'assets/nbaLogos/golden-state-warriors.svg',
    'Houston Rockets': 'assets/nbaLogos/houston-rockets.svg',
    'Indiana Pacers': 'assets/nbaLogos/indiana-pacers.svg',
    'LA Clippers': 'assets/nbaLogos/los-angeles-clippers.svg',
    'Los Angeles Lakers': 'assets/nbaLogos/los-angeles-lakers.svg',
    'Memphis Grizzlies': 'assets/nbaLogos/memphis-grizzlies.svg',
    'Miami Heat': 'assets/nbaLogos/miami-heat.svg',
    'Milwaukee Bucks': 'assets/nbaLogos/milwaukee-bucks.svg',
    'Minnesota Timberwolves': 'assets/nbaLogos/minnesota-timberwolves.svg',
    'New Orleans Pelicans': 'assets/nbaLogos/orleans-pelicans.svg',
    'New York Knicks': 'assets/nbaLogos/new-york-knicks.svg',
    'Orlando Magic': 'assets/nbaLogos/orlando-magic.svg',
    'Philadelphia 76ers': 'assets/nbaLogos/philidephia-76ers.svg',
    'Phoenix Suns': 'assets/nbaLogos/phoenix-suns.svg',
    'Portland Trail Blazers': 'assets/nbaLogos/portland-trail-blazers.svg',
    'Sacramento Kings': 'assets/nbaLogos/sacramento-kings.svg',
    'San Antonio Spurs': 'assets/nbaLogos/san-antonio-spurs.svg',
    'Toronto Raptors': 'assets/nbaLogos/toronto-raptors.svg',
    'Utah Jazz': 'assets/nbaLogos/utah-jazz.svg',
    'Washington Wizards': 'assets/nbaLogos/washington-wizards.svg',
    
    // NBA Teams - shortened names for The Odds API
    'Hawks': 'assets/nbaLogos/atlanta-hawks-basketball-club.svg',
    'Celtics': 'assets/nbaLogos/boston-celtics.svg',
    'Nets': 'assets/nbaLogos/brooklyn-nets.svg',
    'Hornets': 'assets/nbaLogos/charlotte-hornets.svg',
    'Bulls': 'assets/nbaLogos/chicago-bulls.svg',
    'Cavaliers': 'assets/nbaLogos/cleveland-cavaliers.svg',
    'Mavericks': 'assets/nbaLogos/dallas-mavericks.svg',
    'Nuggets': 'assets/nbaLogos/denver-nuggets.svg',
    'Warriors': 'assets/nbaLogos/golden-state-warriors.svg',
    'Rockets': 'assets/nbaLogos/houston-rockets.svg',
    'Pacers': 'assets/nbaLogos/indiana-pacers.svg',
    'Clippers': 'assets/nbaLogos/los-angeles-clippers.svg',
    'Lakers': 'assets/nbaLogos/los-angeles-lakers.svg',
    'Grizzlies': 'assets/nbaLogos/memphis-grizzlies.svg',
    'Heat': 'assets/nbaLogos/miami-heat.svg',
    'Bucks': 'assets/nbaLogos/milwaukee-bucks.svg',
    'Timberwolves': 'assets/nbaLogos/minnesota-timberwolves.svg',
    'Pelicans': 'assets/nbaLogos/orleans-pelicans.svg',
    'Knicks': 'assets/nbaLogos/new-york-knicks.svg',
    'Magic': 'assets/nbaLogos/orlando-magic.svg',
    '76ers': 'assets/nbaLogos/philidephia-76ers.svg',
    'Suns': 'assets/nbaLogos/phoenix-suns.svg',
    'Trail Blazers': 'assets/nbaLogos/portland-trail-blazers.svg',
    'Kings': 'assets/nbaLogos/sacramento-kings.svg',
    'Spurs': 'assets/nbaLogos/san-antonio-spurs.svg',
    'Raptors': 'assets/nbaLogos/toronto-raptors.svg',
    'Jazz': 'assets/nbaLogos/utah-jazz.svg',
    'Wizards': 'assets/nbaLogos/washington-wizards.svg',
    
    // MLB Teams - mapping to actual asset files
    'Los Angeles Angels': 'assets/mlbLogos/angels.png',
    'Houston Astros': 'assets/mlbLogos/astros.png',
    'Oakland Athletics': 'assets/mlbLogos/athletics.png',
    'Toronto Blue Jays': 'assets/mlbLogos/blueJays.png',
    'Atlanta Braves': 'assets/mlbLogos/braves.png',
    'Milwaukee Brewers': 'assets/mlbLogos/brewers.png',
    'St. Louis Cardinals': 'assets/mlbLogos/cardinals.png',
    'Chicago Cubs': 'assets/mlbLogos/cubs.png',
    'Arizona Diamondbacks': 'assets/mlbLogos/diamondbacks.png',
    'Los Angeles Dodgers': 'assets/mlbLogos/dodgers.png',
    'San Francisco Giants': 'assets/mlbLogos/giants.png',
    'Cleveland Guardians': 'assets/mlbLogos/indians.png',
    'Seattle Mariners': 'assets/mlbLogos/mariners.png',
    'Miami Marlins': 'assets/mlbLogos/marlins.png',
    'New York Mets': 'assets/mlbLogos/mets.png',
    'Washington Nationals': 'assets/mlbLogos/nationals.png',
    'Baltimore Orioles': 'assets/mlbLogos/orioles.png',
    'San Diego Padres': 'assets/mlbLogos/padres.png',
    'Philadelphia Phillies': 'assets/mlbLogos/phillies.png',
    'Pittsburgh Pirates': 'assets/mlbLogos/pirates.png',
    'Texas Rangers': 'assets/mlbLogos/rangers.png',
    'Tampa Bay Rays': 'assets/mlbLogos/rays.png',
    'Cincinnati Reds': 'assets/mlbLogos/reds.png',
    'Boston Red Sox': 'assets/mlbLogos/redSox.png',
    'Colorado Rockies': 'assets/mlbLogos/rockies.png',
    'Kansas City Royals': 'assets/mlbLogos/royals.png',
    'Detroit Tigers': 'assets/mlbLogos/tigers.png',
    'Minnesota Twins': 'assets/mlbLogos/twins.png',
    'Chicago White Sox': 'assets/mlbLogos/whiteSox.png',
    'New York Yankees': 'assets/mlbLogos/yankees.png',
    
    // MLB Teams - shortened names
    'Angels': 'assets/mlbLogos/angels.png',
    'Astros': 'assets/mlbLogos/astros.png',
    'Athletics': 'assets/mlbLogos/athletics.png',
    'Blue Jays': 'assets/mlbLogos/blueJays.png',
    'Braves': 'assets/mlbLogos/braves.png',
    'Brewers': 'assets/mlbLogos/brewers.png',
    'Cardinals': 'assets/mlbLogos/cardinals.png',
    'Cubs': 'assets/mlbLogos/cubs.png',
    'Diamondbacks': 'assets/mlbLogos/diamondbacks.png',
    'Dodgers': 'assets/mlbLogos/dodgers.png',
    'Giants': 'assets/mlbLogos/giants.png',
    'Guardians': 'assets/mlbLogos/indians.png',
    'Mariners': 'assets/mlbLogos/mariners.png',
    'Marlins': 'assets/mlbLogos/marlins.png',
    'Mets': 'assets/mlbLogos/mets.png',
    'Nationals': 'assets/mlbLogos/nationals.png',
    'Orioles': 'assets/mlbLogos/orioles.png',
    'Padres': 'assets/mlbLogos/padres.png',
    'Phillies': 'assets/mlbLogos/phillies.png',
    'Pirates': 'assets/mlbLogos/pirates.png',
    'Rangers': 'assets/mlbLogos/rangers.png',
    'Rays': 'assets/mlbLogos/rays.png',
    'Reds': 'assets/mlbLogos/reds.png',
    'Red Sox': 'assets/mlbLogos/redSox.png',
    'Rockies': 'assets/mlbLogos/rockies.png',
    'Royals': 'assets/mlbLogos/royals.png',
    'Tigers': 'assets/mlbLogos/tigers.png',
    'Twins': 'assets/mlbLogos/twins.png',
    'White Sox': 'assets/mlbLogos/whiteSox.png',
    'Yankees': 'assets/mlbLogos/yankees.png',
    
    // NHL Teams - mapping to actual asset files
    'Anaheim Ducks': 'assets/nhlLogos/ana_l.svg',
    'Arizona Coyotes': 'assets/nhlLogos/ari_l.svg',
    'Boston Bruins': 'assets/nhlLogos/bos_l.svg',
    'Buffalo Sabres': 'assets/nhlLogos/buf_l.svg',
    'Carolina Hurricanes': 'assets/nhlLogos/car_l.svg',
    'Columbus Blue Jackets': 'assets/nhlLogos/cbj_l.svg',
    'Calgary Flames': 'assets/nhlLogos/cgy_l.svg',
    'Chicago Blackhawks': 'assets/nhlLogos/chi_l.svg',
    'Colorado Avalanche': 'assets/nhlLogos/col_l.svg',
    'Dallas Stars': 'assets/nhlLogos/dal_l.svg',
    'Detroit Red Wings': 'assets/nhlLogos/det_l.svg',
    'Edmonton Oilers': 'assets/nhlLogos/edm_l.svg',
    'Florida Panthers': 'assets/nhlLogos/fla_l.svg',
    'Los Angeles Kings': 'assets/nhlLogos/lak_l.svg',
    'Minnesota Wild': 'assets/nhlLogos/min_l.svg',
    'Montreal Canadiens': 'assets/nhlLogos/mtl_l.svg',
    'New Jersey Devils': 'assets/nhlLogos/njd_l.svg',
    'Nashville Predators': 'assets/nhlLogos/nsh_l.svg',
    'New York Islanders': 'assets/nhlLogos/nyi_l.svg',
    'New York Rangers': 'assets/nhlLogos/nyr_l.svg',
    'Ottawa Senators': 'assets/nhlLogos/ott_l.svg',
    'Philadelphia Flyers': 'assets/nhlLogos/phi_l.svg',
    'Pittsburgh Penguins': 'assets/nhlLogos/pit_l.svg',
    'San Jose Sharks': 'assets/nhlLogos/sjs_l.svg',
    'St. Louis Blues': 'assets/nhlLogos/stl_l.svg',
    'Tampa Bay Lightning': 'assets/nhlLogos/tbl_l.svg',
    'Toronto Maple Leafs': 'assets/nhlLogos/tor_l.svg',
    'Utah Hockey Club': 'assets/nhlLogos/uth_l.svg',
    'Vancouver Canucks': 'assets/nhlLogos/van_l.svg',
    'Vegas Golden Knights': 'assets/nhlLogos/vgk_l.svg',
    'Winnipeg Jets': 'assets/nhlLogos/wng_l.svg',
    'Washington Capitals': 'assets/nhlLogos/wsh_l.svg',
    
    // NHL Teams - shortened names
    'Ducks': 'assets/nhlLogos/ana_l.svg',
    'Coyotes': 'assets/nhlLogos/ari_l.svg',
    'Bruins': 'assets/nhlLogos/bos_l.svg',
    'Sabres': 'assets/nhlLogos/buf_l.svg',
    'Hurricanes': 'assets/nhlLogos/car_l.svg',
    'Blue Jackets': 'assets/nhlLogos/cbj_l.svg',
    'Flames': 'assets/nhlLogos/cgy_l.svg',
    'Blackhawks': 'assets/nhlLogos/chi_l.svg',
    'Avalanche': 'assets/nhlLogos/col_l.svg',
    'Stars': 'assets/nhlLogos/dal_l.svg',
    'Red Wings': 'assets/nhlLogos/det_l.svg',
    'Oilers': 'assets/nhlLogos/edm_l.svg',
    'Panthers': 'assets/nhlLogos/fla_l.svg',
    'Kings': 'assets/nhlLogos/lak_l.svg',
    'Wild': 'assets/nhlLogos/min_l.svg',
    'Canadiens': 'assets/nhlLogos/mtl_l.svg',
    'Devils': 'assets/nhlLogos/njd_l.svg',
    'Predators': 'assets/nhlLogos/nsh_l.svg',
    'Islanders': 'assets/nhlLogos/nyi_l.svg',
    'Rangers': 'assets/nhlLogos/nyr_l.svg',
    'Senators': 'assets/nhlLogos/ott_l.svg',
    'Flyers': 'assets/nhlLogos/phi_l.svg',
    'Penguins': 'assets/nhlLogos/pit_l.svg',
    'Sharks': 'assets/nhlLogos/sjs_l.svg',
    'Blues': 'assets/nhlLogos/stl_l.svg',
    'Lightning': 'assets/nhlLogos/tbl_l.svg',
    'Maple Leafs': 'assets/nhlLogos/tor_l.svg',
    'Hockey Club': 'assets/nhlLogos/uth_l.svg',
    'Canucks': 'assets/nhlLogos/van_l.svg',
    'Golden Knights': 'assets/nhlLogos/vgk_l.svg',
    'Jets': 'assets/nhlLogos/wng_l.svg',
    'Capitals': 'assets/nhlLogos/wsh_l.svg',
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
    // First try exact match
    String? logo = _teamLogos[teamName];
    if (logo != null) return logo;
    
    // If no exact match, try fuzzy matching for common variations
    for (String key in _teamLogos.keys) {
      if (key.toLowerCase().contains(teamName.toLowerCase()) ||
          teamName.toLowerCase().contains(key.toLowerCase())) {
        return _teamLogos[key];
      }
    }
    
    return null;
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
      'NFL': 'assets/leagueLogos/nfl.png',
      'NBA': 'assets/leagueLogos/nba.png',
      'MLB': 'assets/leagueLogos/mlb.png',
      'NHL': 'assets/leagueLogos/nhl.png',
      'Soccer': 'assets/leagueLogos/soccer.png', // Note: may not exist
      'NCAAF': 'assets/leagueLogos/ncaa.png',
      'NCAAB': 'assets/leagueLogos/ncaa.png',
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
