class TeamLogoUtils {
  // Map team names to their logo assets
  static const Map<String, String> _teamLogos = {
    // NBA Teams
    'Lakers': 'assets/nbaLogos/los-angeles-lakers.svg',
    'Warriors': 'assets/nbaLogos/golden-state-warriors.svg',
    'Celtics': 'assets/nbaLogos/boston-celtics.svg',
    'Bulls': 'assets/nbaLogos/chicago-bulls.svg',
    'Heat': 'assets/nbaLogos/miami-heat.svg',
    'Knicks': 'assets/nbaLogos/new-york-knicks.svg',
    'Nets': 'assets/nbaLogos/brooklyn-nets.svg',
    'Clippers': 'assets/nbaLogos/los-angeles-clippers.svg',
    'Rockets': 'assets/nbaLogos/houston-rockets.svg',
    'Mavericks': 'assets/nbaLogos/dallas-mavericks.svg',
    'Nuggets': 'assets/nbaLogos/denver-nuggets.svg',
    'Hawks': 'assets/nbaLogos/atlanta-hawks-basketball-club.svg',
    'Hornets': 'assets/nbaLogos/charlotte-hornets.svg',
    'Cavaliers': 'assets/nbaLogos/cleveland-cavaliers.svg',
    'Pistons': 'assets/nbaLogos/detroit-pistons.svg', 
    'Pacers': 'assets/nbaLogos/indiana-pacers.svg',
    'Bucks': 'assets/nbaLogos/milwaukee-bucks.svg',
    'Timberwolves': 'assets/nbaLogos/minnesota-timberwolves.svg',
    'Pelicans': 'assets/nbaLogos/orleans-pelicans.svg',
    'Magic': 'assets/nbaLogos/orlando-magic.svg',
    '76ers': 'assets/nbaLogos/philidephia-76ers.svg',
    'Suns': 'assets/nbaLogos/phoenix-suns.svg',
    'Trail Blazers': 'assets/nbaLogos/portland-trail-blazers.svg',
    'Kings': 'assets/nbaLogos/sacramento-kings.svg',
    'Spurs': 'assets/nbaLogos/san-antonio-spurs.svg',
    'Raptors': 'assets/nbaLogos/toronto-raptors.svg',
    'Jazz': 'assets/nbaLogos/utah-jazz.svg',
    'Wizards': 'assets/nbaLogos/washington-wizards.svg',
    'Grizzlies': 'assets/nbaLogos/memphis-grizzlies.svg',
    
    // NFL Teams
    '49ers': 'assets/nflLogos/49ers.png',
    'Bears': 'assets/nflLogos/bears.png',
    'Bengals': 'assets/nflLogos/bengals.png',
    'Bills': 'assets/nflLogos/bills.png',
    'Broncos': 'assets/nflLogos/broncos.png',
    'Browns': 'assets/nflLogos/browns.png',
    'Buccaneers': 'assets/nflLogos/buccaneers.png',
    'Arizona Cardinals': 'assets/nflLogos/cardinals.png',
    'Chargers': 'assets/nflLogos/chargers.png',
    'Chiefs': 'assets/nflLogos/chiefs.png',
    'Colts': 'assets/nflLogos/colts.png',
    'Commanders': 'assets/nflLogos/commanders.png',
    'Cowboys': 'assets/nflLogos/cowboys.png',
    'Dolphins': 'assets/nflLogos/dolphins.png',
    'Eagles': 'assets/nflLogos/eagles.png',
    'Falcons': 'assets/nflLogos/falcons.png',
    'Giants': 'assets/nflLogos/giants.png',
    'Jaguars': 'assets/nflLogos/jaguars.png',
    'Jets': 'assets/nflLogos/jets.png',
    'Lions': 'assets/nflLogos/lions.png',
    'Packers': 'assets/nflLogos/packers.png',
    'Panthers': 'assets/nflLogos/panthers.png',
    'Patriots': 'assets/nflLogos/patriots.png',
    'Raiders': 'assets/nflLogos/raiders.png',
    'Rams': 'assets/nflLogos/rams.png',
    'Ravens': 'assets/nflLogos/ravens.png',
    'Saints': 'assets/nflLogos/saints.png',
    'Seahawks': 'assets/nflLogos/seahawks.png',
    'Steelers': 'assets/nflLogos/steelers.png',
    'Texans': 'assets/nflLogos/texans.png',
    'Titans': 'assets/nflLogos/titans.png',
    'Vikings': 'assets/nflLogos/vikings.png',
    
    // MLB Teams
    'Angels': 'assets/mlbLogos/angels.png',
    'Astros': 'assets/mlbLogos/astros.png',
    'Athletics': 'assets/mlbLogos/athletics.png',
    'Blue Jays': 'assets/mlbLogos/blueJays.png',
    'Braves': 'assets/mlbLogos/braves.png',
    'Brewers': 'assets/mlbLogos/brewers.png',
    'St. Louis Cardinals': 'assets/mlbLogos/cardinals.png',
    'Cubs': 'assets/mlbLogos/cubs.png',
    'Diamondbacks': 'assets/mlbLogos/diamondbacks.png',
    'Dodgers': 'assets/mlbLogos/dodgers.png',
    'SF Giants': 'assets/mlbLogos/giants.png',
    'Guardians': 'assets/mlbLogos/indians.png', // Updated name
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
  };

  /// Get the logo asset path for a team name
  static String? getTeamLogo(String teamName) {
    // Try exact match first
    if (_teamLogos.containsKey(teamName)) {
      return _teamLogos[teamName];
    }
    
    // Try partial matches
    for (final entry in _teamLogos.entries) {
      if (teamName.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(teamName.toLowerCase())) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Get sport-specific logo based on team name
  static String? getSportLogo(String sport) {
    switch (sport.toUpperCase()) {
      case 'NBA':
        return 'assets/leagueLogos/nba.png';
      case 'NFL':
        return 'assets/leagueLogos/nfl.png';
      case 'MLB':
        return 'assets/leagueLogos/mlb.png';
      case 'NHL':
        return 'assets/leagueLogos/nhl.png';
      case 'NCAAB':
      case 'NCAAF':
        return 'assets/leagueLogos/ncaa.png';
      default:
        return null;
    }
  }

  /// Get team colors for UI theming
  static Map<String, dynamic>? getTeamColors(String teamName) {
    final Map<String, Map<String, dynamic>> teamColors = {
      'Lakers': {'primary': 0xFF552583, 'secondary': 0xFFFDB927},
      'Warriors': {'primary': 0xFF1D428A, 'secondary': 0xFFFFC72C},
      'Celtics': {'primary': 0xFF007A33, 'secondary': 0xFFBA9653},
      'Chiefs': {'primary': 0xFFE31837, 'secondary': 0xFFFFB81C},
      'Cowboys': {'primary': 0xFF003594, 'secondary': 0xFF869397},
      // Add more team colors as needed
    };
    
    return teamColors[teamName];
  }
}
