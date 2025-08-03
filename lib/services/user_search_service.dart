import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for searching and managing user profiles in WagerLoop.
/// 
/// Provides functionality to search for users by username, get user details,
/// and manage user discovery features for the social aspects of the app.
class UserSearchService {
  final SupabaseClient _supabase;

  UserSearchService(this._supabase);

  /// Searches for users by username with fuzzy matching.
  /// 
  /// Performs a case-insensitive search across usernames to help users
  /// find and connect with other WagerLoop users for following and
  /// social interactions.
  /// 
  /// Parameters:
  ///   - query: The search term to match against usernames
  ///   - limit: Maximum number of results to return (default: 20)
  /// 
  /// Returns:
  ///   List<Map<String, dynamic>> containing user profile data
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      // Don't search for empty queries
      if (query.trim().isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url, bio')
          .ilike('username', '%${query.trim()}%')
          .order('username')
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Gets detailed profile information for a specific user.
  /// 
  /// Retrieves complete profile data for displaying user information
  /// in search results and profile previews.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user to retrieve
  /// 
  /// Returns:
  ///   Map<String, dynamic>? containing user profile data or null if not found
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url, bio, created_at')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Gets a list of suggested users for discovery.
  /// 
  /// Returns a list of popular or recently active users to help with
  /// user discovery when no specific search is performed.
  /// 
  /// Parameters:
  ///   - limit: Maximum number of suggestions to return (default: 10)
  /// 
  /// Returns:
  ///   List<Map<String, dynamic>> containing suggested user profiles
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<Map<String, dynamic>>> getSuggestedUsers({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, avatar_url, bio')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting suggested users: $e');
      throw Exception('Failed to get suggested users: $e');
    }
  }
}