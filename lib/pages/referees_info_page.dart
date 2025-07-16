import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class RefereesInfoPage extends StatefulWidget {
  const RefereesInfoPage({Key? key}) : super(key: key);

  @override
  _RefereesInfoPageState createState() => _RefereesInfoPageState();
}

class _RefereesInfoPageState extends State<RefereesInfoPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedSport = 'NBA';
  List<dynamic> _refereeData = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> _sportsOptions = [
    {
      'name': 'NBA',
      'icon': Icons.sports_basketball,
      'color': Colors.blue,
      'available': true,
      'fileName': 'lib/nbaRefereesInfo.json',
      'title': 'Referees',
    },
    {
      'name': 'NFL',
      'icon': Icons.sports_football,
      'color': Colors.purple,
      'available': true,
      'fileName': 'lib/nflRefereesInfo.json',
      'title': 'Referees',
    },
    {
      'name': 'MLB',
      'icon': Icons.sports_baseball,
      'color': Colors.orange,
      'available': true,
      'fileName': 'lib/mlbUmpiresInfo.json',
      'title': 'Umpires',
    },
    {
      'name': 'NHL',
      'icon': Icons.sports_hockey,
      'color': Colors.teal,
      'available': false,
      'fileName': '',
      'title': 'Referees',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRefereeData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadRefereeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Find the selected sport's file name
      final selectedSport = _sportsOptions.firstWhere(
        (sport) => sport['name'] == _selectedSport,
        orElse: () => _sportsOptions.first,
      );
      
      if (!selectedSport['available']) {
        setState(() {
          _refereeData = [];
          _isLoading = false;
        });
        return;
      }
      
      final String fileName = selectedSport['fileName'] as String;
      if (fileName.isEmpty) {
        throw Exception('No data file specified for $_selectedSport');
      }
      
      final String jsonString = await rootBundle.loadString(fileName);
      final List<dynamic> data = json.decode(jsonString);
      
      setState(() {
        _refereeData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load referee data: $e';
        _isLoading = false;
      });
    }
  }

  String get _currentTitle {
    final selectedSport = _sportsOptions.firstWhere(
      (sport) => sport['name'] == _selectedSport,
      orElse: () => _sportsOptions.first,
    );
    return selectedSport['title'] ?? 'Referees';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildSportSelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sportsOptions.length,
        itemBuilder: (context, index) {
          final sport = _sportsOptions[index];
          final isSelected = _selectedSport == sport['name'];
          final isAvailable = sport['available'] as bool;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          _selectedSport = sport['name'];
                        });
                        _loadRefereeData();
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${sport['name']} ${sport['title']?.toLowerCase()} data coming soon!'),
                            backgroundColor: Colors.blue.withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected && isAvailable
                        ? LinearGradient(
                            colors: [
                              sport['color'].withOpacity(0.8),
                              sport['color'].withOpacity(0.6),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey[700]!.withOpacity(0.8),
                              Colors.grey[800]!.withOpacity(0.6),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected && isAvailable
                          ? sport['color'].withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: isSelected && isAvailable
                        ? [
                            BoxShadow(
                              color: sport['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sport['icon'],
                        color: isAvailable
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sport['name'],
                        style: TextStyle(
                          color: isAvailable
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefereeCard(Map<String, dynamic> referee, int index) {
    String subtitle = 'Age: ${referee['age'] ?? 'Unknown'}';
    Color iconColor = Colors.purple;
    IconData iconData = Icons.sports;
    
    // Customize based on sport
    if (_selectedSport == 'NBA') {
      iconColor = Colors.blue;
      iconData = Icons.sports_basketball;
    } else if (_selectedSport == 'NFL') {
      iconColor = Colors.purple;
      iconData = Icons.sports_football;
    } else if (_selectedSport == 'MLB') {
      iconColor = Colors.orange;
      iconData = Icons.sports_baseball;
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 50)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[700]!.withOpacity(0.95),
                      Colors.grey[800]!.withOpacity(0.9),
                      Colors.grey[850]!.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showRefereeDetails(referee),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  iconColor.withOpacity(0.8),
                                  iconColor.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              iconData,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  referee['name'] ?? 'Unknown ${_currentTitle.substring(0, _currentTitle.length - 1)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      },
    );
  }

  void _showRefereeDetails(Map<String, dynamic> referee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefereeDetailsSheet(
        referee: referee, 
        sport: _selectedSport,
        title: _currentTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$_currentTitle Info',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                _buildSportSelector(),
                if (_isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading data',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadRefereeData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_refereeData.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No ${_currentTitle.toLowerCase()} data available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _refereeData.length,
                      itemBuilder: (context, index) {
                        return _buildRefereeCard(_refereeData[index], index);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RefereeDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> referee;
  final String sport;
  final String title;

  const RefereeDetailsSheet({
    Key? key, 
    required this.referee, 
    required this.sport,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tendencies = referee['tendencies'] as Map<String, dynamic>?;
    final playerSurvey = tendencies?['player_survey'] as Map<String, dynamic>?;
    final reputation = tendencies?['reputation'] as Map<String, dynamic>?;
    
    Color iconColor = Colors.purple;
    IconData iconData = Icons.sports;
    
    if (sport == 'NBA') {
      iconColor = Colors.blue;
      iconData = Icons.sports_basketball;
    } else if (sport == 'NFL') {
      iconColor = Colors.purple;
      iconData = Icons.sports_football;
    } else if (sport == 'MLB') {
      iconColor = Colors.orange;
      iconData = Icons.sports_baseball;
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[800]!,
            Colors.grey[850]!,
            Colors.grey[900]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withOpacity(0.8),
                              iconColor.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              referee['name'] ?? 'Unknown ${title.substring(0, title.length - 1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Age: ${referee['age'] ?? 'Unknown'}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Game Statistics
                  if (tendencies != null) ...[
                    _buildSectionTitle('Statistics'),
                    
                    // NBA specific fields
                    if (sport == 'NBA') ...[
                      if (tendencies['home_fouls_per_game'] != null)
                        _buildDetailSection(
                          'Home Fouls per Game',
                          '${tendencies['home_fouls_per_game']}',
                          Icons.home,
                          Colors.green,
                        ),
                      if (tendencies['road_fouls_per_game'] != null)
                        _buildDetailSection(
                          'Road Fouls per Game',
                          '${tendencies['road_fouls_per_game']}',
                          Icons.flight_takeoff,
                          Colors.orange,
                        ),
                      if (tendencies['home_win_pct'] != null)
                        _buildDetailSection(
                          'Home Win %',
                          '${(tendencies['home_win_pct'] * 100).toStringAsFixed(1)}%',
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      if (tendencies['home_win_margin'] != null)
                        _buildDetailSection(
                          'Home Win Margin',
                          '${tendencies['home_win_margin']}',
                          Icons.bar_chart,
                          Colors.cyan,
                        ),
                      if (tendencies['foul_whistle_rate'] != null)
                        _buildDetailSection(
                          'Foul Whistle Rate',
                          '${tendencies['foul_whistle_rate']}',
                          Icons.sports_basketball,
                          Colors.red,
                        ),
                    ],
                    
                    // NFL specific fields
                    if (sport == 'NFL') ...[
                      if (tendencies['penalties_per_game'] != null)
                        _buildDetailSection(
                          'Penalties per Game',
                          '${tendencies['penalties_per_game']}',
                          Icons.flag,
                          Colors.red,
                        ),
                      if (tendencies['flags_per_game'] != null)
                        _buildDetailSection(
                          'Flags per Game',
                          '${tendencies['flags_per_game']}',
                          Icons.outlined_flag,
                          Colors.orange,
                        ),
                      if (tendencies['challenge_rate'] != null)
                        _buildDetailSection(
                          'Challenge Rate',
                          '${tendencies['challenge_rate']}',
                          Icons.gavel,
                          Colors.blue,
                        ),
                    ],
                    
                    // MLB specific fields
                    if (sport == 'MLB') ...[
                      if (tendencies['strike_zone_accuracy'] != null)
                        _buildDetailSection(
                          'Strike Zone Accuracy',
                          '${tendencies['strike_zone_accuracy']}',
                          Icons.center_focus_strong,
                          Colors.green,
                        ),
                      if (tendencies['challenge_overturn_rate'] != null)
                        _buildDetailSection(
                          'Challenge Overturn Rate',
                          '${tendencies['challenge_overturn_rate']}',
                          Icons.replay,
                          Colors.orange,
                        ),
                      if (tendencies['ejections_per_game'] != null)
                        _buildDetailSection(
                          'Ejections per Game',
                          '${tendencies['ejections_per_game']}',
                          Icons.exit_to_app,
                          Colors.red,
                        ),
                    ],
                    
                    // Common fields
                    if (tendencies['experience_years'] != null)
                      _buildDetailSection(
                        'Experience',
                        '${tendencies['experience_years']} years',
                        Icons.timeline,
                        Colors.purple,
                      ),
                    if (tendencies['games_officiated'] != null)
                      _buildDetailSection(
                        'Games Officiated',
                        '${tendencies['games_officiated']}',
                        Icons.sports,
                        Colors.indigo,
                      ),
                    if (tendencies['playoff_games'] != null)
                      _buildDetailSection(
                        'Playoff Games',
                        '${tendencies['playoff_games']}',
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                  ],
                  
                  // Player Survey Section (NBA/NFL)
                  if (playerSurvey != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Player Survey'),
                    if (playerSurvey['best_votes_pct'] != null)
                      _buildDetailSection(
                        'Best Official Votes',
                        '${playerSurvey['best_votes_pct']}%',
                        Icons.thumb_up,
                        Colors.green,
                      ),
                    if (playerSurvey['worst_votes_pct'] != null)
                      _buildDetailSection(
                        'Worst Official Votes',
                        '${playerSurvey['worst_votes_pct']}%',
                        Icons.thumb_down,
                        Colors.red,
                      ),
                    
                    // Player Quotes
                    if (playerSurvey['quotes'] != null) ...[
                      const SizedBox(height: 16),
                      _buildQuotesSection(playerSurvey['quotes'] as List<dynamic>),
                    ],
                    
                    if (playerSurvey['source'] != null)
                      _buildDetailSection(
                        'Survey Source',
                        '${playerSurvey['source']}',
                        Icons.source,
                        Colors.teal,
                      ),
                  ],
                  
                  // MLB Reputation Section
                  if (reputation != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Reputation'),
                    
                    if (reputation['best_traits'] != null)
                      _buildTraitsSection(
                        'Best Traits',
                        reputation['best_traits'] as List<dynamic>,
                        Colors.green,
                        Icons.thumb_up,
                      ),
                    
                    if (reputation['worst_traits'] != null)
                      _buildTraitsSection(
                        'Areas for Improvement',
                        reputation['worst_traits'] as List<dynamic>,
                        Colors.orange,
                        Icons.warning,
                      ),
                  ],
                  
                  // Additional Notes
                  if (tendencies?['notes'] != null) ...[
                    const SizedBox(height: 20),
                    _buildNotesSection(tendencies!['notes'] as String),
                  ],
                  
                  // Reputation Notes (MLB)
                  if (reputation?['notes'] != null) ...[
                    const SizedBox(height: 16),
                    _buildNotesSection(reputation!['notes'] as String),
                  ],
                  
                  // Nicknames (NBA/NFL)
                  if (tendencies?['nicknames'] != null) ...[
                    const SizedBox(height: 16),
                    _buildNicknamesSection(tendencies!['nicknames'] as List<dynamic>),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesSection(List<dynamic> quotes) {
    if (quotes.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_quote,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Player Quotes',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...quotes.map((quote) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '"$quote"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTraitsSection(String title, List<dynamic> traits, Color color, IconData icon) {
    if (traits.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...traits.map((trait) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trait.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notes,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Additional Notes',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknamesSection(List<dynamic> nicknames) {
    if (nicknames.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tag,
                  color: Colors.pink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Nicknames',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nicknames.map((nickname) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.pink.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                nickname.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
} 