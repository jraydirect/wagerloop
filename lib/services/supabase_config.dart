// Configuration file for Supabase backend services
// lib/services/supabase_config.dart
// Import Supabase Flutter SDK for backend operations
import 'package:supabase_flutter/supabase_flutter.dart';
// Import social feed service for social media functionality
import 'social_feed_service.dart';

// Class that contains all Supabase configuration and initialization
class SupabaseConfig {
  // Static constant for the Supabase project URL - points to the specific Supabase project instance
  static const String supaBaseURL = 'https://lbkvlemiuhosfrizrwcz.supabase.co';
  // Static constant for the Supabase anonymous key used for client-side operations - allows unauthenticated access to public data
  static const String supaBaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxia3ZsZW1pdWhvc2ZyaXpyd2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzNzQzOTEsImV4cCI6MjA2Nzk1MDM5MX0.pJdkvUxY7QscGDywHz81rxgrAEIISSjZuxWO6_M8fsc';

  // Static instance of social feed service for social media operations - provides methods for posts, likes, comments
  static final socialFeedService = SocialFeedService(supabase);

  // Static instance of Supabase client for database operations - main interface for all Supabase interactions
  static final supabase = Supabase.instance.client;

  // Static method to initialize Supabase with configuration - called during app startup
  static Future<void> initialize() async {
    // Initialize Supabase with URL and anonymous key - sets up the connection to the backend
    await Supabase.initialize(
      // Set the Supabase project URL - specifies which Supabase project to connect to
      url: supaBaseURL,
      // Set the anonymous key for client-side authentication - allows the app to make API calls
      anonKey: supaBaseAnonKey,
    );
  }
}
