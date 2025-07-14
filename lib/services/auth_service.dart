import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase Flutter SDK for authentication and database operations
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In package for OAuth authentication
import 'package:flutter/foundation.dart' show kIsWeb; // Import Flutter foundation library specifically for web platform detection
import 'supabase_config.dart'; // Import local Supabase configuration file

/// Manages user authentication and session handling for WagerLoop.
/// 
/// Handles user registration, login, Google OAuth, profile management,
/// and social follow/unfollow operations. Maintains user sessions for
/// accessing betting features and social interactions.
class AuthService { // Define AuthService class to manage all authentication operations
  final supabase = SupabaseConfig.supabase; // Create a reference to the Supabase client from configuration
  late final GoogleSignIn _googleSignIn; // Declare a late final GoogleSignIn instance for OAuth authentication

  AuthService() { // Constructor for AuthService class
    _googleSignIn = GoogleSignIn( // Initialize the GoogleSignIn instance with configuration
      clientId: !kIsWeb // Set the client ID based on the platform (web vs mobile)
          ? '454829996179-4g3cv5eiadbmf3tom9m5r1ae3n919j5r.apps.googleusercontent.com' // Mobile client ID for Android/iOS
          : '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com', // Web client ID for browser
      serverClientId: !kIsWeb // Set the server client ID based on the platform
          ? '454829996179-g92j5di0fuvv10c5l92dkh5nffgrgift.apps.googleusercontent.com' // Server client ID for mobile platforms
          : null, // No server client ID needed for web platform
      scopes: ['email', 'profile'], // Define the OAuth scopes to request email and profile information
    ); // End of GoogleSignIn initialization
  } // End of AuthService constructor

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
  Future<void> updateFavoriteTeams(List<dynamic> favoriteTeams) async { // Define async method to update user's favorite teams
    await updateProfile(favoriteTeams: favoriteTeams.cast<String>()); // Call updateProfile method with favorite teams cast to string list
  } // End of updateFavoriteTeams method

  /// Debug method to check authentication state and user profile.
  /// 
  /// Logs comprehensive authentication information including user ID,
  /// session token, and profile data for troubleshooting login issues
  /// or session management problems in the betting app.
  /// 
  /// Returns:
  ///   void - Only logs debug information to console
  Future<void> debugAuthState() async { // Define async method to debug authentication state
    print('=== AUTH DEBUG INFO ==='); // Print debug section header to console
    final user = currentUser; // Get the current user from Supabase
    final session = currentSession; // Get the current session from Supabase
    
    print('User: $user'); // Log the current user object
    print('Session: $session'); // Log the current session object
    print('User ID: ${user?.id}'); // Log the user's ID if available
    print('User Email: ${user?.email}'); // Log the user's email if available
    print('Session Token: ${session?.accessToken?.substring(0, 20)}...'); // Log the first 20 characters of the session token
    
    if (user != null) { // Check if user is not null
      try {
        final profile = await getCurrentUserProfile(); // Get the current user's profile
        print('Profile: $profile'); // Log the profile data
      } catch (e) {
        print('Profile fetch error: $e'); // Log any error during profile fetch
      }
    }
    print('====================='); // Print a separator line
  } // End of debugAuthState method

  User? get currentUser { // Define getter for the current user
    final user = supabase.auth.currentUser; // Get the current user from Supabase
    print('Current User Check: $user'); // Log the current user object
    return user; // Return the user object
  } // End of currentUser getter

  Session? get currentSession { // Define getter for the current session
    final session = supabase.auth.currentSession; // Get the current session from Supabase
    print('Current Session Check: $session'); // Log the current session object
    return session; // Return the session object
  } // End of currentSession getter

  Stream<AuthState> get authStateChanges { // Define getter for the authentication state changes stream
    print('Setting up auth state stream'); // Log the start of setting up the stream
    return supabase.auth.onAuthStateChange; // Return the stream from Supabase
  } // End of authStateChanges getter

