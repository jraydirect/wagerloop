// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import flutter_animate package for advanced animations
import 'package:flutter_animate/flutter_animate.dart';

// DiceBouncySplashScreen class definition - a stateful widget for animated dice-themed splash screen
class DiceBouncySplashScreen extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const DiceBouncySplashScreen({super.key});

  // Override createState method to return the state class instance
  @override
  State<DiceBouncySplashScreen> createState() => _DiceBouncySplashScreenState();
}

// Private state class that manages the dice splash screen's state and animations
class _DiceBouncySplashScreenState extends State<DiceBouncySplashScreen>
    with TickerProviderStateMixin {
  // Animation controller for dice rotation animation
  late AnimationController _diceController;
  // Animation controller for bouncing animations
  late AnimationController _bounceController;
  // Animation controller for fade in/out animations
  late AnimationController _fadeController;

  // Override initState to initialize the widget state and animations
  @override
  void initState() {
    // Call parent initState
    super.initState();

    // Initialize dice animation controller with 1.5 second duration
    _diceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize bounce animation controller with 1 second duration
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize fade animation controller with 0.8 second duration
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start the splash screen animation sequence
    _startAnimation();
  }

  // Async method to orchestrate the splash screen animation sequence
  void _startAnimation() async {
    // Start fade in
    _fadeController.forward();
    
    // Start dice rotation
    await Future.delayed(const Duration(milliseconds: 300));
    _diceController.repeat();
    
    // Start bounce animation
    await Future.delayed(const Duration(milliseconds: 200));
    _bounceController.repeat(reverse: true);
    
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
    // Dispose dice animation controller
    _diceController.dispose();
    // Dispose bounce animation controller
    _bounceController.dispose();
    // Dispose fade animation controller
    _fadeController.dispose();
    // Call parent dispose
    super.dispose();
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with animated dice splash screen content
    return Scaffold(
      // Container body with gradient background
      body: Container(
        // Set radial gradient background decoration
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            // Center the gradient
            center: Alignment.center,
            // Gradient radius
            radius: 1.2,
            // Blue gradient colors for dice theme
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
              Color(0xFF0f0f0f),
            ],
          ),
        ),
        // Fade transition for entire content
        child: FadeTransition(
          // Use fade controller for opacity animation
          opacity: _fadeController,
          // Safe area to avoid system UI overlaps
          child: SafeArea(
            // Column to arrange splash screen elements vertically
            child: Column(
              // Center the column contents
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top spacer with flex of 2
                const Spacer(flex: 2),

                // Animated Dice Logo
                // Animated builder for dice with rotation and bouncing
                AnimatedBuilder(
                  // Listen to both dice and bounce animation controllers
                  animation: Listenable.merge([_diceController, _bounceController]),
                  // Builder function for animated dice
                  builder: (context, child) {
                    // Transform translate for bouncing effect
                    return Transform.translate(
                      // Vertical offset based on bounce animation value
                      offset: Offset(
                        0,
                        // Vertical bounce with 15px amplitude
                        -15 * Curves.easeInOut.transform(_bounceController.value),
                      ),
                      // Transform rotate for dice rotation
                      child: Transform.rotate(
                        // Rotation angle based on dice animation value
                        angle: _diceController.value * 2 * 3.14159,
                        // Dice container
                        child: Container(
                          // Container dimensions
                          width: 120,
                          height: 120,
                          // Container decoration with gradient and shadow
                          decoration: BoxDecoration(
                            // Blue gradient for dice appearance
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                                Colors.blue.shade800,
                              ],
                            ),
                            // Rounded corners for dice
                            borderRadius: BorderRadius.circular(25),
                            // Shadow effects for depth
                            boxShadow: [
                              BoxShadow(
                                // Blue shadow with opacity
                                color: Colors.blue.withOpacity(0.4),
                                // Blur radius for soft shadow
                                blurRadius: 30,
                                // Spread radius for shadow size
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                // White highlight shadow
                                color: Colors.white.withOpacity(0.1),
                                // Smaller blur radius
                                blurRadius: 5,
                                // Smaller spread radius
                                spreadRadius: 1,
                                // Offset for highlight effect
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          // Stack for positioning dice dots
                          child: Stack(
                            children: [
                              // Dice dots
                              // Top left dot
                              Positioned(
                                top: 15,
                                left: 15,
                                child: _buildDiceDot(),
                              ),
                              // Top right dot
                              Positioned(
                                top: 15,
                                right: 15,
                                child: _buildDiceDot(),
                              ),
                              // Bottom left dot
                              Positioned(
                                bottom: 15,
                                left: 15,
                                child: _buildDiceDot(),
                              ),
                              // Bottom right dot
                              Positioned(
                                bottom: 15,
                                right: 15,
                                child: _buildDiceDot(),
                              ),
                              // Center dot
                              Center(
                                child: _buildDiceDot(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Spacing between dice and title
                const SizedBox(height: 40),

                // App Title with shimmer effect
                // App title text with shimmer animation
                const Text(
                  'WagerLoop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    // Letter spacing for stylistic effect
                    letterSpacing: 3,
                  ),
                )
                    // Animate with shimmer effect
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.blue.shade300)
                    .then()
                    .fadeIn(duration: 800.ms),

                // Spacing between title and subtitle
                const SizedBox(height: 8),

                // Subtitle text with animation
                Text(
                  'Roll the dice on sports',
                  style: TextStyle(
                    // Light grey text color
                    color: Colors.grey[300],
                    fontSize: 16,
                    // Letter spacing for stylistic effect
                    letterSpacing: 1,
                  ),
                )
                    // Animate with fade in and slide effect
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                // Middle spacer with flex of 2
                const Spacer(flex: 2),

                // Bouncing dots loader
                // Animated builder for bouncing dots
                AnimatedBuilder(
                  // Listen to bounce animation controller
                  animation: _bounceController,
                  // Builder function for animated dots
                  builder: (context, child) {
                    // Row to arrange dots horizontally
                    return Row(
                      // Center the dots horizontally
                      mainAxisAlignment: MainAxisAlignment.center,
                      // Generate 4 bouncing dots
                      children: List.generate(4, (index) {
                        // Calculate delay for each dot
                        final delay = index * 0.15;
                        // Calculate animation value with delay
                        final animationValue = 
                            ((_bounceController.value + delay) % 1.0);
                        
                        // Transform translate for bouncing effect
                        return Transform.translate(
                          // Vertical offset based on animation value
                          offset: Offset(
                            0,
                            // Vertical bounce with 20px amplitude
                            -20 * Curves.bounceOut.transform(animationValue),
                          ),
                          // Dot container
                          child: Container(
                            // Horizontal margin between dots
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            // Dot dimensions
                            width: 12,
                            height: 12,
                            // Dot decoration
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // Circular border radius
                              borderRadius: BorderRadius.circular(6),
                              // Shadow for depth effect
                              boxShadow: [
                                BoxShadow(
                                  // White shadow with opacity
                                  color: Colors.white.withOpacity(0.3),
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
                    );
                  },
                ),

                // Spacing between dots and loading text
                const SizedBox(height: 30),

                // Loading text with animation
                Text(
                  'Loading...',
                  style: TextStyle(
                    // Light grey text color
                    color: Colors.grey[400],
                    fontSize: 14,
                    // Light font weight
                    fontWeight: FontWeight.w300,
                  ),
                )
                    // Animate with fade in
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 800.ms),

                // Bottom spacer
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to build a dice dot widget
  Widget _buildDiceDot() {
    // Return container representing a dice dot
    return Container(
      // Dot dimensions
      width: 8,
      height: 8,
      // Dot decoration with shadow
      decoration: BoxDecoration(
        color: Colors.white,
        // Circular border radius
        borderRadius: BorderRadius.circular(4),
        // Shadow for depth effect
        boxShadow: [
          BoxShadow(
            // Black shadow with opacity
            color: Colors.black.withOpacity(0.3),
            // Blur radius for soft shadow
            blurRadius: 2,
            // Offset for shadow position
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}
