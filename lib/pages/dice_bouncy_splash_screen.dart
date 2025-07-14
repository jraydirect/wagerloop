import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DiceBouncySplashScreen extends StatefulWidget {
  const DiceBouncySplashScreen({super.key});

  @override
  State<DiceBouncySplashScreen> createState() => _DiceBouncySplashScreenState();
}

class _DiceBouncySplashScreenState extends State<DiceBouncySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _diceController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _diceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startAnimation();
  }

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
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _diceController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
              Color(0xFF0f0f0f),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeController,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Dice Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_diceController, _bounceController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        -15 * Curves.easeInOut.transform(_bounceController.value),
                      ),
                      child: Transform.rotate(
                        angle: _diceController.value * 2 * 3.14159,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                                Colors.blue.shade800,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Dice dots
                              Positioned(
                                top: 15,
                                left: 15,
                                child: _buildDiceDot(),
                              ),
                              Positioned(
                                top: 15,
                                right: 15,
                                child: _buildDiceDot(),
                              ),
                              Positioned(
                                bottom: 15,
                                left: 15,
                                child: _buildDiceDot(),
                              ),
                              Positioned(
                                bottom: 15,
                                right: 15,
                                child: _buildDiceDot(),
                              ),
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

                const SizedBox(height: 40),

                // App Title with shimmer effect
                const Text(
                  'WagerLoop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.blue.shade300)
                    .then()
                    .fadeIn(duration: 800.ms),

                const SizedBox(height: 8),

                Text(
                  'Roll the dice on sports',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const Spacer(flex: 2),

                // Bouncing dots loader
                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final delay = index * 0.15;
                        final animationValue = 
                            ((_bounceController.value + delay) % 1.0);
                        
                        return Transform.translate(
                          offset: Offset(
                            0,
                            -20 * Curves.bounceOut.transform(animationValue),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
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

                const SizedBox(height: 30),

                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 800.ms),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}