  /// Authenticates user with email and password.
  /// 
  /// Provides secure login for WagerLoop users to access their betting
  /// history, social posts, and account settings.
  /// 
  /// Parameters:
  ///   - email: User's registered email address
  ///   - password: User's account password
  ///   - username: User's desired username
  ///   - fullName: Optional new full name for the user
  /// 
  /// Returns:
  ///   AuthResponse containing user session and profile data
  /// 
  /// Throws:
  ///   - AuthException: If credentials are invalid or user doesn't exist
  ///   - NetworkException: If connection to auth service fails
  Future<AuthResponse> signUp({ // Define async method to sign up a new user
    required String email, // Required email address
    required String password, // Required password
    required String username, // Required username
    String? fullName, // Optional full name
  }) async { // Begin async block
    try { // Begin try block
      // Create auth user
      final response = await supabase.auth.signUp( // Sign up the user with Supabase
        email: email, // Set email
        password: password, // Set password
        data: { // Set additional user data (username, full_name)
          'username': username,
          'full_name': fullName,
        },
      ); // End Supabase sign up

      if (response.user != null) { // Check if the response includes a user
        // Wait a moment for the session to be fully established
        await Future.delayed(const Duration(milliseconds: 500)); // Wait for session to be fully established
        
        // Create profile in one atomic operation
        try { // Begin try block for profile creation
          await supabase.from('profiles').upsert({ // Upsert the profile into the 'profiles' table
            'id': response.user!.id, // Set ID to the user's ID
            'username': username, // Set username
            'email': email, // Set email
            'full_name': fullName, // Set full name
            'has_completed_onboarding': false, // Set onboarding completion status
            'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
            'updated_at': DateTime.now().toIso8601String(), // Set update timestamp
          }, onConflict: 'id'); // Specify conflict resolution strategy
        } catch (profileError) { // Catch any error during profile creation
          print('Profile creation error during signup: $profileError'); // Log the error
          // Don't throw here - let the user proceed to onboarding
        } // End try block for profile creation
      } // End if block for response.user != null

      return response; // Return the AuthResponse
    } catch (e) { // Catch any error during sign up
      print('Sign up error: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for sign up
  } // End of signUp method

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
  Future<AuthResponse> signInWithGoogle() async { // Define async method to sign in with Google
    try { // Begin try block
      print('Initializing Google Sign In'); // Log the start of Google Sign In process

      if (kIsWeb) { // Check if the app is running on the web platform
        print('Using web OAuth flow'); // Log the web OAuth flow
        final success = await supabase.auth.signInWithOAuth( // Sign in with Supabase using Google provider
          Provider.google, // Specify the provider
          redirectTo: Uri.base.origin + Uri.base.path, // Set redirect URL for web
          queryParams: { // Add query parameters for web
            'access_type': 'offline',
            'prompt': 'consent',
          },
        ); // End Supabase sign in with OAuth

        if (!success) { // Check if the sign-in was successful
          throw 'Failed to initialize OAuth flow'; // Throw an error if it failed
        }

        return AuthResponse(session: null, user: null); // Return a dummy response as it's a redirect
      } else { // If not on web, use mobile sign-in flow
        print('Using mobile sign in flow'); // Log the mobile sign-in flow
        
        // Sign out first to prevent "Future already completed" error
        await _googleSignIn.signOut(); // Sign out from Google Sign-In
        
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn(); // Sign in with Google Sign-In

        if (googleUser == null) { // Check if the sign-in was cancelled
          print('Google Sign In was cancelled by user'); // Log cancellation
          throw 'Sign in cancelled'; // Throw an error for cancelled sign-in
        }

        print('Getting Google authentication'); // Log getting Google authentication
        final googleAuth = await googleUser.authentication; // Get authentication details from Google
        final accessToken = googleAuth.accessToken; // Get access token
        final idToken = googleAuth.idToken; // Get ID token

        if (accessToken == null || idToken == null) { // Check if tokens are obtained
          print('Failed to get Google tokens'); // Log failure to get tokens
          throw 'Authentication failed'; // Throw an error for failed authentication
        }

        print('Signing in to Supabase with Google tokens'); // Log signing in to Supabase with tokens
        final response = await supabase.auth.signInWithIdToken( // Sign in with Supabase using ID token
          provider: Provider.google, // Specify the provider
          idToken: idToken, // Set ID token
          accessToken: accessToken, // Set access token
        ); // End Supabase sign in with ID token

        // Create profile for Google sign-in if it doesn't exist
        if (response.user != null) { // Check if the response includes a user
          // Wait a moment for the session to be fully established
          await Future.delayed(const Duration(milliseconds: 500)); // Wait for session to be fully established
          
          final existingProfile = await supabase // Check if a profile already exists for the user
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (existingProfile == null) { // If no profile exists, create one
            final googleData = response.user!.userMetadata; // Get user metadata from Supabase
            final username = // Generate a unique username
                '${googleData?['name'] ?? 'user'}_${response.user!.id.substring(0, 6)}';

            try { // Begin try block for profile creation
              await supabase.from('profiles').insert({ // Insert the new profile into the 'profiles' table
                'id': response.user!.id, // Set ID
                'email': response.user!.email, // Set email
                'username': username.toLowerCase().replaceAll(' ', '_'), // Set username, sanitize
                'full_name': googleData?['full_name'] ?? googleData?['name'], // Set full name
                'avatar_url': googleData?['avatar_url'], // Set avatar URL
                'has_completed_onboarding': false, // Set onboarding completion status
                'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
                'updated_at': DateTime.now().toIso8601String(), // Set update timestamp
              }); // End Supabase insert
            } catch (profileError) { // Catch any error during profile creation
              print('Profile creation error (this may be normal): $profileError'); // Log the error
              // Don't throw here - the profile might be created by a trigger
            } // End try block for profile creation
          } // End if block for existingProfile == null
        } // End if block for response.user != null

        print('Google sign in response: $response'); // Log the final response
        return response; // Return the AuthResponse
      } // End else block for kIsWeb
    } catch (e, stackTrace) { // Catch any error during Google sign-in
      print('Google sign in error: $e'); // Log the error
      print('Stack trace: $stackTrace'); // Log the stack trace
      rethrow; // Re-throw the error
    } // End try-catch block for Google sign-in
  } // End of signInWithGoogle method

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
  Future<Map<String, dynamic>?> getCurrentUserProfile() async { // Define async method to get current user profile
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) { // Check if user is null
        print('No current user in getCurrentUserProfile'); // Log no current user
        return null; // Return null if user is not authenticated
      }

      print('Getting profile for user: ${user.id}'); // Log getting profile for user

      // Try to get existing profile
      final existingProfile = await supabase // Query the 'profiles' table for the user's profile
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      print('Existing profile: $existingProfile'); // Log the existing profile

      // If no profile exists, create one
      if (existingProfile == null) { // Check if profile does not exist
        print('No profile found, creating one'); // Log creating new profile
        try { // Begin try block for profile creation
          final insertedProfile = await supabase // Insert the new profile into the 'profiles' table
              .from('profiles')
              .insert({
                'id': user.id, // Set ID
                'username': user.userMetadata?['username'] ?? '', // Set username, use existing or empty
                'email': user.email, // Set email
                'has_completed_onboarding': false, // Set onboarding completion status
                'created_at': DateTime.now().toIso8601String(), // Set creation timestamp
                'updated_at': DateTime.now().toIso8601String(), // Set update timestamp
              })
              .select() // Select the newly inserted profile
              .single();

          print('Created profile: $insertedProfile'); // Log the created profile
          return insertedProfile; // Return the inserted profile
        } catch (createError) { // Catch any error during profile creation
          print('Error creating profile: $createError'); // Log the error
          // Return a minimal profile object if creation fails
          return { // Return a minimal profile object
            'id': user.id,
            'email': user.email,
            'username': '',
            'has_completed_onboarding': false,
          };
        } // End try block for profile creation
      } // End if block for existingProfile == null

      return existingProfile; // Return the existing profile
    } catch (e) { // Catch any error during profile retrieval
      print('Error getting user profile: $e'); // Log the error
      return null; // Return null on error
    } // End try-catch block for profile retrieval
  } // End of getCurrentUserProfile method

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
  Future<void> updateProfile({ // Define async method to update user profile
    String? username, // Optional new username
    String? fullName, // Optional new full name
    String? bio, // Optional new bio
    String? avatarUrl, // Optional new avatar URL
    List<String>? favoriteTeams, // Optional new list of favorite teams
  }) async { // Begin async block
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) { // Check if user is null
        print('User is null in updateProfile'); // Log user is null
        throw 'User not authenticated'; // Throw an error for not authenticated user
      }

