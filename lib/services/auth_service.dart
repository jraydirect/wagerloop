// Import Supabase Flutter SDK for backend authentication and database operations - provides auth, database, and storage functionality
import 'package:supabase_flutter/supabase_flutter.dart';
// Import Google Sign-In package for OAuth authentication - enables Google login on mobile platforms
import 'package:google_sign_in/google_sign_in.dart';
// Import Flutter foundation library for web platform detection - helps determine if running on web vs mobile
import 'package:flutter/foundation.dart' show kIsWeb;
// Import local Supabase configuration - provides access to Supabase client and settings
import 'supabase_config.dart';

/// Manages user authentication and session handling for WagerLoop.
/// 
/// Handles user registration, login, Google OAuth, profile management,
/// and social follow/unfollow operations. Maintains user sessions for
/// accessing betting features and social interactions.
class AuthService {
  // Get the Supabase client instance from configuration - provides access to all Supabase services
  final supabase = SupabaseConfig.supabase;
  // Declare Google Sign-In instance as late final - will be initialized in constructor
  late final GoogleSignIn _googleSignIn;

  // Constructor that initializes Google Sign-In with appropriate client IDs - sets up OAuth for different platforms
  AuthService() {
    // Initialize Google Sign-In with different client IDs for web and mobile - ensures proper OAuth flow for each platform
    _googleSignIn = GoogleSignIn(
      // Use different client ID based on platform (web vs mobile) - web and mobile require different OAuth configurations
      clientId: !kIsWeb
          ? '454829996179-4g3cv5eiadbmf3tom9m5r1ae3n919j5r.apps.googleusercontent.com'
          : '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com',
      // Server client ID for mobile platforms - required for mobile OAuth flow
      serverClientId: !kIsWeb
          ? '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com'
          : null,
      // Request email and profile scopes for user data - these permissions are needed for user profile information
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
    // Call updateProfile method with the favorite teams list - delegates to the main profile update method
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
    // Print debug header - marks the start of debug information
    print('=== AUTH DEBUG INFO ===');
    // Get current user from Supabase - retrieves the currently authenticated user
    final user = currentUser;
    // Get current session from Supabase - retrieves the current authentication session
    final session = currentSession;
    
    // Print user information - displays user object for debugging
    print('User: $user');
    // Print session information - displays session object for debugging
    print('Session: $session');
    // Print user ID - displays the unique user identifier
    print('User ID: ${user?.id}');
    // Print user email - displays the user's email address
    print('User Email: ${user?.email}');
    // Print first 20 characters of session token for security - shows partial token for debugging without exposing full token
    print('Session Token: ${session?.accessToken?.substring(0, 20)}...');
    
    // If user exists, try to get their profile - only attempt profile fetch if user is authenticated
    if (user != null) {
      try {
        // Get current user profile - retrieves user's profile data from database
        final profile = await getCurrentUserProfile();
        // Print profile information - displays profile object for debugging
        print('Profile: $profile');
      } catch (e) {
        // Print error if profile fetch fails - logs any errors during profile retrieval
        print('Profile fetch error: $e');
      }
    }
    // Print debug footer - marks the end of debug information
    print('=====================');
  }

  // Getter for current authenticated user - provides easy access to current user
  User? get currentUser {
    // Get current user from Supabase auth - retrieves the currently logged in user
    final user = supabase.auth.currentUser;
    // Print current user for debugging - logs user information for troubleshooting
    print('Current User Check: $user');
    // Return the current user - returns null if no user is authenticated
    return user;
  }

  // Getter for current session - provides easy access to current authentication session
  Session? get currentSession {
    // Get current session from Supabase auth - retrieves the current authentication session
    final session = supabase.auth.currentSession;
    // Print current session for debugging - logs session information for troubleshooting
    print('Current Session Check: $session');
    // Return the current session - returns null if no session exists
    return session;
  }

  // Getter for auth state changes stream - provides real-time authentication state updates
  Stream<AuthState> get authStateChanges {
    // Print debug message - logs when auth state stream is being set up
    print('Setting up auth state stream');
    // Return auth state changes stream from Supabase - provides real-time auth state updates
    return supabase.auth.onAuthStateChange;
  }

  /// Authenticates user with email and password.
  /// 
  /// Provides secure registration for WagerLoop users to create new accounts
  /// and access betting features and social interactions.
  /// 
  /// Parameters:
  ///   - email: User's email address for registration
  ///   - password: User's chosen password
  ///   - username: User's chosen username
  ///   - fullName: User's full name (optional)
  /// 
  /// Returns:
  ///   AuthResponse containing user session and profile data
  /// 
  /// Throws:
  ///   - AuthException: If registration fails or user already exists
  ///   - NetworkException: If connection to auth service fails
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      // Create auth user with Supabase - registers new user in authentication system
      final response = await supabase.auth.signUp(
        // Set user email - primary identifier for the account
        email: email,
        // Set user password - must meet security requirements
        password: password,
        // Set additional user metadata - stores username and full name with the auth account
        data: {
          'username': username,
          'full_name': fullName,
        },
      );

      // If user was created successfully - check if registration was successful
      if (response.user != null) {
        // Wait a moment for the session to be fully established - ensures auth state is stable
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Create profile in one atomic operation - creates user profile in database
        try {
          // Insert user profile into profiles table - stores additional user information
          await supabase.from('profiles').upsert({
            // Set user ID from auth response - links profile to auth account
            'id': response.user!.id,
            // Set username from registration - user's display name
            'username': username,
            // Set email from registration - user's email address
            'email': email,
            // Set full name from registration - user's full name
            'full_name': fullName,
            // Mark onboarding as not completed - user needs to complete setup
            'has_completed_onboarding': false,
            // Set creation timestamp - when the profile was created
            'created_at': DateTime.now().toIso8601String(),
            // Set update timestamp - when the profile was last updated
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
        } catch (profileError) {
          // Print profile creation error but don't throw - profile creation is not critical for signup
          print('Profile creation error during signup: $profileError');
          // Don't throw here - let the user proceed to onboarding - allows signup to succeed even if profile creation fails
        }
      }

      // Return the auth response - contains user session and profile data
      return response;
    } catch (e) {
      // Print sign up error - logs any errors during registration
      print('Sign up error: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
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
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Print debug message for email sign in attempt - logs the login attempt for debugging
      print('Attempting email sign in for: $email');
      
      // Sign in with email and password using Supabase - authenticates user with provided credentials
      final response = await supabase.auth.signInWithPassword(
        // Set user email - the email address to authenticate
        email: email,
        // Set user password - the password for the account
        password: password,
      );
      
      // Print user ID from response for debugging - logs successful authentication
      print('Sign in response: ${response.user?.id}');
      
      // Ensure profile exists for the user - creates profile if it doesn't exist
      if (response.user != null) {
        // Wait a moment for the session to be fully established - ensures auth state is stable
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Check if profile already exists for this user - queries database for existing profile
          final existingProfile = await supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();
          
          // If no profile exists, create one - ensures every user has a profile
          if (existingProfile == null) {
            // Print debug message for profile creation - logs when creating new profile
            print('Creating profile for existing user');
            // Insert new profile for the user - creates profile in database
            await supabase.from('profiles').insert({
              // Set user ID from auth response - links profile to auth account
              'id': response.user!.id,
              // Create username from email (before @ symbol) - generates username from email address
              'username': response.user!.email?.split('@')[0] ?? 'user',
              // Set user email - stores email in profile
              'email': response.user!.email,
              // Mark onboarding as not completed - user needs to complete setup
              'has_completed_onboarding': false,
              // Set creation timestamp - when the profile was created
              'created_at': DateTime.now().toIso8601String(),
              // Set update timestamp - when the profile was last updated
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (profileError) {
          // Print profile error but don't throw - profile creation is not critical for login
          print('Profile check/creation error: $profileError');
          // Don't throw here - let the user proceed - allows login to succeed even if profile creation fails
        }
      }
      
      // Return the auth response - contains user session and profile data
      return response;
    } catch (e) {
      // Print sign in error - logs any errors during authentication
      print('Sign in error: $e');
      // Re-throw the error - allows calling code to handle the error
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
  // Method to sign in with Google OAuth
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Print debug message for Google sign in initialization - logs the start of Google OAuth process
      print('Initializing Google Sign In');

      // Check if running on web platform - determines which OAuth flow to use
      if (kIsWeb) {
        // Print debug message for web OAuth flow - logs web-specific OAuth process
        print('Using web OAuth flow');
        // Initialize OAuth flow for web platform - starts Google OAuth process for web
        final success = await supabase.auth.signInWithOAuth(
          // Use Google as the OAuth provider - specifies Google as the authentication provider
          Provider.google,
          // Set redirect URL for OAuth callback - where user will be redirected after OAuth
          redirectTo: Uri.base.origin + Uri.base.path,
          // Set query parameters for OAuth - configures OAuth flow parameters
          queryParams: {
            'access_type': 'offline',
            'prompt': 'consent',
          },
        );

        // Check if OAuth flow initialization was successful - verifies OAuth flow started properly
        if (!success) {
          // Throw error if OAuth flow failed - handles OAuth initialization failure
          throw 'Failed to initialize OAuth flow';
        }

        // Return empty auth response for web flow - web OAuth completes asynchronously
        return AuthResponse(session: null, user: null);
      } else {
        // Print debug message for mobile sign in flow - logs mobile-specific OAuth process
        print('Using mobile sign in flow');
        
        // Sign out first to prevent "Future already completed" error - clears any existing Google session
        await _googleSignIn.signOut();
        
        // Attempt to sign in with Google - initiates Google sign-in process on mobile
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        // Check if user cancelled the sign in - handles user cancellation of OAuth flow
        if (googleUser == null) {
          // Print debug message for cancelled sign in - logs when user cancels OAuth
          print('Google Sign In was cancelled by user');
          // Throw error for cancelled sign in - allows calling code to handle cancellation
          throw 'Sign in cancelled';
        }

        // Print debug message for getting Google authentication - logs the authentication token retrieval
        print('Getting Google authentication');
        // Get authentication details from Google - retrieves access and ID tokens
        final googleAuth = await googleUser.authentication;
        // Extract access token from Google auth - used for API access
        final accessToken = googleAuth.accessToken;
        // Extract ID token from Google auth - used for Supabase authentication
        final idToken = googleAuth.idToken;

        // Check if both tokens are available - verifies that OAuth provided required tokens
        if (accessToken == null || idToken == null) {
          // Print debug message for missing tokens - logs when OAuth tokens are missing
          print('Failed to get Google tokens');
          // Throw error for authentication failure - handles missing token scenario
          throw 'Authentication failed';
        }

        // Print debug message for signing in to Supabase - logs the Supabase authentication attempt
        print('Signing in to Supabase with Google tokens');
        // Sign in to Supabase using Google tokens - authenticates user with Supabase using Google credentials
        final response = await supabase.auth.signInWithIdToken(
          // Specify Google as the provider - tells Supabase to use Google authentication
          provider: Provider.google,
          // Pass the ID token from Google - provides user identity to Supabase
          idToken: idToken,
          // Pass the access token from Google - provides API access permissions
          accessToken: accessToken,
        );

        // Create profile for Google sign-in if it doesn't exist - ensures Google users have profiles
        if (response.user != null) {
          // Wait a moment for the session to be fully established - ensures auth state is stable
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if profile already exists for this user - queries database for existing profile
          final existingProfile = await supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          // If no profile exists, create one - creates profile for new Google users
          if (existingProfile == null) {
            // Get user metadata from Google - retrieves user information from Google account
            final googleData = response.user!.userMetadata;
            // Create username from Google name and user ID - generates unique username for Google user
            final username =
                '${googleData?['name'] ?? 'user'}_${response.user!.id.substring(0, 6)}';

            try {
              // Insert new profile for Google user - creates profile in database with Google data
              await supabase.from('profiles').insert({
                // Set user ID from auth response - links profile to auth account
                'id': response.user!.id,
                // Set user email from Google - stores Google email in profile
                'email': response.user!.email,
                // Create username from Google data - generates username from Google name
                'username': username.toLowerCase().replaceAll(' ', '_'),
                // Set full name from Google data - stores Google full name in profile
                'full_name': googleData?['full_name'] ?? googleData?['name'],
                // Set avatar URL from Google data - stores Google profile picture URL
                'avatar_url': googleData?['avatar_url'],
                // Mark onboarding as not completed - user needs to complete setup
                'has_completed_onboarding': false,
                // Set creation timestamp - when the profile was created
                'created_at': DateTime.now().toIso8601String(),
                // Set update timestamp - when the profile was last updated
                'updated_at': DateTime.now().toIso8601String(),
              });
            } catch (profileError) {
              // Print profile creation error (may be normal) - logs profile creation issues
              print('Profile creation error (this may be normal): $profileError');
              // Don't throw here - the profile might be created by a trigger - allows OAuth to succeed even if profile creation fails
            }
          }
        }

        // Print debug message with Google sign in response - logs successful Google authentication
        print('Google sign in response: $response');
        // Return the auth response - contains user session and profile data
        return response;
      }
    } catch (e, stackTrace) {
      // Print Google sign in error - logs any errors during Google OAuth
      print('Google sign in error: $e');
      // Print stack trace for debugging - provides detailed error information
      print('Stack trace: $stackTrace');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }

// Method to get current user profile with automatic creation if missing
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Check if user is authenticated - verifies that a user is logged in
      if (user == null) {
        // Print debug message for no current user - logs when no user is authenticated
        print('No current user in getCurrentUserProfile');
        // Return null if no user is authenticated - indicates no profile available
        return null;
      }

      // Print debug message with user ID - logs which user's profile is being retrieved
      print('Getting profile for user: ${user.id}');

      // Try to get existing profile from database - queries the profiles table for user data
      final existingProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Print debug message with existing profile - logs the profile data found
      print('Existing profile: $existingProfile');

      // If no profile exists, create one - ensures every user has a profile
      if (existingProfile == null) {
        // Print debug message for profile creation - logs when creating new profile
        print('No profile found, creating one');
        try {
          // Insert new profile for the user - creates profile in database with basic information
          final insertedProfile = await supabase
              .from('profiles')
              .insert({
                // Set user ID from auth - links profile to authentication account
                'id': user.id,
                // Set username from user metadata or empty string - uses metadata or defaults to empty
                'username': user.userMetadata?['username'] ?? '',
                // Set user email - stores email address in profile
                'email': user.email,
                // Mark onboarding as not completed - indicates user needs to complete setup
                'has_completed_onboarding': false,
                // Set creation timestamp - records when profile was created
                'created_at': DateTime.now().toIso8601String(),
                // Set update timestamp - records when profile was last updated
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

          // Print debug message with created profile - logs the newly created profile data
          print('Created profile: $insertedProfile');
          // Return the created profile - provides the new profile data to caller
          return insertedProfile;
        } catch (createError) {
          // Print error if profile creation fails - logs any errors during profile creation
          print('Error creating profile: $createError');
          // Return a minimal profile object if creation fails - provides fallback profile data
          return {
            'id': user.id,
            'email': user.email,
            'username': '',
            'has_completed_onboarding': false,
          };
        }
      }

      // Return the existing profile - provides the found profile data to caller
      return existingProfile;
    } catch (e) {
      // Print error if getting user profile fails - logs any errors during profile retrieval
      print('Error getting user profile: $e');
      // Return null on error - indicates profile retrieval failed
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Check if user is authenticated - verifies that a user is logged in
      if (user == null) {
        // Print debug message for null user - logs when no user is authenticated
        print('User is null in updateProfile');
        // Throw error for unauthenticated user - prevents profile updates without authentication
        throw 'User not authenticated';
      }

      // Print debug message with user ID - logs which user's profile is being updated
      print('Updating profile for user: ${user.id}');

      // Additional username uniqueness check - ensures username is not already taken
      if (username != null) {
        // Check if username is already taken by another user - queries database for existing username
        final existingUser = await supabase
            .from('profiles')
            .select('username')
            .eq('username', username)
            .neq('id', user.id)
            .maybeSingle();

        // If username is already taken, throw error - prevents duplicate usernames
        if (existingUser != null) {
          // Throw error for duplicate username - allows calling code to handle the error
          throw 'Username is already taken';
        }
      }

      // Create updates map with only non-null values - builds update object with provided fields
      final updates = {
        // Add username if provided - updates username if new value is provided
        if (username != null) 'username': username,
        // Add full name if provided - updates full name if new value is provided
        if (fullName != null) 'full_name': fullName,
        // Add bio if provided - updates bio if new value is provided
        if (bio != null) 'bio': bio,
        // Add avatar URL if provided - updates avatar URL if new value is provided
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        // Add favorite teams if provided - updates favorite teams if new value is provided
        if (favoriteTeams != null) 'favorite_teams': favoriteTeams,
        // Always update the timestamp - records when profile was last updated
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Print debug message with updates - logs what fields are being updated
      print('Profile updates: $updates');

      // Update the profile in the database - applies the changes to the user's profile
      final result = await supabase.from('profiles').update(updates).eq('id', user.id);
      // Print debug message with update result - logs the result of the update operation
      print('Profile update result: $result');
    } catch (e) {
      // Print error if profile update fails - logs any errors during profile update
      print('Error updating profile: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Check if user is authenticated - verifies that a user is logged in
      if (user == null) {
        // Print debug message for null user - logs when no user is authenticated
        print('User is null in completeOnboarding');
        // Throw error for unauthenticated user - prevents onboarding completion without authentication
        throw 'User not authenticated';
      }

      // Print debug message with user ID - logs which user is completing onboarding
      print('Completing onboarding for user: ${user.id}');

      // Update the profile to mark onboarding as complete - sets the onboarding flag to true
      final result = await supabase.from('profiles').update({
        // Mark onboarding as completed - indicates user has finished initial setup
        'has_completed_onboarding': true,
        // Update the timestamp - records when onboarding was completed
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      // Print debug message with completion result - logs the result of onboarding completion
      print('Onboarding completion result: $result');
    } catch (e) {
      // Print error if onboarding completion fails - logs any errors during onboarding completion
      print('Error completing onboarding: $e');
      // Re-throw the error - allows calling code to handle the error
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
      // Print debug message for sign out attempt - logs the start of sign out process
      print('Attempting sign out');
      // Check if not running on web platform - determines if mobile-specific sign out is needed
      if (!kIsWeb) {
        // Sign out from Google for mobile platforms - clears Google authentication session
        await _googleSignIn.signOut();
      }
      // Sign out from Supabase - clears the main authentication session
      await supabase.auth.signOut();
      // Print debug message for completed sign out - logs successful sign out
      print('Sign out completed');
    } catch (e, stackTrace) {
      // Print sign out error - logs any errors during sign out process
      print('Sign out error: $e');
      // Print stack trace for debugging - provides detailed error information
      print('Stack trace: $stackTrace');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }

  // Method to get followers for a user
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
      // Query followers table with joined profile data - retrieves follower information with profile details
      final response = await supabase.from('followers').select('''
            follower_id,
            follower:profiles!followers_follower_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('following_id', userId);

      // Transform the response to return only profile data - converts database response to profile format
      return (response as List).map((record) {
        // Extract follower profile from the record - gets the profile data from the joined query
        final profile = record['follower'];
        // Return formatted profile data - provides clean profile information
        return {
          'id': profile['id'],
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'full_name': profile['full_name'],
        };
      }).toList();
    } catch (e) {
      // Print error if getting followers fails - logs any errors during follower retrieval
      print('Error getting followers: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }

  // Method to get users that a user follows
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
      // Query followers table with joined profile data for following users - retrieves following information with profile details
      final response = await supabase.from('followers').select('''
            following_id,
            following:profiles!followers_following_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('follower_id', userId);

      // Transform the response to return only profile data - converts database response to profile format
      return (response as List).map((record) {
        // Extract following profile from the record - gets the profile data from the joined query
        final profile = record['following'];
        // Return formatted profile data - provides clean profile information
        return {
          'id': profile['id'],
          'username': profile['username'],
          'avatar_url': profile['avatar_url'],
          'full_name': profile['full_name'],
        };
      }).toList();
    } catch (e) {
      // Print error if getting following fails - logs any errors during following retrieval
      print('Error getting following: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }

  // Method to check if current user follows another user
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Return false if no user is authenticated - handles case where no user is logged in
      if (user == null) return false;

      // Query followers table to check if follow relationship exists - searches for follow relationship
      final response = await supabase
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      // Return true if follow relationship exists, false otherwise - indicates if user is following
      return response != null;
    } catch (e) {
      // Print error if checking follow status fails - logs any errors during follow status check
      print('Error checking follow status: $e');
      // Return false on error - provides safe fallback when check fails
      return false;
    }
  }

  // Method to follow a user
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Check if user is authenticated - verifies that a user is logged in
      if (user == null) throw 'User not authenticated';

      // Insert follow relationship into followers table - creates the follow relationship in database
      await supabase.from('followers').insert({
        'follower_id': user.id,
        'following_id': userId,
      });
    } catch (e) {
      // Print error if following user fails - logs any errors during follow operation
      print('Error following user: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }

  // Method to unfollow a user
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
      // Get current authenticated user - retrieves the currently logged in user
      final user = currentUser;
      // Check if user is authenticated - verifies that a user is logged in
      if (user == null) throw 'User not authenticated';

      // Delete follow relationship from followers table - removes the follow relationship from database
      await supabase
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', userId);
    } catch (e) {
      // Print error if unfollowing user fails - logs any errors during unfollow operation
      print('Error unfollowing user: $e');
      // Re-throw the error - allows calling code to handle the error
      rethrow;
    }
  }
}
