// lib/utils/team_logo_utils.dart

class TeamLogoUtils {
  static String getTeamLogo(String teamName, String sport) {
    switch (sport) {
      case 'basketball_nba':
        return _getNBALogo(teamName);
      case 'icehockey_nhl':
        return _getNHLLogo(teamName);
      case 'americanfootball_nfl':
        return _getNFLLogo(teamName);
      case 'baseball_mlb':
        return _getMLBLogo(teamName);
      default:
        return '';
    }
  }

  static String _getNFLLogo(String teamName) {
    final Map<String, String> nflTeamLogoMap = {
      'Arizona Cardinals': 'cardinals.png',
      'Atlanta Falcons': 'falcons.png',
      'Baltimore Ravens': 'ravens.png',
      'Buffalo Bills': 'bills.png',
      'Carolina Panthers': 'panthers.png',
      'Chicago Bears': 'bears.png',
      'Cincinnati Bengals': 'bengals.png',
      'Cleveland Browns': 'browns.png',
      'Dallas Cowboys': 'cowboys.png',
      'Denver Broncos': 'broncos.png',
      'Detroit Lions': 'lions.png',
      'Green Bay Packers': 'packers.png',
      'Houston Texans': 'texans.png',
      'Indianapolis Colts': 'colts.png',
      'Jacksonville Jaguars': 'jaguars.png',
      'Kansas City Chiefs': 'chiefs.png',
      'Las Vegas Raiders': 'raiders.png',
      'Los Angeles Chargers': 'chargers.png',
      'Los Angeles Rams': 'rams.png',
      'Miami Dolphins': 'dolphins.png',
      'Minnesota Vikings': 'vikings.png',
      'New England Patriots': 'patriots.png',
      'New Orleans Saints': 'saints.png',
      'New York Giants': 'giants.png',
      'New York Jets': 'jets.png',
      'Philadelphia Eagles': 'eagles.png',
      'Pittsburgh Steelers': 'steelers.png',
      'San Francisco 49ers': '49ers.png',
      'Seattle Seahawks': 'seahawks.png',
      'Tampa Bay Buccaneers': 'buccaneers.png',
      'Tennessee Titans': 'titans.png',
      'Washington Commanders': 'commanders.png',
    };

    return nflTeamLogoMap[teamName] ?? '';
  }

  static String _getMLBLogo(String teamName) {
    final Map<String, String> mlbTeamLogoMap = {
      'Los Angeles Angels': 'angels.png',
      'Houston Astros': 'astros.png',
      'Oakland Athletics': 'athletics.png',
      'Toronto Blue Jays': 'blueJays.png',
      'Atlanta Braves': 'braves.png',
      'Milwaukee Brewers': 'brewers.png',
      'St. Louis Cardinals': 'cardinals.png',
      'Chicago Cubs': 'cubs.png',
      'Arizona Diamondbacks': 'diamondbacks.png',
      'Los Angeles Dodgers': 'dodgers.png',
      'San Francisco Giants': 'giants.png',
      'Cleveland Guardians': 'indians.png', // Note: keeping old filename for now
      'Seattle Mariners': 'mariners.png',
      'Miami Marlins': 'marlins.png',
      'New York Mets': 'mets.png',
      'Washington Nationals': 'nationals.png',
      'Baltimore Orioles': 'orioles.png',
      'San Diego Padres': 'padres.png',
      'Philadelphia Phillies': 'phillies.png',
      'Pittsburgh Pirates': 'pirates.png',
      'Texas Rangers': 'rangers.png',
      'Tampa Bay Rays': 'rays.png',
      'Cincinnati Reds': 'reds.png',
      'Boston Red Sox': 'redSox.png',
      'Colorado Rockies': 'rockies.png',
      'Kansas City Royals': 'royals.png',
      'Detroit Tigers': 'tigers.png',
      'Minnesota Twins': 'twins.png',
      'Chicago White Sox': 'whiteSox.png',
      'New York Yankees': 'yankees.png',
    };

    return mlbTeamLogoMap[teamName] ?? '';
  }

