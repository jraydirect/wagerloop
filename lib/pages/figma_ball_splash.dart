import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import '../services/auth_service.dart';

class FigmaBallSplash extends StatefulWidget {
  const FigmaBallSplash({super.key});

  @override
  State<FigmaBallSplash> createState() => _FigmaBallSplashState();
}

class _FigmaBallSplashState extends State<FigmaBallSplash>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _fillController;
  late AnimationController _textController;
  late AnimationController _loginController;
  late AnimationController _typewriterController;
  
  late Animation<double> _ballBounce;
  late Animation<double> _ballOpacity;
  late Animation<double> _fillRadius;
  late Animation<double> _textFade;
  late Animation<double> _textScale;
  late Animation<double> _logoSlideUp;
  late Animation<double> _loginSlideUp;
  late Animation<int> _typewriterAnimation;

  bool _showText = false;
  bool _showLogin = false;
  bool _showCursor = true;
  Timer? _cursorTimer;
  
  @override
  void initState() {
    super.initState();

    // Ball bouncing animation (3 bounces, decreasing height)
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Screen fill animation - SMOOTHER
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Text reveal animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Login reveal animation
    _loginController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Typewriter effect for subtitle
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2 seconds to type
      vsync: this,
    );

    // Ball bounce physics (3 bounces with decreasing amplitude)
    _ballBounce = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.bounceOut),
    );

    _ballOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _fillController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // SMOOTHER screen fill - using radius instead of scale
    _fillRadius = Tween<double>(begin: 25, end: 1000).animate(
      CurvedAnimation(parent: _fillController, curve: Curves.easeOutQuart),
    );

    // Text animations
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _textScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.9, curve: Curves.elasticOut),
      ),
    );

    // Logo stays in place (no slide up animation needed)
    _logoSlideUp = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _loginController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Login form slide up animation  
    _loginSlideUp = Tween<double>(begin: 300, end: 0).animate(
      CurvedAnimation(
        parent: _loginController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Typewriter animation - animates from 0 to string length
    const subtitle = 'keep your wager in the loop';
    _typewriterAnimation = IntTween(
      begin: 0,
      end: subtitle.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startCursorBlinking() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _startAnimation() async {
    // Start ball bouncing
    await _ballController.forward();
    
    // Start screen fill on final bounce
    await Future.delayed(const Duration(milliseconds: 100));
    _fillController.forward();
    
    // Show text after fill completes
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showText = true);
    _textController.forward();
    
    // Start typewriter effect after logo appears
    await Future.delayed(const Duration(milliseconds: 800));
    _typewriterController.forward();
    
    // Start cursor blinking
    _startCursorBlinking();
    
    // Wait for typewriter to finish, then slide to login
    await Future.delayed(const Duration(milliseconds: 2500));
    setState(() => _showLogin = true);
    _loginController.forward();
  }

  @override
  void dispose() {
    _ballController.dispose();
    _fillController.dispose();
    _textController.dispose();
    _loginController.dispose();
    _typewriterController.dispose();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ballController, _fillController, _textController, _loginController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
              ),

              // SMOOTHER Blue fill animation
              if (_fillController.value > 0)
                AnimatedBuilder(
                  animation: _fillController,
                  builder: (context, child) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final screenWidth = MediaQuery.of(context).size.width;
                    final ballY = _getBallY(screenHeight);
                    
                    return Positioned(
                      left: screenWidth / 2 - _fillRadius.value,
                      top: ballY - _fillRadius.value,
                      child: Container(
                        width: _fillRadius.value * 2,
                        height: _fillRadius.value * 2,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),

              // Bouncing ball
              if (_ballOpacity.value > 0)
                AnimatedBuilder(
                  animation: _ballController,
                  builder: (context, child) {
                    final screenHeight = MediaQuery.of(context).size.height;
                    final screenWidth = MediaQuery.of(context).size.width;
                    
                    return Positioned(
                      left: screenWidth / 2 - 25,
                      top: _getBallY(screenHeight),
                      child: Opacity(
                        opacity: _ballOpacity.value,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Blue background (appears after fill)
              if (_showText)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.green,
                ),

              // Logo and text content (positioned above login form)
              if (_showText)
                Positioned(
                  top: 80, // Moved up from 140px to 80px
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: ScaleTransition(
                      scale: _textScale,
                      child: Column(
                        children: [
                          // WagerLoop logo image
                          Container(
                            height: 320, // Doubled from 160 to 320
                            width: 560, // Doubled from 280 to 560
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              // Removed shadow completely
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/ce71b5ba-35f9-4f31-aadf-2875b00dda9f_removalai_preview.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback text if image fails to load
                                  return Text(
                                    'WagerLoop',
                                    style: GoogleFonts.bowlbyOne(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Typewriter effect subtitle
                          AnimatedBuilder(
                            animation: _typewriterController,
                            builder: (context, child) {
                              const subtitle = 'keep your wager in the loop';
                              final visibleText = subtitle.substring(0, _typewriterAnimation.value);
                              final isTypingComplete = _typewriterAnimation.value >= subtitle.length;
                              
                              return Text(
                                '$visibleText${_showCursor ? '|' : ' '}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Login form (slides up from bottom)
              if (_showLogin)
                AnimatedBuilder(
                  animation: _loginController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _loginSlideUp.value),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.55, // Reduced from 58% to 55% to give more space
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: const LoginFormWidget(),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  double _getBallY(double screenHeight) {
    // Create a custom bounce pattern with 3 decreasing bounces
    double progress = _ballController.value;
    double baseY = screenHeight - 150; // Ground level
    
    if (progress <= 0.33) {
      // First bounce (highest)
      double bounceProgress = (progress / 0.33);
      double bounceHeight = 300 * math.sin(bounceProgress * math.pi);
      return baseY - bounceHeight;
    } else if (progress <= 0.66) {
      // Second bounce (medium)
      double bounceProgress = ((progress - 0.33) / 0.33);
      double bounceHeight = 200 * math.sin(bounceProgress * math.pi);
      return baseY - bounceHeight;
    } else {
      // Third bounce (smallest)
      double bounceProgress = ((progress - 0.66) / 0.34);
      double bounceHeight = 100 * math.sin(bounceProgress * math.pi);
      return baseY - bounceHeight;
    }
  }
}

class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({super.key});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _authService.signInWithGoogle();
      
      if (response.user != null && mounted) {
        // Navigate to auth wrapper to handle routing
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (response.user != null && mounted) {
        // Navigate to auth wrapper to handle routing
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8), // Further reduced padding
      child: SingleChildScrollView( // Make scrollable to prevent overflow
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12), // Further reduced spacing
            
            // Welcome Back text
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to continue',
              style: TextStyle(
                fontSize: 14, // Smaller
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // Further reduced spacing

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.green), // Changed to green
                hintStyle: const TextStyle(color: Colors.green), // Changed to green
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.green), // Changed icon to green
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your email';
                if (!value!.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 10), // Further reduced spacing

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.green), // Changed to green
                hintStyle: const TextStyle(color: Colors.green), // Changed to green
                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.green), // Changed icon to green
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.green, // Changed icon to green
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter your password';
                if (value!.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16), // Further reduced spacing

            // Sign in button
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 10), // Further reduced spacing

            // OR divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 10), // Further reduced spacing

            // Google Sign In button
            OutlinedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Further reduced spacing

            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/auth/register');
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Minimal bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
