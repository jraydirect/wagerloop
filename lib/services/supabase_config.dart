// lib/services/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for database and authentication functionality
import 'social_feed_service.dart'; // Import local social feed service for managing social media features

class SupabaseConfig { // Define SupabaseConfig class to manage Supabase configuration and initialization
  static const String supaBaseURL = 'https://lbkvlemiuhosfrizrwcz.supabase.co'; // Define the Supabase project URL as a constant string
  static const String supaBaseAnonKey = // Define the Supabase anonymous key as a constant string
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxia3ZsZW1pdWhvc2ZyaXpyd2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzNzQzOTEsImV4cCI6MjA2Nzk1MDM5MX0.pJdkvUxY7QscGDywHz81rxgrAEIISSjZuxWO6_M8fsc'; // JWT token for anonymous authentication with Supabase

  static final socialFeedService = SocialFeedService(supabase); // Create a static instance of SocialFeedService using the supabase client

  static final supabase = Supabase.instance.client; // Create a static reference to the Supabase client instance

  static Future<void> initialize() async { // Define an async static method to initialize Supabase
    await Supabase.initialize( // Initialize the Supabase client with configuration
      url: supaBaseURL, // Set the Supabase project URL
      anonKey: supaBaseAnonKey, // Set the anonymous authentication key
    ); // End of Supabase initialization
  } // End of initialize method
} // End of SupabaseConfig class
