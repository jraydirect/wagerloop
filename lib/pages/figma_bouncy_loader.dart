// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import math library for mathematical operations
import 'dart:math' as math;

// FigmaBouncyLoader class definition - a stateful widget for Figma-style animated loader
class FigmaBouncyLoader extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const FigmaBouncyLoader({super.key});

  // Override createState method to return the state class instance
  @override
  State<FigmaBouncyLoader> createState() => _FigmaBouncyLoaderState();
}

// Private state class that manages the Figma bouncy loader's state and animations
class _FigmaBouncyLoaderState extends State<FigmaBouncyLoader>
    with TickerProviderStateMixin {
  // Main animation controller for overall fade and scale animations
  late AnimationController _mainController;
  // Bounce animation controller for continuous bouncing effects
  late AnimationController _bounceController;
  // List of animation controllers for individual ball animations
  late List<AnimationController> _ballControllers;

  // Figma-style gradient colors
  // List of gradient colors for background styling
  final List<Color> gradientColors = [
    const Color(0xFF667eea),
    const Color(0xFF764ba2),
  ];

  // Ball colors (typical Figma palette)
  // List of colors for bouncing balls using Figma-style palette
  final List<Color> ballColors = [
    const Color(0xFFFF6B6B), // Coral
    const Color(0xFF4ECDC4), // Turquoise
    const Color(0xFF45B7D1), // Sky Blue
    const Color(0xFF96CEB4), // Mint
    const Color(0xFFFECA57), // Yellow
    const Color(0xFFFF9FF3), // Pink
    const Color(0xFF54A0FF), // Blue
  ];

  // Override initState to initialize the widget state and animations
  @override
  void initState() {
    // Call parent initState
    super.initState();

    // Initialize main animation controller with 2-second duration
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize bounce animation controller with 1.2-second duration
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create individual controllers for each ball
    _ballControllers = List.generate(
      7, // Generate 7 ball controllers
      (index) => AnimationController(
        // Each ball has slightly different duration for varied timing
        duration: Duration(milliseconds: 800 + (index * 50)),
        vsync: this,
      ),
    );

    // Start the splash screen animation sequence
    _startAnimation();
  }

  // Async method to orchestrate the animation sequence
  void _startAnimation() async {
    // Start main fade in
    _mainController.forward();

    // Start ball animations with staggered delays
    for (int i = 0; i < _ballControllers.length; i++) {
      // Delay each ball animation by 100ms * index
      await Future.delayed(Duration(milliseconds: i * 100));
      // Start ball animation if widget is still mounted
      if (mounted) {
        // Repeat animation in reverse for bouncing effect
        _ballControllers[i].repeat(reverse: true);
      }
    }

    // Start continuous bounce animation
    await Future.delayed(const Duration(milliseconds: 500));
    // Start bounce animation if widget is still mounted
    if (mounted) {
      _bounceController.repeat();
    }

    // Navigate after splash duration
    await Future.delayed(const Duration(seconds: 4));
    // Navigate to home page if widget is still mounted
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose main animation controller
    _mainController.dispose();
    // Dispose bounce animation controller
    _bounceController.dispose();
    // Dispose all ball animation controllers
    for (var controller in _ballControllers) {
      controller.dispose();
    }
    // Call parent dispose
    super.dispose();
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with Figma-style loader content
    return Scaffold(
      // Container body with gradient background
      body: Container(
        // Full width and height
        width: double.infinity,
        height: double.infinity,
        // Gradient background decoration
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Gradient from top-left to bottom-right
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Use predefined gradient colors
            colors: gradientColors,
            // Color stops for gradient transition
            stops: const [0.0, 1.0],
          ),
        ),
        // Animated builder for main fade animation
        child: AnimatedBuilder(
          // Listen to main animation controller
          animation: _mainController,
          // Builder function for animated content
          builder: (context, child) {
            // Opacity widget for fade effect
            return Opacity(
              // Opacity from 0 to 1 with fade animation
              opacity: Tween<double>(begin: 0.0, end: 1.0)
                  .animate(CurvedAnimation(
                    parent: _mainController,
                    // Animate from 0% to 50% of main animation
                    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                  ))
                  .value,
              // Safe area to avoid system UI overlaps
              child: SafeArea(
                // Column to arrange loader elements vertically
                child: Column(
                  // Center the column contents
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top spacer with flex of 2
                    const Spacer(flex: 2),

                    // Logo Section
                    // Transform scale for logo animation
                    Transform.scale(
                      // Scale from 0.5 to 1.0 with elastic animation
                      scale: Tween<double>(begin: 0.5, end: 1.0)
                          .animate(CurvedAnimation(
                            parent: _mainController,
                            // Animate from 30% to 80% of main animation
                            curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
                          ))
                          .value,
                      // Column containing logo and text
                      child: Column(
                        children: [
                          // Main Logo Container
                          // Logo container with Figma-style design
                          Container(
                            // Container dimensions
                            width: 100,
                            height: 100,
                            // Container decoration with shadows
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // Rounded corners
                              borderRadius: BorderRadius.circular(25),
                              // Multiple shadows for depth
                              boxShadow: [
                                BoxShadow(
                                  // Dark shadow for depth
                                  color: Colors.black.withOpacity(0.1),
                                  // Blur radius for soft shadow
                                  blurRadius: 20,
                                  // No spread radius
                                  spreadRadius: 0,
                                  // Offset for shadow position
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  // Light shadow for highlight
                                  color: Colors.white.withOpacity(0.9),
                                  // Blur radius for soft shadow
                                  blurRadius: 20,
                                  // Spread radius for shadow size
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            // Casino dice icon
                            child: Icon(
                              Icons.casino,
                              size: 50,
                              // Use gradient color for icon
                              color: gradientColors[1],
                            ),
                          ),

                          // Spacing between logo and title
                          const SizedBox(height: 30),

                          // App Title
                          // App title text with Figma-style typography
                          const Text(
                            'WagerLoop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              // Letter spacing for stylistic effect
                              letterSpacing: 1.2,
                              // Text shadow for depth
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),

                          // Spacing between title and subtitle
                          const SizedBox(height: 8),

                          // Subtitle
                          // Subtitle text with light styling
                          Text(
                            'Sports Betting Reimagined',
                            style: TextStyle(
                              // Semi-transparent white
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              // Letter spacing for stylistic effect
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle spacer with flex of 2
                    const Spacer(flex: 2),

                    // Bouncing Balls Animation
                    // Container for bouncing balls with fixed height
                    SizedBox(
                      height: 120,
                      // Animated builder for bouncing balls
                      child: AnimatedBuilder(
                        // Listen to bounce controller and all ball controllers
                        animation: Listenable.merge([_bounceController, ..._ballControllers]),
                        // Builder function for animated balls
                        builder: (context, child) {
                          // Row to arrange balls horizontally
                          return Row(
                            // Center the balls horizontally
                            mainAxisAlignment: MainAxisAlignment.center,
                            // Align balls to bottom of container
                            crossAxisAlignment: CrossAxisAlignment.end,
                            // Generate 7 bouncing balls
                            children: List.generate(7, (index) {
                              // Get animation controller for current ball
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

                              // Transform translate for bouncing effect
                              return Transform.translate(
                                // Vertical offset based on calculated bounce height
                                offset: Offset(0, -bounceHeight),
                                // Transform scale for size animation
                                child: Transform.scale(
                                  // Scale based on animation value
                                  scale: scale,
                                  // Ball container
                                  child: Container(
                                    // Horizontal margin between balls
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    // Ball dimensions
                                    width: 16,
                                    height: 16,
                                    // Ball decoration with color and shadows
                                    decoration: BoxDecoration(
                                      // Ball color from colors array
                                      color: ballColors[index],
                                      // Circular border radius
                                      borderRadius: BorderRadius.circular(8),
                                      // Multiple shadows for depth
                                      boxShadow: [
                                        BoxShadow(
                                          // Colored shadow matching ball color
                                          color: ballColors[index].withOpacity(0.4),
                                          // Blur radius for soft shadow
                                          blurRadius: 8,
                                          // Spread radius for shadow size
                                          spreadRadius: 1,
                                          // Offset for shadow position
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          // Light highlight shadow
                                          color: Colors.white.withOpacity(0.3),
                                          // Smaller blur radius
                                          blurRadius: 4,
                                          // No spread radius
                                          spreadRadius: 0,
                                          // Offset for highlight effect
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

                    // Spacing between balls and loading text
                    const SizedBox(height: 40),

                    // Loading Text with Pulse Effect
                    // Animated builder for pulsing loading text
                    AnimatedBuilder(
                      // Listen to bounce animation controller
                      animation: _bounceController,
                      // Builder function for animated text
                      builder: (context, child) {
                        // Calculate pulse scale based on animation value
                        final pulse = 0.8 + (0.2 * math.sin(_bounceController.value * 2 * math.pi));
                        // Transform scale for pulsing effect
                        return Transform.scale(
                          // Scale based on calculated pulse value
                          scale: pulse,
                          // Loading text
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              // Semi-transparent white
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              // Letter spacing for stylistic effect
                              letterSpacing: 3,
                            ),
                          ),
                        );
                      },
                    ),

                    // Bottom spacer
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
