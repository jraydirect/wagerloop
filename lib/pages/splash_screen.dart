import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/dice_loading_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _startAnimation();
  }

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
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Logo Section
              FadeTransition(
                opacity: _fadeController,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Column(
                    children: [
                      // App Icon with bounce
                      AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              -20 * Curves.elasticInOut.transform(_bounceController.value),
                            ),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.casino,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // App Name
                      const Text(
                        'WagerLoop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 800.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      // Tagline
                      Text(
                        'Sports • Bets • Community',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 800.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Loading Animation
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    // Dice loading with custom message
                    const DiceLoadingWidget(
                      message: 'Loading the action...',
                      size: 60,
                      showMessage: true,
                    )
                        .animate()
                        .fadeIn(delay: 1000.ms, duration: 800.ms),
                    
                    const SizedBox(height: 40),
                    
                    // Animated dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedBuilder(
                            animation: _bounceController,
                            builder: (context, child) {
                              final delay = index * 0.2;
                              final animationValue = (_bounceController.value + delay) % 1.0;
                              return Transform.scale(
                                scale: 0.5 + (0.5 * Curves.easeInOut.transform(animationValue)),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    )
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Bottom text
              FadeTransition(
                opacity: _fadeController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Get ready to win!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  )
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
