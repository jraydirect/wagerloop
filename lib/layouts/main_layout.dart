// lib/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../pages/scores_page.dart';
import '../pages/news_page.dart';
import '../pages/social_feed_page.dart';
import '../pages/profile_page.dart';
import '../pages/discover_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _selectionController;
  late AnimationController _backgroundController;
  late Animation<double> _selectionAnimation;
  late Animation<double> _backgroundAnimation;

  final List<Widget> _pages = [
    ScoresPage(),
    NewsPage(),
    const DiscoverPage(),
    const SocialFeedPage(),
    ProfilePage(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.sports_football_outlined,
      'activeIcon': Icons.sports_football,
      'label': 'Scores',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
    },
    {
      'icon': Icons.newspaper_outlined,
      'activeIcon': Icons.newspaper,
      'label': 'News',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
    },
    {
      'icon': Icons.explore_outlined,
      'activeIcon': Icons.explore,
      'label': 'Discover',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
    },
    {
      'icon': Icons.groups_outlined,
      'activeIcon': Icons.groups,
      'label': 'Social',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person,
      'label': 'Profile',
      'color': const Color(0xFF4CAF50),
      'gradient': [const Color(0xFF4CAF50), const Color(0xFF45A049)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.elasticOut),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _selectionController.forward();
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index != _currentIndex) {
      _selectionController.reset();
      setState(() {
        _currentIndex = index;
      });
      _selectionController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      extendBody: true,
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          height: 75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _navItems[_currentIndex]['color'].withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Stack(
                  children: [
                    // Animated background orb
                    AnimatedBuilder(
                      animation: _backgroundAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: 20 + (200 * sin(_backgroundAnimation.value * 2 * pi)),
                          top: 10 + (15 * cos(_backgroundAnimation.value * 3 * pi)),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  _navItems[_currentIndex]['color'].withOpacity(0.4),
                                  _navItems[_currentIndex]['color'].withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Navigation items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_navItems.length, (index) {
                        return _buildNavItem(index);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = index == _currentIndex;

    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _onNavTap(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with selection animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 50 : 35,
                  height: isSelected ? 35 : 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSelected ? 18 : 8),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: item['gradient'],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: item['color'].withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Transform.scale(
                    scale: isSelected 
                        ? (0.8 + 0.4 * _selectionAnimation.value)
                        : 1.0,
                    child: Icon(
                      isSelected ? item['activeIcon'] : item['icon'],
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      size: isSelected ? 24 : 20,
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Label with smooth animation
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.6,
                  child: Text(
                    item['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
