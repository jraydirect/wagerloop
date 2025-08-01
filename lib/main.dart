import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
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
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView platform for web - must be done before any WebView widgets
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }

  // Suppress Google Sign-In library errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Suppress "Future already completed" errors from Google Sign-In
    if (details.exception.toString().contains('Future already completed') &&
        details.stack.toString().contains('google_sign_in')) {
      return;
    }
    // Let other errors through
    FlutterError.presentError(details);
  };

  // Load environment variables - handle missing .env file gracefully
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found. Some features may not work without API keys.');
  }

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL') ?? SupabaseConfig.supaBaseURL,
    anonKey: dotenv.get('SUPABASE_ANON_KEY') ?? SupabaseConfig.supaBaseAnonKey,
    authFlowType: AuthFlowType.pkce,
    debug: false, // Reduce Supabase logging in production
  );

  runApp(
    DevicePreview(
      enabled: kIsWeb && !const bool.fromEnvironment('dart.vm.product'),
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
