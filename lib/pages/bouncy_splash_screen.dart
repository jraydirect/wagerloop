import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BouncySplashScreen extends StatefulWidget {
  const BouncySplashScreen({super.key});

  @override
  State<BouncySplashScreen> createState() => _BouncySplashScreenState();
}

class _BouncySplashScreenState extends State<BouncySplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late List<AnimationController> _ballControllers;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create controllers for bouncing balls
    _ballControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(milliseconds: 800 + (index * 100)),
        vsync: this,
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Start main animation
    _mainController.forward();

    // Start bouncing balls with delays
    for (int i = 0; i < _ballControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 150));
      if (mounted) {
        _ballControllers[i].repeat(reverse: true);
      }
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
    for (var controller in _ballControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f0f),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // App Logo/Title Animation
              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                          parent: _mainController,
                          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
                        ))
                        .value,
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.casino,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'WagerLoop',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              // Bouncing Balls Animation
              AnimatedBuilder(
                animation: Listenable.merge(_ballControllers),
                builder: (context, child) {
                  return SizedBox(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(5, (index) {
                        final controller = _ballControllers[index];
                        final colors = [
                          Colors.blue,
                          Colors.cyan,
                          Colors.green,
                          Colors.yellow,
                          Colors.orange,
                        ];

                        return Transform.translate(
                          offset: Offset(
                            0,
                            -40 * Curves.bounceOut.transform(controller.value),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[index],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[index].withOpacity(0.3),
                                  blurRadius: 8,
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

              const SizedBox(height: 40),

              // Loading text with fade animation
              AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Opacity(
                    opacity: Tween<double>(begin: 0.0, end: 1.0)
                        .animate(CurvedAnimation(
                          parent: _mainController,
                          curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                        ))
                        .value,
                    child: Text(
                      'Loading the action...',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
