// lib/services/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'social_feed_service.dart';

class SupabaseConfig {
  static const String supaBaseURL = 'https://lbkvlemiuhosfrizrwcz.supabase.co';
  static const String supaBaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxia3ZsZW1pdWhvc2ZyaXpyd2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzNzQzOTEsImV4cCI6MjA2Nzk1MDM5MX0.pJdkvUxY7QscGDywHz81rxgrAEIISSjZuxWO6_M8fsc';

  static final socialFeedService = SocialFeedService(supabase);

  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supaBaseURL,
      anonKey: supaBaseAnonKey,
    );
  }
}
