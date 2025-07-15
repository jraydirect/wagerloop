import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/onboarding_page.dart';
import '../pages/figma_ball_splash.dart';
import '../layouts/main_layout.dart';
import '../widgets/dice_loading_widget.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Handle stream errors
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Authentication Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check current session
        final session = _authService.currentSession;

        // If no session, show splash screen for first-time experience
        if (session == null) {
          return const FigmaBallSplash();
        }

        // For authenticated users, check onboarding status
        return FutureBuilder<Map<String, dynamic>?>(
          future: _authService.getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: DiceLoadingWidget(
                  message: 'Setting up your profile...',
                  size: 100,
                ),
              );
            }

            final hasCompletedOnboarding =
                profileSnapshot.data?['has_completed_onboarding'] ?? false;

            if (!hasCompletedOnboarding) {
              return const OnboardingPage();
            }

            // User is authenticated and has completed onboarding
            final user = _authService.currentUser;
            if (user != null) {
              print('✅ Login successful: ${user.email}');
            }
            return const MainLayout();
          },
        );
      },
    );
  }
}
