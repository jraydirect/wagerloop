import 'package:flutter/material.dart';
import 'dart:math' as math;

class FigmaBouncyLoader extends StatefulWidget {
  const FigmaBouncyLoader({super.key});

  @override
  State<FigmaBouncyLoader> createState() => _FigmaBouncyLoaderState();
}

class _FigmaBouncyLoaderState extends State<FigmaBouncyLoader>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bounceController;
  late List<AnimationController> _ballControllers;

  // Figma-style gradient colors
  final List<Color> gradientColors = [
    const Color(0xFF667eea),
    const Color(0xFF764ba2),
  ];

  // Ball colors (typical Figma palette)
  final List<Color> ballColors = [
    const Color(0xFFFF6B6B), // Coral
    const Color(0xFF4ECDC4), // Turquoise
    const Color(0xFF45B7D1), // Sky Blue
    const Color(0xFF96CEB4), // Mint
    const Color(0xFFFECA57), // Yellow
    const Color(0xFFFF9FF3), // Pink
    const Color(0xFF54A0FF), // Blue
  ];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create individual controllers for each ball
    _ballControllers = List.generate(
      7,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 50)),
        vsync: this,
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Start main fade in
    _mainController.forward();

    // Start ball animations with staggered delays
    for (int i = 0; i < _ballControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      if (mounted) {
        _ballControllers[i].repeat(reverse: true);
      }
    }

    // Start continuous bounce animation
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _bounceController.repeat();
    }

    // Navigate after splash duration
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    for (var controller in _ballControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Opacity(
              opacity: Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                    parent: _mainController,
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  ))
                  .value,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo Section
                    Transform.scale(
                      scale: Tween<double>(begin: 0.5, end: 1.0)
                          .animate(CurvedAnimation(
                            parent: _mainController,
                            curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
                          ))
                          .value,
                      child: Column(
                        children: [
                          // Main Logo Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.9),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.casino,
                              size: 50,
                              color: gradientColors[1],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // App Title
                          const Text(
                            'WagerLoop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Sports Betting Reimagined',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Bouncing Balls Animation
                    SizedBox(
                      height: 120,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_bounceController, ..._ballControllers]),
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              final controller = _ballControllers[index];
                              
                              // Create wave effect
                              final waveOffset = math.sin((_bounceController.value * 2 * math.pi) + (index * 0.5));
                              final baseHeight = 60.0;
                              final waveHeight = 20.0;
                              final totalHeight = baseHeight + (waveHeight * waveOffset.abs());
                              
                              // Individual ball bounce
                              final ballBounce = Curves.bounceOut.transform(controller.value);
                              final bounceHeight = totalHeight * ballBounce;

                              // Scale effect
                              final scale = 0.7 + (0.6 * controller.value);

                              return Transform.translate(
                                offset: Offset(0, -bounceHeight),
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: ballColors[index],
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ballColors[index].withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 4,
                                          spreadRadius: 0,
                                          offset: const Offset(-1, -1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading Text with Pulse Effect
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        final pulse = 0.8 + (0.2 * math.sin(_bounceController.value * 2 * math.pi));
                        return Transform.scale(
                          scale: pulse,
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 3,
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