  static String _getNBALogo(String teamName) {
    final Map<String, String> nbaTeamLogoMap = {
      'Atlanta Hawks': 'atlanta-hawks-basketball-club.svg',
      'Boston Celtics': 'boston-celtics.svg',
      'Brooklyn Nets': 'brooklyn-nets.svg',
      'Charlotte Hornets': 'charlotte-hornets.svg',
      'Chicago Bulls': 'chicago-bulls.svg',
      'Cleveland Cavaliers': 'cleveland-cavaliers.svg',
      'Dallas Mavericks': 'dallas-mavericks.svg',
      'Denver Nuggets': 'denver-nuggets.svg',
      'Golden State Warriors': 'golden-state-warriors.svg',
      'Houston Rockets': 'houston-rockets.svg',
      'Indiana Pacers': 'indiana-pacers.svg',
      'LA Clippers': 'los-angeles-clippers.svg',
      'Los Angeles Lakers': 'los-angeles-lakers.svg',
      'Memphis Grizzlies': 'memphis-grizzlies.svg',
      'Miami Heat': 'miami-heat.svg',
      'Milwaukee Bucks': 'milwaukee-bucks.svg',
      'Minnesota Timberwolves': 'minnesota-timberwolves.svg',
      'New Orleans Pelicans': 'orleans-pelicans.svg',
      'New York Knicks': 'new-york-knicks.svg',
      'Oklahoma City Thunder': 'oklahoma-city-thunder.svg',
      'Orlando Magic': 'orlando-magic.svg',
      'Philadelphia 76ers': 'philidephia-76ers.svg',
      'Phoenix Suns': 'phoenix-suns.svg',
      'Portland Trail Blazers': 'portland-trail-blazers.svg',
      'Sacramento Kings': 'sacramento-kings.svg',
      'San Antonio Spurs': 'san-antonio-spurs.svg',
      'Toronto Raptors': 'toronto-raptors.svg',
      'Utah Jazz': 'utah-jazz.svg',
      'Washington Wizards': 'washington-wizards.svg',
    };

    return nbaTeamLogoMap[teamName] ?? '';
  }

  static String _getNHLLogo(String teamName) {
    final Map<String, String> nhlTeamLogoMap = {
      'Anaheim Ducks': 'ana_l.svg',
      'Arizona Coyotes': 'ari_l.svg',
      'Boston Bruins': 'bos_l.svg',
      'Buffalo Sabres': 'buf_l.svg',
      'Calgary Flames': 'cgy_l.svg',
      'Carolina Hurricanes': 'car_l.svg',
      'Chicago Blackhawks': 'chi_l.svg',
      'Colorado Avalanche': 'col_l.svg',
      'Columbus Blue Jackets': 'cbj_l.svg',
      'Dallas Stars': 'dal_l.svg',
      'Detroit Red Wings': 'det_l.svg',
      'Edmonton Oilers': 'edm_l.svg',
      'Florida Panthers': 'fla_l.svg',
      'Los Angeles Kings': 'lak_l.svg',
      'Minnesota Wild': 'min_l.svg',
      'Montreal Canadiens': 'mtl_l.svg',
      'Nashville Predators': 'nsh_l.svg',
      'New Jersey Devils': 'njd_l.svg',
      'New York Islanders': 'nyi_l.svg',
      'New York Rangers': 'nyr_l.svg',
      'Ottawa Senators': 'ott_l.svg',
      'Philadelphia Flyers': 'phi_l.svg',
      'Pittsburgh Penguins': 'pit_l.svg',
      'San Jose Sharks': 'sjs_l.svg',
      'St Louis Blues': 'stl_l.svg',
      'Tampa Bay Lightning': 'tbl_l.svg',
      'Toronto Maple Leafs': 'tor_l.svg',
      'Vancouver Canucks': 'van_l.svg',
      'Vegas Golden Knights': 'vgk_l.svg',
      'Washington Capitals': 'wsh_l.svg',
      'Winnipeg Jets': 'wng_l.svg',
      'Utah Club': 'uth_l.svg',
    };

    return nhlTeamLogoMap[teamName] ?? '';
  }

  static String getLogoPath(String teamName, String sport) {
    String logoFile = getTeamLogo(teamName, sport);
    if (logoFile.isEmpty) return '';

    switch (sport) {
      case 'basketball_nba':
        return 'assets/nbaLogos/$logoFile';
      case 'icehockey_nhl':
        return 'assets/nhlLogos/$logoFile';
      case 'americanfootball_nfl':
        return 'assets/nflLogos/$logoFile';
      case 'baseball_mlb':
        return 'assets/mlbLogos/$logoFile';
      default:
        return '';
    }
  }
}
