// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import flutter_animate package for advanced animations
import 'package:flutter_animate/flutter_animate.dart';

// BouncySplashScreen class definition - a stateful widget for animated splash screen
class BouncySplashScreen extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const BouncySplashScreen({super.key});

  // Override createState method to return the state class instance
  @override
  State<BouncySplashScreen> createState() => _BouncySplashScreenState();
}

// Private state class that manages the splash screen's state and animations
class _BouncySplashScreenState extends State<BouncySplashScreen>
    with TickerProviderStateMixin {
  // Main animation controller for logo and text animations
  late AnimationController _mainController;
  // List of animation controllers for bouncing ball animations
  late List<AnimationController> _ballControllers;

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

    // Create controllers for bouncing balls
    _ballControllers = List.generate(
      5, // Create 5 ball controllers
      (index) => AnimationController(
        // Each ball has slightly different duration for varied timing
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    // Start the splash screen animation sequence
    _startAnimation();
  }

  // Async method to orchestrate the splash screen animation sequence
  void _startAnimation() async {
    // Start main animation
    _mainController.forward();

    // Start bouncing balls with delays
    for (int i = 0; i < _ballControllers.length; i++) {
      // Delay each ball animation by 150ms * index
      await Future.delayed(Duration(milliseconds: i * 150));
      // Start ball animation if widget is still mounted
      if (mounted) {
        // Repeat animation in reverse for bouncing effect
        _ballControllers[i].repeat(reverse: true);
      }
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
    // Return scaffold with animated splash screen content
    return Scaffold(
      // Container body with gradient background
      body: Container(
        // Set gradient background decoration
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Gradient from top-left to bottom-right
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Dark gradient colors for modern look
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f0f),
            ],
          ),
        ),
        // Safe area to avoid system UI overlaps
        child: SafeArea(
          // Column to arrange splash screen elements vertically
          child: Column(
            // Center the column contents
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top spacer with flex of 2
              const Spacer(flex: 2),

              // App Logo/Title Animation
              // Animated builder for main logo and title
              AnimatedBuilder(
                // Listen to main animation controller
                animation: _mainController,
                // Builder function for animated content
                builder: (context, child) {
                  // Transform scale based on animation value
                  return Transform.scale(
                    // Scale from 0 to 1 with elastic animation
                    scale: Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                          parent: _mainController,
                          // Animate from 0% to 60% of main animation
                          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
                        ))
                        .value,
                    // Logo and title column
                    child: Column(
                      children: [
                        // Logo container
                        Container(
                          // Container dimensions
                          width: 100,
                          height: 100,
                          // Container decoration with rounded corners and shadow
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                // Blue shadow with opacity
                                color: Colors.blue.withOpacity(0.4),
                                // Blur radius for soft shadow
                                blurRadius: 20,
                                // Spread radius for shadow size
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          // Casino dice icon in center
                          child: const Icon(
                            Icons.casino,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        // Spacing between logo and title
                        const SizedBox(height: 20),
                        // App title text
                        const Text(
                          'WagerLoop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            // Letter spacing for stylistic effect
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Middle spacer
              const Spacer(),

              // Bouncing Balls Animation
              // Animated builder for bouncing balls
              AnimatedBuilder(
                // Listen to all ball animation controllers
                animation: Listenable.merge(_ballControllers),
                // Builder function for animated balls
                builder: (context, child) {
                  // Container with fixed height for bouncing area
                  return SizedBox(
                    height: 80,
                    // Row to arrange balls horizontally
                    child: Row(
                      // Center the balls horizontally
                      mainAxisAlignment: MainAxisAlignment.center,
                      // Align balls to bottom of container
                      crossAxisAlignment: CrossAxisAlignment.end,
                      // Generate 5 bouncing balls
                      children: List.generate(5, (index) {
                        // Get animation controller for current ball
                        final controller = _ballControllers[index];
                        // Array of colors for each ball
                        final colors = [
                          Colors.blue,
                          Colors.cyan,
                          Colors.green,
                          Colors.yellow,
                          Colors.orange,
                        ];

                        // Transform translate for bouncing effect
                        return Transform.translate(
                          // Vertical offset based on animation value
                          offset: Offset(
                            0, // No horizontal offset
                            // Vertical bounce with 40px amplitude
                            -40 * Curves.bounceOut.transform(controller.value),
                          ),
                          // Ball container
                          child: Container(
                            // Horizontal margin between balls
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            // Ball dimensions
                            width: 16,
                            height: 16,
                            // Ball decoration with color and shadow
                            decoration: BoxDecoration(
                              // Ball color from colors array
                              color: colors[index],
                              // Circular border radius
                              borderRadius: BorderRadius.circular(8),
                              // Shadow for depth effect
                              boxShadow: [
                                BoxShadow(
                                  // Shadow color with opacity
                                  color: colors[index].withOpacity(0.3),
                                  // Blur radius for soft shadow
                                  blurRadius: 8,
                                  // Spread radius for shadow size
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),

              // Spacing after bouncing balls
              const SizedBox(height: 40),

              // Loading text with fade animation
              // Animated builder for loading text
              AnimatedBuilder(
                // Listen to main animation controller
                animation: _mainController,
                // Builder function for animated text
                builder: (context, child) {
                  // Opacity widget for fade effect
                  return Opacity(
                    // Opacity from 0 to 1 with delayed animation
                    opacity: Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                          parent: _mainController,
                          // Animate from 70% to 100% of main animation
                          curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                        ))
                        .value,
                    // Loading text
                    child: Text(
                      'Loading the action...',
                      style: TextStyle(
                        // Light grey text color
                        color: Colors.grey[400],
                        fontSize: 16,
                        // Light font weight
                        fontWeight: FontWeight.w300,
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
      ),
    );
  }
}