      print('Updating profile for user: ${user.id}'); // Log updating profile for user

      // Additional username uniqueness check
      if (username != null) { // Check if username is provided
        final existingUser = await supabase // Query the 'profiles' table for existing users with the same username
            .from('profiles')
            .select('username')
            .eq('username', username)
            .neq('id', user.id) // Exclude the current user's profile
            .maybeSingle();

        if (existingUser != null) { // Check if username is already taken
          throw 'Username is already taken'; // Throw an error for taken username
        }
      }

      final updates = { // Prepare updates for the profile
        if (username != null) 'username': username, // Add username if provided
        if (fullName != null) 'full_name': fullName, // Add full name if provided
        if (bio != null) 'bio': bio, // Add bio if provided
        if (avatarUrl != null) 'avatar_url': avatarUrl, // Add avatar URL if provided
        if (favoriteTeams != null) 'favorite_teams': favoriteTeams, // Add favorite teams if provided
        'updated_at': DateTime.now().toIso8601String(), // Set update timestamp
      };

      print('Profile updates: $updates'); // Log the updates

      // This will only work if the user's ID matches the row's ID
      final result = await supabase.from('profiles').update(updates).eq('id', user.id); // Update the profile in the 'profiles' table
      print('Profile update result: $result'); // Log the update result
    } catch (e) { // Catch any error during profile update
      print('Error updating profile: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for profile update
  } // End of updateProfile method

  /// Marks the current user's onboarding as complete.
  /// 
  /// Updates the 'has_completed_onboarding' flag in the user's profile
  /// to true, indicating that the user has finished the initial setup.
  /// 
  /// Throws:
  ///   - Exception: If user is not authenticated or onboarding completion fails
  Future<void> completeOnboarding() async { // Define async method to complete onboarding
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) { // Check if user is null
        print('User is null in completeOnboarding'); // Log user is null
        throw 'User not authenticated'; // Throw an error for not authenticated user
      }

      print('Completing onboarding for user: ${user.id}'); // Log completing onboarding for user

      final result = await supabase.from('profiles').update({ // Update the 'has_completed_onboarding' flag
        'has_completed_onboarding': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id); // Update the profile in the 'profiles' table
      
      print('Onboarding completion result: $result'); // Log the onboarding completion result
    } catch (e) { // Catch any error during onboarding completion
      print('Error completing onboarding: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for onboarding completion
  } // End of completeOnboarding method

  /// Signs out the current user from the application.
  /// 
  /// Handles both web and mobile sign-out, including Google sign-out
  /// for mobile platforms. Clears the user's session and profile data.
  /// 
  /// Throws:
  ///   - Exception: If sign-out fails
  Future<void> signOut() async { // Define async method to sign out
    try { // Begin try block
      print('Attempting sign out'); // Log the start of sign out
      if (!kIsWeb) { // Check if not on web platform
        await _googleSignIn.signOut(); // Sign out from Google Sign-In
      }
      await supabase.auth.signOut(); // Sign out from Supabase
      print('Sign out completed'); // Log sign out completion
    } catch (e, stackTrace) { // Catch any error during sign out
      print('Sign out error: $e'); // Log the error
      print('Stack trace: $stackTrace'); // Log the stack trace
      rethrow; // Re-throw the error
    } // End try-catch block for sign out
  } // End of signOut method

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
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async { // Define async method to get followers
    try { // Begin try block
      final response = await supabase.from('followers').select(''' // Query the 'followers' table for followers
            follower_id,
            follower:profiles!followers_follower_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('following_id', userId);

      return (response as List).map((record) { // Map the response to a list of follower profiles
        final profile = record['follower']; // Get the profile data from the record
        return {
          'id': profile['id'], // Set ID
          'username': profile['username'], // Set username
          'avatar_url': profile['avatar_url'], // Set avatar URL
          'full_name': profile['full_name'], // Set full name
        };
      }).toList(); // Return the list of follower profiles
    } catch (e) { // Catch any error during follower retrieval
      print('Error getting followers: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for follower retrieval
  } // End of getFollowers method

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
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async { // Define async method to get following
    try { // Begin try block
      final response = await supabase.from('followers').select(''' // Query the 'followers' table for following
            following_id,
            following:profiles!followers_following_id_fkey (
              id,
              username,
              avatar_url,
              full_name
            )
          ''').eq('follower_id', userId);

      return (response as List).map((record) { // Map the response to a list of following profiles
        final profile = record['following']; // Get the profile data from the record
        return {
          'id': profile['id'], // Set ID
          'username': profile['username'], // Set username
          'avatar_url': profile['avatar_url'], // Set avatar URL
          'full_name': profile['full_name'], // Set full name
        };
      }).toList(); // Return the list of following profiles
    } catch (e) { // Catch any error during following retrieval
      print('Error getting following: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for following retrieval
  } // End of getFollowing method

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
  Future<bool> isFollowing(String userId) async { // Define async method to check if following
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) return false; // Return false if user is not authenticated

      final response = await supabase // Query the 'followers' table for the follow status
          .from('followers')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null; // Return true if following, false otherwise
    } catch (e) { // Catch any error during follow status check
      print('Error checking follow status: $e'); // Log the error
      return false; // Return false on error
    } // End try-catch block for follow status check
  } // End of isFollowing method

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
  Future<void> followUser(String userId) async { // Define async method to follow a user
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) throw 'User not authenticated'; // Throw an error for not authenticated user

      await supabase.from('followers').insert({ // Insert the follow relationship into the 'followers' table
        'follower_id': user.id, // Set follower ID
        'following_id': userId, // Set following ID
      });
    } catch (e) { // Catch any error during follow
      print('Error following user: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for follow
  } // End of followUser method

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
  Future<void> unfollowUser(String userId) async { // Define async method to unfollow a user
    try { // Begin try block
      final user = currentUser; // Get the current user from Supabase
      if (user == null) throw 'User not authenticated'; // Throw an error for not authenticated user

      await supabase // Delete the follow relationship from the 'followers' table
          .from('followers')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', userId);
    } catch (e) { // Catch any error during unfollow
      print('Error unfollowing user: $e'); // Log the error
      rethrow; // Re-throw the error
    } // End try-catch block for unfollow
  } // End of unfollowUser method
} // End of AuthService class
