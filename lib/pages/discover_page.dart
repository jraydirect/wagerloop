import 'package:flutter/material.dart';
import 'dart:math';
import 'stadium_info_page.dart';
import 'coaches_info_page.dart';
import 'referees_info_page.dart';
import 'wager_gpt_page.dart';
import 'weather_info_page.dart';
import 'communities_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({Key? key}) : super(key: key);

  @override
  _DiscoverPageState createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20), // Slower for more elegant movement
      vsync: this,
    )..repeat(); // Continuous endless animation
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        final progress = _backgroundAnimation.value;
        
        return Stack(
          children: [
            // Primary orbital system - Large elegant circles
            ..._buildPrimaryOrbitalSystem(progress),
            
            // Secondary ambient layer - Floating elements
            ..._buildSecondaryAmbientLayer(progress),
            
            // Tertiary detail layer - Subtle accents
            ..._buildTertiaryDetailLayer(progress),
          ],
        );
      },
    );
  }

  List<Widget> _buildPrimaryOrbitalSystem(double progress) {
    return [
      // Main orbital center - Large green presence
      Positioned(
        top: MediaQuery.of(context).size.height * 0.15 + (80 * sin(progress * 2 * pi)),
        right: MediaQuery.of(context).size.width * 0.25 + (120 * cos(progress * 2 * pi)),
        child: Transform.scale(
          scale: 1.0 + (0.15 * sin(progress * 2 * pi)),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.25),
                  const Color(0xFF10B981).withOpacity(0.15),
                  const Color(0xFF10B981).withOpacity(0.08),
                  const Color(0xFF10B981).withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Secondary orbital - Blue accent
      Positioned(
        top: MediaQuery.of(context).size.height * 0.45 + (100 * sin(progress * 1.5 * pi + pi/3)),
        left: MediaQuery.of(context).size.width * 0.1 + (100 * cos(progress * 1.5 * pi + pi/3)),
        child: Transform.scale(
          scale: 0.8 + (0.2 * cos(progress * 1.8 * pi)),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.2),
                  const Color(0xFF3B82F6).withOpacity(0.12),
                  const Color(0xFF3B82F6).withOpacity(0.06),
                  const Color(0xFF3B82F6).withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.55, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Tertiary orbital - Purple elegance
      Positioned(
        bottom: MediaQuery.of(context).size.height * 0.2 + (70 * sin(progress * 1.2 * pi + pi)),
        right: MediaQuery.of(context).size.width * 0.15 + (90 * cos(progress * 1.2 * pi + pi)),
        child: Transform.scale(
          scale: 0.9 + (0.1 * sin(progress * 2.2 * pi)),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.18),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                  const Color(0xFF8B5CF6).withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.06),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSecondaryAmbientLayer(double progress) {
    return List.generate(8, (index) {
      final offset = index * 0.4;
      final phase = progress + offset;
      final colors = [
        const Color(0xFF10B981),
        const Color(0xFF3B82F6),
        const Color(0xFF8B5CF6),
        const Color(0xFF06B6D4),
      ];
      final color = colors[index % colors.length];
      
      return Positioned(
        top: 100 + (index * 80) + (50 * sin(phase * 2 * pi)),
        left: (index.isEven ? 50 : MediaQuery.of(context).size.width - 100) + 
              (60 * cos(phase * 1.5 * pi)),
        child: Transform.scale(
          scale: (0.7 + 0.3 * sin(phase * 3 * pi)).clamp(0.4, 1.2),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.08),
                  color.withOpacity(0.03),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildTertiaryDetailLayer(double progress) {
    return [
      // Elegant flowing lines
      ...List.generate(3, (index) {
        final offset = index * 0.33;
        final lineProgress = (progress + offset) % 1.0;
        
        return Positioned(
          top: 200 + (index * 200),
          left: -100 + (MediaQuery.of(context).size.width + 200) * lineProgress,
          child: Transform.rotate(
            angle: progress * 0.5 * pi,
            child: Container(
              width: 120,
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF10B981).withOpacity(0.4),
                    const Color(0xFF10B981).withOpacity(0.8),
                    const Color(0xFF10B981).withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      
      // Subtle particle field
      ...List.generate(15, (index) {
        final offset = index * 0.2;
        final particlePhase = progress + offset;
        
        return Positioned(
          top: 50 + (index * 45) + (30 * sin(particlePhase * 2 * pi)),
          left: 30 + (index * 20) + (40 * cos(particlePhase * 1.8 * pi)),
          child: Transform.scale(
            scale: (0.3 + 0.4 * sin(particlePhase * 4 * pi)).clamp(0.1, 0.8),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  // Quick Access Tools - More Refined
  final List<Map<String, dynamic>> _quickTools = [
    {'name': 'Weather', 'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFF3B82F6), 'route': 'weather'},
    {'name': 'Coaches', 'icon': Icons.person_outline, 'color': const Color(0xFF8B5CF6), 'route': 'coaches'},
    {'name': 'Stadium', 'icon': Icons.stadium_outlined, 'color': const Color(0xFFEF4444), 'route': 'stadium'},
    {'name': 'Referees', 'icon': Icons.sports_outlined, 'color': const Color(0xFF10B981), 'route': 'referees'},
    {'name': 'Analytics', 'icon': Icons.analytics_outlined, 'color': const Color(0xFFF59E0B), 'route': null},
    {'name': 'News', 'icon': Icons.article_outlined, 'color': const Color(0xFF06B6D4), 'route': null},
  ];

  // Featured Services - Premium Design
  final List<Map<String, dynamic>> _featuredServices = [
    {
      'title': 'WagerGPT',
      'subtitle': 'AI-Powered Betting Intelligence',
      'icon': Icons.auto_awesome,
      'gradient': [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      'route': 'wagergpt',
      'tag': 'AI',
    },
    {
      'title': 'Communities',
      'subtitle': 'Connect & Share Insights',
      'icon': Icons.groups_2_outlined,
      'gradient': [const Color(0xFF059669), const Color(0xFF0891B2)],
      'route': 'communities',
      'tag': 'Social',
    },
    {
      'title': 'Live Analysis',
      'subtitle': 'Real-Time Game Insights',
      'icon': Icons.timeline_outlined,
      'gradient': [const Color(0xFFDC2626), const Color(0xFFEA580C)],
      'route': null,
      'tag': 'Live',
    },
    {
      'title': 'Expert Predictions',
      'subtitle': 'Professional Insights',
      'icon': Icons.verified_outlined,
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
      'route': null,
      'tag': 'Pro',
    },
  ];

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered WagerLoop Logo
          Center(
            child: Image.asset(
              'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
              height: 44,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessTool(Map<String, dynamic> tool, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleToolTap(tool),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1F2937).withOpacity(0.9),
                        const Color(0xFF1A202C).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon container
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tool['color'].withOpacity(0.15),
                              tool['color'].withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: tool['color'].withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: tool['color'].withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          tool['icon'],
                          color: tool['color'],
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tool name
                      Text(
                        tool['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickToolsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Top row - first 3 tools
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                    child: _buildQuickAccessTool(_quickTools[i], i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row - last 3 tools
          Row(
            children: [
              for (int i = 3; i < 6; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 5 ? 12 : 0),
                    child: _buildQuickAccessTool(_quickTools[i], i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServiceCard(Map<String, dynamic> service, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 120)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 25 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleServiceTap(service),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5), // Green trim
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Full Height Icon Container
                          Container(
                            width: 52,
                            height: double.infinity, // Full height of the card
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: service['gradient'] as List<Color>,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (service['gradient'] as List<Color>)[0].withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                service['icon'],
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Tag Row
                                Row(
                                  children: [
                                    Text(
                                      service['title'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (service['gradient'] as List<Color>)[0].withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (service['gradient'] as List<Color>)[0].withOpacity(0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        service['tag'],
                                        style: TextStyle(
                                          color: (service['gradient'] as List<Color>)[0],
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                // Subtitle
                                Text(
                                  service['subtitle'],
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Refined Arrow
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleToolTap(Map<String, dynamic> tool) {
    switch (tool['route']) {
      case 'weather':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherInfoPage()));
        break;
      case 'coaches':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CoachesInfoPage()));
        break;
      case 'stadium':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StadiumInfoPage()));
        break;
      case 'referees':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const RefereesInfoPage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tool['name']} coming soon!'),
            backgroundColor: tool['color'],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  void _handleServiceTap(Map<String, dynamic> service) {
    switch (service['route']) {
      case 'wagergpt':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WagerGPTPage()));
        break;
      case 'communities':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunitiesPage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${service['title']} coming soon!'),
            backgroundColor: (service['gradient'] as List<Color>)[0],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A), // Premium dark slate at top
              const Color(0xFF0C1220), // Deep midnight in middle
              const Color(0xFF0B1018), // Rich black at bottom
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned.fill(
              child: _buildAnimatedBackground(),
            ),
            // Main content
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Refined Header
                        SliverToBoxAdapter(
                          child: _buildHeader(),
                        ),

                        // Quick Access Section
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    Text(
                                      'Quick Access',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 40,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF10B981),
                                            const Color(0xFF10B981).withOpacity(0.3),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildQuickToolsGrid(),
                            ],
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 44)),

                        // Featured Services Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Featured Services',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.6,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 40,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF8B5CF6),
                                                const Color(0xFF8B5CF6).withOpacity(0.3),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Premium tools and integrations',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey[800]!.withOpacity(0.6),
                                        Colors.grey[900]!.withOpacity(0.4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[600]!.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'See All',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Featured Services List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildFeaturedServiceCard(_featuredServices[index], index),
                              childCount: _featuredServices.length,
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
