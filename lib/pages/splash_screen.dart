// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import flutter_animate package for advanced animations
import 'package:flutter_animate/flutter_animate.dart';
// Import custom dice loading widget
import '../widgets/dice_loading_widget.dart';

// SplashScreen class definition - a stateful widget for animated splash screen
class SplashScreen extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const SplashScreen({super.key});

  // Override createState method to return the state class instance
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Private state class that manages the splash screen's state and animations
class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controller for bouncing animations
  late AnimationController _bounceController;
  // Animation controller for fade in/out animations
  late AnimationController _fadeController;
  // Animation controller for scaling animations
  late AnimationController _scaleController;

  // Override initState to initialize the widget state and animations
  @override
  void initState() {
    // Call parent initState
    super.initState();

    // Initialize bounce animation controller with 1.2 second duration
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize fade animation controller with 0.8 second duration
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize scale animation controller with 0.6 second duration
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start the splash screen animation sequence
    _startAnimation();
  }

  // Async method to orchestrate the splash screen animation sequence
  void _startAnimation() async {
    // Start the bounce animation
    _bounceController.repeat(reverse: true);
    
    // Fade in the content
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    // Scale animation for logo
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    // Navigate after splash duration
    await Future.delayed(const Duration(seconds: 3));
    // Navigate to home page if widget is still mounted
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose bounce animation controller
    _bounceController.dispose();
    // Dispose fade animation controller
    _fadeController.dispose();
    // Dispose scale animation controller
    _scaleController.dispose();
    // Call parent dispose
    super.dispose();
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with animated splash screen content
    return Scaffold(
      // Set black background color
      backgroundColor: Colors.black,
      // Container body with gradient background
      body: Container(
        // Set radial gradient background decoration
        decoration: BoxDecoration(
          gradient: RadialGradient(
            // Center the gradient
            center: Alignment.center,
            // Gradient radius
            radius: 1.0,
            // Gradient colors from blue to black
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
            // Color stops for gradient transition
            stops: const [0.0, 0.7, 1.0],
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
              
              // Animated Logo Section
              // Fade transition for logo section
              FadeTransition(
                // Use fade controller for opacity animation
                opacity: _fadeController,
                // Scale transition for logo section
                child: ScaleTransition(
                  // Scale from 0.8 to 1.0 with elastic animation
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  // Column containing logo and text
                  child: Column(
                    children: [
                      // App Icon with bounce
                      // Animated builder for bouncing logo
                      AnimatedBuilder(
                        // Listen to bounce animation controller
                        animation: _bounceController,
                        // Builder function for animated logo
                        builder: (context, child) {
                          // Transform translate for bouncing effect
                          return Transform.translate(
                            // Vertical offset based on animation value
                            offset: Offset(
                              0,
                              // Vertical bounce with 20px amplitude
                              -20 * Curves.elasticInOut.transform(_bounceController.value),
                            ),
                            // Logo container
                            child: Container(
                              // Container dimensions
                              width: 120,
                              height: 120,
                              // Container decoration with rounded corners and shadow
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    // Blue shadow with opacity
                                    color: Colors.blue.withOpacity(0.3),
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
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Spacing between logo and app name
                      const SizedBox(height: 30),
                      
                      // App Name
                      // App name text with animation
                      const Text(
                        'WagerLoop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          // Letter spacing for stylistic effect
                          letterSpacing: 2,
                        ),
                      )
                          // Animate with fade in and slide animation
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 800.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      // Spacing between app name and tagline
                      const SizedBox(height: 8),
                      
                      // Tagline
                      // Tagline text with animation
                      Text(
                        'Sports • Bets • Community',
                        style: TextStyle(
                          // Light grey text color
                          color: Colors.grey[400],
                          fontSize: 16,
                          // Letter spacing for stylistic effect
                          letterSpacing: 1,
                        ),
                      )
                          // Animate with fade in and slide animation
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 800.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
              
              // Middle spacer with flex of 2
              const Spacer(flex: 2),
              
              // Loading Animation
              // Fade transition for loading section
              FadeTransition(
                // Use fade controller for opacity animation
                opacity: _fadeController,
                // Column containing loading elements
                child: Column(
                  children: [
                    // Dice loading with custom message
                    // Dice loading widget with animation
                    const DiceLoadingWidget(
                      // Loading message
                      message: 'Loading the action...',
                      // Loading widget size
                      size: 60,
                      // Show message flag
                      showMessage: true,
                    )
                        // Animate with fade in
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 800.ms),
                    
                    // Spacing between loading widget and dots
                    const SizedBox(height: 40),
                    
                    // Animated dots
                    // Row containing animated dots
                    Row(
                      // Center the dots horizontally
                      mainAxisAlignment: MainAxisAlignment.center,
                      // Generate 3 animated dots
                      children: List.generate(3, (index) {
                        // Container for each dot
                        return Container(
                          // Horizontal margin between dots
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          // Animated builder for dot animation
                          child: AnimatedBuilder(
                            // Listen to bounce animation controller
                            animation: _bounceController,
                            // Builder function for animated dot
                            builder: (context, child) {
                              // Calculate delay for each dot
                              final delay = index * 0.2;
                              // Calculate animation value with delay
                              final animationValue = (_bounceController.value + delay) % 1.0;
                              // Transform scale for dot animation
                              return Transform.scale(
                                // Scale from 0.5 to 1.0 based on animation value
                                scale: 0.5 + (0.5 * Curves.easeInOut.transform(animationValue)),
                                // Dot container
                                child: Container(
                                  // Dot dimensions
                                  width: 8,
                                  height: 8,
                                  // Dot decoration
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    // Circular border radius
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    )
                        // Animate with fade in
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms),
                  ],
                ),
              ),
              
              // Bottom spacer
              const Spacer(),
              
              // Bottom text
              // Fade transition for bottom text
              FadeTransition(
                // Use fade controller for opacity animation
                opacity: _fadeController,
                // Padded bottom text
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  // Bottom text with animation
                  child: Text(
                    'Get ready to win!',
                    style: TextStyle(
                      // Light grey text color
                      color: Colors.grey[600],
                      fontSize: 14,
                      // Light font weight
                      fontWeight: FontWeight.w300,
                    ),
                  )
                      // Animate with fade in and slide animation
                      .animate()
                      .fadeIn(delay: 1400.ms, duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
