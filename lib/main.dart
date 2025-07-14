import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'wrappers/auth_wrapper.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/splash_screen.dart';
import 'pages/bouncy_splash_screen.dart';
import 'pages/dice_bouncy_splash_screen.dart';
import 'pages/figma_bouncy_loader.dart';
import 'pages/figma_ball_splash.dart';
import 'layouts/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supaBaseURL,
    anonKey: SupabaseConfig.supaBaseAnonKey,
    authFlowType: AuthFlowType.pkce,
  );

  runApp(
    DevicePreview(
      enabled: !const bool.fromEnvironment('dart.vm.product'),
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Sports App',
      theme: ThemeData.light().copyWith(
        platform: Theme.of(context).platform,
        scaffoldBackgroundColor: Colors.grey[800], // Changed to gray background
        primaryColor: Colors.green,
        colorScheme: ColorScheme.light(
          primary: Colors.green,
          secondary: Colors.greenAccent,
          surface: Colors.white,
          background: Colors.grey[800],
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.green,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[700], // Dark gray card background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[800], // Changed to gray
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.grey[800], // Changed to gray
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey[700], // Dark gray background
          selectedColor: Colors.green, // Green when selected
          labelStyle: const TextStyle(color: Colors.green), // Green text for unselected
          secondaryLabelStyle: const TextStyle(color: Colors.white), // White text when selected
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      initialRoute: '/', // Start with AuthWrapper to check authentication state
      routes: {
        '/splash': (context) => const FigmaBallSplash(), // Exact Figma recreation: bouncing ball → blue fill → text
        '/': (context) => const AuthWrapper(),
        '/auth/login': (context) => const LoginPage(),
        '/auth/register': (context) => const RegisterPage(),
        '/auth/onboarding': (context) => OnboardingPage(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}
