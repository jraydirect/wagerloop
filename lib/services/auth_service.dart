import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'supabase_config.dart';

/// Manages user authentication and session handling for WagerLoop.
/// 
/// Handles user registration, login, Google OAuth, profile management,
/// and social follow/unfollow operations. Maintains user sessions for
/// accessing betting features and social interactions.
class AuthService {
  final supabase = SupabaseConfig.supabase;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      clientId: !kIsWeb
          ? '454829996179-4g3cv5eiadbmf3tom9m5r1ae3n919j5r.apps.googleusercontent.com'
          : '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com',
      serverClientId: !kIsWeb
          ? '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com'
          : null,
      scopes: ['email', 'profile'],
    );
  }

  /// Updates user's favorite sports teams in their profile.
  /// 
  /// Used during onboarding and profile customization to personalize
  /// the user's betting experience and social feed content.
  /// 
  /// Parameters:
  ///   - favoriteTeams: List of team names the user wants to follow
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or database update fails
  Future<void> updateFavoriteTeams(List<dynamic> favoriteTeams) async {
    await updateProfile(favoriteTeams: favoriteTeams.cast<String>());
  }

  /// Debug method to check authentication state and user profile.
  /// 
  /// Logs comprehensive authentication information including user ID,
  /// session token, and profile data for troubleshooting login issues
  /// or session management problems in the betting app.
  /// 
  /// Returns:
  ///   void - Only logs debug information to console
  Future<void> debugAuthState() async {
    print('=== AUTH DEBUG INFO ===');
    final user = currentUser;
    final session = currentSession;
    
    print('User: $user');
    print('Session: $session');
    print('User ID: ${user?.id}');
    print('User Email: ${user?.email}');
    print('Session Token: ${session?.accessToken?.substring(0, 20)}...');
    
    if (user != null) {
      try {
        final profile = await getCurrentUserProfile();
        print('Profile: $profile');
      } catch (e) {
        print('Profile fetch error: $e');
      }
    }
    print('=====================');
  }

  User? get currentUser {
    final user = supabase.auth.currentUser;
    print('Current User Check: $user');
    return user;
  }

  Session? get currentSession {
    final session = supabase.auth.currentSession;
    print('Current Session Check: $session');
    return session;
  }

  Stream<AuthState> get authStateChanges {
    print('Setting up auth state stream');
    return supabase.auth.onAuthStateChange;
  }

  /// Authenticates user with email and password.
  /// 
  /// Provides secure login for WagerLoop users to access their betting
  /// history, social posts, and account settings.
  /// 
  /// Parameters:
  ///   - email: User's registered email address
  ///   - password: User's account password
  /// 
  /// Returns:
  ///   AuthResponse containing user session and profile data
  /// 
  /// Throws:
  ///   - AuthException: If credentials are invalid or user doesn't exist
  ///   - NetworkException: If connection to auth service fails
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      // Create auth user
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        // Wait a moment for the session to be fully established
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Create profile in one atomic operation
        try {
          await supabase.from('profiles').upsert({
            'id': response.user!.id,
            'username': username,
            'email': email,
            'full_name': fullName,
            'has_completed_onboarding': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
        } catch (profileError) {
          print('Profile creation error during signup: $profileError');
          // Don't throw here - let the user proceed to onboarding
        }
      }

      return response;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  /// Authenticates user with Google OAuth.
  /// 
  /// Provides seamless Google sign-in for WagerLoop users, handling
  /// both web and mobile OAuth flows. Creates user profile automatically
  /// if signing in for the first time.
  /// 
  /// Returns:
  ///   AuthResponse with user session for accessing betting features
  /// 
  /// Throws:
  ///   - AuthException: If Google OAuth flow fails or is cancelled
  ///   - PlatformException: If Google services are unavailable
  Future<AuthResponse> signInWithGoogle() async {
    try {
      print('Initializing Google Sign In');

      if (kIsWeb) {
        print('Using web OAuth flow');
        final success = await supabase.auth.signInWithOAuth(
          Provider.google,
          redirectTo: Uri.base.origin + Uri.base.path,
          queryParams: {
            'access_type': 'offline',
            'prompt': 'consent',
          },
        );

        if (!success) {
          throw 'Failed to initialize OAuth flow';
        }

        return AuthResponse(session: null, user: null);
      } else {
        print('Using mobile sign in flow');
        
        // Sign out first to prevent "Future already completed" error
        await _googleSignIn.signOut();
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          print('Google Sign In was cancelled by user');
          throw 'Sign in cancelled';
        }

        print('Getting Google authentication');
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null || idToken == null) {
          print('Failed to get Google tokens');
          throw 'Authentication failed';
        }

        print('Signing in to Supabase with Google tokens');
        final response = await supabase.auth.signInWithIdToken(
          provider: Provider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        // Create profile for Google sign-in if it doesn't exist
        if (response.user != null) {
          // Wait a moment for the session to be fully established
          await Future.delayed(const Duration(milliseconds: 500));
          
          final existingProfile = await supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (existingProfile == null) {
            final googleData = response.user!.userMetadata;
            final username =
                '${googleData?['name'] ?? 'user'}_${response.user!.id.substring(0, 6)}';

            try {
              await supabase.from('profiles').insert({
                'id': response.user!.id,
                'email': response.user!.email,
                'username': username.toLowerCase().replaceAll(' ', '_'),
                'full_name': googleData?['full_name'] ?? googleData?['name'],
                'avatar_url': googleData?['avatar_url'],
                'has_completed_onboarding': false,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (profileError) {
              print('Profile creation error (this may be normal): $profileError');
              // Don't throw here - the profile might be created by a trigger
            }
          }
        }

        print('Google sign in response: $response');
        return response;
      }
    } catch (e, stackTrace) {
      print('Google sign in error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

// Modify getCurrentUserProfile to handle potential missing profiles
  /// Retrieves the current user's profile data from the database.
  /// 
  /// Ensures a profile exists for the authenticated user, creating one
  /// if it doesn't. Returns a map of profile data including username,
  /// email, and completion status.
  /// 
  /// Returns:
  ///   Map<String, dynamic>? - A map of profile data or null if user is not authenticated
  /// 
  /// Throws:
  ///   - Exception: If database query or profile creation fails
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('No current user in getCurrentUserProfile');
        return null;
      }

      print('Getting profile for user: ${user.id}');

      // Try to get existing profile
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      print('Existing profile: $existingProfile');

      // If no profile exists, create one
      if (existingProfile == null) {
        print('No profile found, creating one');
        try {
          final insertedProfile = await supabase
              .from('profiles')
              .insert({
                'id': user.id,
                'username': user.userMetadata?['username'] ?? '',
                'email': user.email,
                'has_completed_onboarding': false,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

          print('Created profile: $insertedProfile');
          return insertedProfile;
        } catch (createError) {
          print('Error creating profile: $createError');
          // Return a minimal profile object if creation fails
          return {
            'id': user.id,
            'email': user.email,
            'username': '',
            'has_completed_onboarding': false,
          };
        }
      }

      return existingProfile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Updates the current user's profile information.
  /// 
  /// Allows users to change their username, full name, bio, avatar,
  /// and favorite teams. Ensures username uniqueness and handles
  /// profile completion status.
  /// 
  /// Parameters:
  ///   - username: Optional new username (must be unique)
  ///   - fullName: Optional new full name
  ///   - bio: Optional new bio
  ///   - avatarUrl: Optional new avatar URL
  ///   - favoriteTeams: Optional new list of favorite teams
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or profile update fails
  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    List<String>? favoriteTeams,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        print('User is null in updateProfile');
        throw 'User not authenticated';
      }

      print('Updating profile for user: ${user.id}');

      // Additional username uniqueness check
      if (username != null) {
        final existingUser = await supabase
            .from('profiles')
            .select('username')
            .eq('username', username)
            .neq('id', user.id)
            .maybeSingle();

        if (existingUser != null) {
          throw 'Username is already taken';
        }
      }

      final updates = {
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (favoriteTeams != null) 'favorite_teams': favoriteTeams,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Profile updates: $updates');

      // This will only work if the user's ID matches the row's ID
      final result = await supabase.from('profiles').update(updates).eq('id', user.id);
      print('Profile update result: $result');
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  /// Marks the current user's onboarding as complete.
  /// 
  /// Updates the 'has_completed_onboarding' flag in the user's profile
  /// to true, indicating that the user has finished the initial setup.
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or onboarding completion fails
  Future<void> completeOnboarding() async {
    try {
      final user = currentUser;
      if (user == null) {
        print('User is null in completeOnboarding');
        throw 'User not authenticated';
      }

      print('Completing onboarding for user: ${user.id}');

      final result = await supabase.from('profiles').update({
        'has_completed_onboarding': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      print('Onboarding completion result: $result');
    } catch (e) {
      print('Error completing onboarding: $e');
      rethrow;
    }
  }

  /// Signs out the current user from the application.
  /// 
  /// Handles both web and mobile sign-out, including Google sign-out
  /// for mobile platforms. Clears the user's session and profile data.
  /// 
  /// Throws:
  ///   - Exception: If sign-out fails
  Future<void> signOut() async {
    try {
      print('Attempting sign out');
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await supabase.auth.signOut();
      print('Sign out completed');
    } catch (e, stackTrace) {
      print('Sign out error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get followers for a user
  /// Retrieves a list of users who follow the specified user.
  /// 
  /// Used to display a user's followers in their profile or social feed.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user whose followers are to be retrieved
  /// 
  /// Returns:
  ///   List<Map<String, dynamic>> - A list of follower profiles
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await supabase.from('followers').select('''
            follower_id,
            follower:profiles!followers_follower_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('following_id', userId);

      return (response as List).map((record) {
        final profile = record['follower'];
        return {
          'id': profile['id'],
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'full_name': profile['full_name'],
        };
      }).toList();
    } catch (e) {
      print('Error getting followers: $e');
      rethrow;
    }
  }

  // Get users that a user follows
  /// Retrieves a list of users that the specified user follows.
  /// 
  /// Used to display a user's following list in their profile or social feed.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user whose following list is to be retrieved
  /// 
  /// Returns:
  ///   List<Map<String, dynamic>> - A list of following profiles
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await supabase.from('followers').select('''
            following_id,
            following:profiles!followers_following_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('follower_id', userId);

      return (response as List).map((record) {
        final profile = record['following'];
        return {
          'id': profile['id'],
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'full_name': profile['full_name'],
        };
      }).toList();
    } catch (e) {
      print('Error getting following: $e');
      rethrow;
    }
  }

  // Check if current user follows another user
  /// Checks if the current authenticated user follows the specified user.
  /// 
  /// Used to determine if a user is following another user for social
  /// interaction features like follow/unfollow.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user to check if the current user follows
  /// 
  /// Returns:
  ///   bool - True if the current user follows the specified user, false otherwise
  /// 
  /// Throws:
  ///   - Exception: If database query fails
  Future<bool> isFollowing(String userId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // Follow a user
  /// Follows the specified user.
  /// 
  /// Allows users to follow other users for social interaction and
  /// to receive updates from their followed users.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user to follow
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or follow fails
  Future<void> followUser(String userId) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not authenticated';

      await supabase.from('followers').insert({
        'follower_id': user.id,
        'following_id': userId,
      });
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  // Unfollow a user
  /// Unfollows the specified user.
  /// 
  /// Allows users to unfollow other users, removing them from their
  /// following list and preventing future updates.
  /// 
  /// Parameters:
  ///   - userId: The ID of the user to unfollow
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or unfollow fails
  Future<void> unfollowUser(String userId) async {
    try {
      final user = currentUser;
      if (user == null) throw 'User not authenticated';

      await supabase
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', userId);
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }
}
