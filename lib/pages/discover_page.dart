import 'package:flutter/material.dart';
import 'stadium_info_page.dart';
import 'coaches_info_page.dart';
import 'wager_gpt_page.dart';
import 'weather_info_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Small square tools for horizontal scrolling (organized in pairs for 2 rows)
  final List<List<Map<String, dynamic>>> _toolRows = [
    [
      {'name': 'Injury Watch', 'icon': Icons.medical_services, 'color': Colors.red},
      {'name': 'Coaches', 'icon': Icons.person, 'color': Colors.blue},
      {'name': 'Stadium Info', 'icon': Icons.stadium, 'color': Colors.orange},
      {'name': 'Referees', 'icon': Icons.sports, 'color': Colors.purple},
      {'name': 'Weather', 'icon': Icons.wb_sunny, 'color': Colors.yellow},
      {'name': 'Schedule', 'icon': Icons.schedule, 'color': Colors.teal},
    ],
    [
      {'name': 'Stats', 'icon': Icons.bar_chart, 'color': Colors.indigo},
      {'name': 'Teams', 'icon': Icons.groups, 'color': Colors.pink},
      {'name': 'Players', 'icon': Icons.sports_basketball, 'color': Colors.cyan},
      {'name': 'Odds', 'icon': Icons.trending_up, 'color': Colors.lime},
      {'name': 'News', 'icon': Icons.newspaper, 'color': Colors.amber},
      {'name': 'Videos', 'icon': Icons.play_circle, 'color': Colors.deepOrange},
    ],
  ];

  // Long rectangular features for vertical scrolling
  final List<Map<String, dynamic>> _features = [
    {'name': 'WagerGPT', 'icon': Icons.smart_toy, 'description': 'AI-powered betting insights', 'gradient': [Colors.green, Colors.teal]},
    {'name': 'Momentum Tracker', 'icon': Icons.trending_up, 'description': 'Track game momentum changes', 'gradient': [Colors.blue, Colors.indigo]},
    {'name': 'Leaderboards', 'icon': Icons.leaderboard, 'description': 'Top performers and rankings', 'gradient': [Colors.orange, Colors.red]},
    {'name': 'Communities', 'icon': Icons.forum, 'description': 'Connect with fellow fans', 'gradient': [Colors.purple, Colors.pink]},
    {'name': 'Live Analysis', 'icon': Icons.analytics, 'description': 'Real-time game analysis', 'gradient': [Colors.teal, Colors.cyan]},
    {'name': 'Prediction Hub', 'icon': Icons.psychology, 'description': 'Make and track predictions', 'gradient': [Colors.indigo, Colors.blue]},
    {'name': 'Expert Picks', 'icon': Icons.star, 'description': 'Professional predictions', 'gradient': [Colors.amber, Colors.orange]},
    {'name': 'Betting Calculator', 'icon': Icons.calculate, 'description': 'Calculate potential payouts', 'gradient': [Colors.green, Colors.lightGreen]},
  ];

  Widget _buildToolCard(Map<String, dynamic> tool, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 50)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[700]!.withOpacity(0.9),
                    Colors.grey[800]!.withOpacity(0.95),
                    Colors.grey[900]!.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: tool['color'].withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (tool['name'] == 'Stadium Info') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StadiumInfoPage(),
                        ),
                      );
                    } else if (tool['name'] == 'Coaches') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CoachesInfoPage(),
                        ),
                      );
                    } else if (tool['name'] == 'Weather') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeatherInfoPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(tool['icon'], color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('${tool['name']} activated'),
                            ],
                          ),
                          backgroundColor: tool['color'].withOpacity(0.9),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(22),
                  splashColor: tool['color'].withOpacity(0.3),
                  highlightColor: tool['color'].withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tool['color'].withOpacity(0.3),
                              tool['color'].withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: tool['color'].withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tool['color'].withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          tool['icon'],
                          size: 24,
                          color: tool['color'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[700]!.withOpacity(0.95),
                      Colors.grey[800]!.withOpacity(0.9),
                      Colors.grey[850]!.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -3,
                    ),
                    BoxShadow(
                      color: (feature['gradient'] as List<Color>)[0].withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (feature['name'] == 'WagerGPT') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WagerGPTPage(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: feature['gradient'] as List<Color>,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(feature['icon'], color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Text('${feature['name']} activated'),
                              ],
                            ),
                            backgroundColor: (feature['gradient'] as List<Color>)[0].withOpacity(0.9),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    splashColor: (feature['gradient'] as List<Color>)[0].withOpacity(0.2),
                    highlightColor: (feature['gradient'] as List<Color>)[0].withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  (feature['gradient'] as List<Color>)[0],
                                  (feature['gradient'] as List<Color>)[1],
                                  (feature['gradient'] as List<Color>)[0].withOpacity(0.8),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (feature['gradient'] as List<Color>)[0].withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                  spreadRadius: -3,
                                ),
                              ],
                            ),
                            child: Icon(
                              feature['icon'],
                              color: Colors.white,
                              size: 28,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feature['description'],
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                    height: 1.3,
                                    letterSpacing: 0.1,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildToolsGrid() {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, columnIndex) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            child: Column(
              children: [
                // First row
                if (columnIndex < _toolRows[0].length)
                  _buildToolCard(_toolRows[0][columnIndex], columnIndex),
                const SizedBox(height: 10),
                // Second row
                if (columnIndex < _toolRows[1].length)
                  _buildToolCard(_toolRows[1][columnIndex], columnIndex + 6),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Discover',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Tools section - more compact
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.grey],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Quick Tools',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.3),
                              Colors.green.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Two-row horizontally scrollable tools - more compact
                _buildToolsGrid(),

                const SizedBox(height: 20),

                // Features section header - moved up
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.grey],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Features',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.2),
                              Colors.green.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Vertically scrollable features section - more room now
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _features.length,
                    itemBuilder: (context, index) => _buildFeatureCard(_features[index], index),
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
