// Import Material Design components and widgets for building the UI
import 'package:flutter/material.dart';
// Import authentication service to handle profile operations
import '../../services/auth_service.dart';
// Import custom dice loading widget for loading animations
import '../../widgets/dice_loading_widget.dart';

// OnboardingPage class definition - a stateful widget for user onboarding interface
class OnboardingPage extends StatefulWidget {
  // Constructor with optional key parameter for widget identification
  const OnboardingPage({super.key});

  // Override createState method to return the state class instance
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

// Private state class that manages the onboarding page's state and functionality
class _OnboardingPageState extends State<OnboardingPage> {
  // Page controller for managing page navigation
  final PageController _pageController = PageController();
  // Authentication service instance for handling profile operations
  final _authService = AuthService();
  // Current page index tracker
  int _currentPage = 0;
  // Boolean flag to track loading state during onboarding completion
  bool _isLoading = false;

  // Form controllers
  // Text controller for username input field
  final _usernameController = TextEditingController();
  // Text controller for full name input field
  final _fullNameController = TextEditingController();
  // Text controller for bio input field
  final _bioController = TextEditingController();
  // Set to store selected favorite teams
  final Set<String> _selectedTeams = {};

  // Sample teams data structure
  // Map containing sports leagues and their teams
  final Map<String, List<String>> _teams = {
    'NFL': [
      'Arizona Cardinals',
      'Atlanta Falcons',
      'Baltimore Ravens',
      'Buffalo Bills',
      'Carolina Panthers',
      'Chicago Bears',
      'Cincinnati Bengals',
      'Cleveland Browns',
      'Dallas Cowboys',
      'Denver Broncos',
      'Detroit Lions',
      'Green Bay Packers',
      'Houston Texans',
      'Indianapolis Colts',
      'Jacksonville Jaguars',
      'Kansas City Chiefs',
      'Las Vegas Raiders',
      'Los Angeles Chargers',
      'Los Angeles Rams',
      'Miami Dolphins',
      'Minnesota Vikings',
      'New England Patriots',
      'New Orleans Saints',
      'New York Giants',
      'New York Jets',
      'Philadelphia Eagles',
      'Pittsburgh Steelers',
      'San Francisco 49ers',
      'Seattle Seahawks',
      'Tampa Bay Buccaneers',
      'Tennessee Titans',
      'Washington Commanders'
    ],
    'NBA': [
      'Atlanta Hawks',
      'Boston Celtics',
      'Brooklyn Nets',
      'Charlotte Hornets',
      'Chicago Bulls',
      'Cleveland Cavaliers',
      'Dallas Mavericks',
      'Denver Nuggets',
      'Detroit Pistons',
      'Golden State Warriors',
      'Houston Rockets',
      'Indiana Pacers',
      'LA Clippers',
      'Los Angeles Lakers',
      'Memphis Grizzlies',
      'Miami Heat',
      'Milwaukee Bucks',
      'Minnesota Timberwolves',
      'New Orleans Pelicans',
      'New York Knicks',
      'Oklahoma City Thunder',
      'Orlando Magic',
      'Philadelphia 76ers',
      'Phoenix Suns',
      'Portland Trail Blazers',
      'Sacramento Kings',
      'San Antonio Spurs',
      'Toronto Raptors',
      'Utah Jazz',
      'Washington Wizards'
    ],
    'MLB': [
      'Arizona Diamondbacks',
      'Atlanta Braves',
      'Baltimore Orioles',
      'Boston Red Sox',
      'Chicago Cubs',
      'Chicago White Sox',
      'Cincinnati Reds',
      'Cleveland Guardians',
      'Colorado Rockies',
      'Detroit Tigers',
      'Houston Astros',
      'Kansas City Royals',
      'Los Angeles Angels',
      'Los Angeles Dodgers',
      'Miami Marlins',
      'Milwaukee Brewers',
      'Minnesota Twins',
      'New York Mets',
      'New York Yankees',
      'Oakland Athletics',
      'Philadelphia Phillies',
      'Pittsburgh Pirates',
      'San Diego Padres',
      'San Francisco Giants',
      'Seattle Mariners',
      'St. Louis Cardinals',
      'Tampa Bay Rays',
      'Texas Rangers',
      'Toronto Blue Jays',
      'Washington Nationals'
    ],
    'NHL': [
      'Anaheim Ducks',
      'Arizona Coyotes',
      'Boston Bruins',
      'Buffalo Sabres',
      'Calgary Flames',
      'Carolina Hurricanes',
      'Chicago Blackhawks',
      'Colorado Avalanche',
      'Columbus Blue Jackets',
      'Dallas Stars',
      'Detroit Red Wings',
      'Edmonton Oilers',
      'Florida Panthers',
      'Los Angeles Kings',
      'Minnesota Wild',
      'Montreal Canadiens',
      'Nashville Predators',
      'New Jersey Devils',
      'New York Islanders',
      'New York Rangers',
      'Ottawa Senators',
      'Philadelphia Flyers',
      'Pittsburgh Penguins',
      'San Jose Sharks',
      'Seattle Kraken',
      'St. Louis Blues',
      'Tampa Bay Lightning',
      'Toronto Maple Leafs',
      'Vancouver Canucks',
      'Vegas Golden Knights',
      'Washington Capitals',
      'Winnipeg Jets'
    ],
  };

  // Override initState to initialize the widget state
  @override
  void initState() {
    // Call parent initState
    super.initState();
    // Load existing user profile data
    _loadUserProfile();
  }

  // Async method to load existing user profile data
  Future<void> _loadUserProfile() async {
    try {
      // Get current user profile from auth service
      final profile = await _authService.getCurrentUserProfile();
      // Check if profile exists
      if (profile != null) {
        // Update UI with existing profile data
        setState(() {
          // Set username from profile or empty string
          _usernameController.text = profile['username'] ?? '';
          // Set full name from profile or empty string
          _fullNameController.text = profile['full_name'] ?? '';
          // Set bio from profile or empty string
          _bioController.text = profile['bio'] ?? '';
          // Add favorite teams from profile if they exist
          if (profile['favorite_teams'] != null) {
            _selectedTeams.addAll(List<String>.from(profile['favorite_teams']));
          }
        });
      }
    } catch (e) {
      // Log error if profile loading fails
      print('Error loading profile: $e');
    }
  }

  // Async method to complete the onboarding process
  Future<void> _completeOnboarding() async {
    // Check if username is provided (required field)
    if (_usernameController.text.isEmpty) {
      // Show error message if username is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required')),
      );
      return;
    }

    // Set loading state to true and update UI
    setState(() => _isLoading = true);

    try {
      // Check authentication state first
      final user = _authService.currentUser;
      final session = _authService.currentSession;
      
      // Debug log user and session information
      print('User in onboarding completion: $user');
      print('Session in onboarding completion: $session');
      
      // Validate user authentication
      if (user == null || session == null) {
        // Debug authentication state
        await _authService.debugAuthState();
        throw 'User not authenticated. Please sign in again.';
      }

      // Refresh session to ensure it's still valid
      try {
        // Attempt to refresh the session
        await _authService.supabase.auth.refreshSession();
        // Log successful session refresh
        print('Session refreshed successfully');
      } catch (refreshError) {
        // Log session refresh error
        print('Session refresh failed: $refreshError');
        throw 'Session expired. Please sign in again.';
      }

      // Update profile
      await _authService.updateProfile(
        username: _usernameController.text,
        fullName: _fullNameController.text,
        bio: _bioController.text,
        favoriteTeams: _selectedTeams.toList(),
      );

      // Complete onboarding
      await _authService.completeOnboarding();

      // Navigate to main app if widget is still mounted
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      // Log onboarding completion error
      print('Onboarding completion error: $e');
      // Show error message if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            // Add sign-in action if authentication error
            action: e.toString().contains('sign in again') 
                ? SnackBarAction(
                    label: 'Sign In',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/auth/login');
                    },
                  )
                : null,
          ),
        );
      }
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Method to build the welcome page widget
  Widget _buildWelcomePage() {
    // Return column with welcome content
    return Column(
      // Center the column contents
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sports icon
        const Icon(Icons.sports, size: 80, color: Colors.blue),
        // Spacing after icon
        const SizedBox(height: 24),
        // Welcome title text
        const Text(
          'Welcome to WagerLoop!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Spacing after title
        const SizedBox(height: 16),
        // Welcome subtitle text
        const Text(
          'Let\'s set up your profile and select your favorite teams',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Method to build the profile information page widget
  Widget _buildProfileInfoPage() {
    // Return scrollable view with profile form
    return SingleChildScrollView(
      // Padding around the content
      padding: const EdgeInsets.all(24),
      // Column to arrange form elements vertically
      child: Column(
        // Left align the column contents
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile creation title
          const Text(
            'Create your profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Spacing after title
          const SizedBox(height: 24),
          // Username input field
          TextFormField(
            // Set text controller for username input
            controller: _usernameController,
            // Set text color to white
            style: const TextStyle(color: Colors.white),
            // Configure field appearance
            decoration: const InputDecoration(
              // Field label with asterisk indicating required field
              labelText: 'Username*',
              // Label color
              labelStyle: TextStyle(color: Colors.grey),
              // Prefix icon
              prefixIcon: Icon(Icons.person, color: Colors.grey),
            ),
          ),
          // Spacing between username and full name fields
          const SizedBox(height: 16),
          // Full name input field
          TextFormField(
            // Set text controller for full name input
            controller: _fullNameController,
            // Set text color to white
            style: const TextStyle(color: Colors.white),
            // Configure field appearance
            decoration: const InputDecoration(
              // Field label
              labelText: 'Full Name',
              // Label color
              labelStyle: TextStyle(color: Colors.grey),
              // Prefix icon
              prefixIcon: Icon(Icons.badge, color: Colors.grey),
            ),
          ),
          // Spacing between full name and bio fields
          const SizedBox(height: 16),
          // Bio input field
          TextFormField(
            // Set text controller for bio input
            controller: _bioController,
            // Set text color to white
            style: const TextStyle(color: Colors.white),
            // Allow multiple lines for bio
            maxLines: 3,
            // Configure field appearance
            decoration: const InputDecoration(
              // Field label
              labelText: 'Bio',
              // Label color
              labelStyle: TextStyle(color: Colors.grey),
              // Prefix icon
              prefixIcon: Icon(Icons.edit, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Method to build the team selection page widget
  Widget _buildTeamSelectionPage() {
    // Return padded column with team selection interface
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        // Left align the column contents
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team selection title
          Text(
            'Select your favorite teams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Spacing after title
          SizedBox(height: 24),
          // Expanded list view to show teams
          Expanded(
            child: ListView.builder(
              // Number of sports leagues
              itemCount: _teams.length,
              // Builder function for each league
              itemBuilder: (context, index) {
                // Get league entry at current index
                final league = _teams.entries.elementAt(index);
                // Return column with league and teams
                return Column(
                  // Left align the column contents
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // League name text
                    Text(
                      league.key,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Spacing after league name
                    SizedBox(height: 8),
                    // Wrap widget to arrange team chips
                    Wrap(
                      // Horizontal spacing between chips
                      spacing: 8,
                      // Vertical spacing between chip rows
                      runSpacing: 8,
                      // Map teams to filter chips
                      children: league.value.map((team) {
                        // Check if team is selected
                        final isSelected = _selectedTeams.contains(team);
                        // Return filter chip for team
                        return FilterChip(
                          // Set selected state
                          selected: isSelected,
                          // Team name label
                          label: Text(
                            team,
                            style: TextStyle(
                              // Text color based on selection state
                              color: isSelected ? Colors.black : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Selected chip color
                          selectedColor: Colors.green,
                          // Unselected chip color
                          backgroundColor: Colors.grey[700],
                          // Handle selection change
                          onSelected: (selected) {
                            // Update selected teams set
                            setState(() {
                              // Add or remove team based on selection
                              if (selected) {
                                _selectedTeams.add(team);
                              } else {
                                _selectedTeams.remove(team);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    // Spacing after each league
                    SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Override build method to construct the widget tree
  @override
  Widget build(BuildContext context) {
    // Return scaffold with black background
    return Scaffold(
      backgroundColor: Colors.black,
      // Safe area to avoid system UI overlaps
      body: SafeArea(
        // Column to arrange main UI elements
        child: Column(
          children: [
            // Progress indicator
            // Linear progress indicator showing current page
            LinearProgressIndicator(
              // Calculate progress based on current page
              value: (_currentPage + 1) / 3,
              // Background color
              backgroundColor: Colors.grey[900],
              // Progress color
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

            // Page content
            // Expanded page view for onboarding pages
            Expanded(
              child: PageView(
                // Set page controller
                controller: _pageController,
                // Handle page changes
                onPageChanged: (page) {
                  // Update current page state
                  setState(() => _currentPage = page);
                },
                // List of onboarding pages
                children: [
                  // Welcome page
                  _buildWelcomePage(),
                  // Profile information page
                  _buildProfileInfoPage(),
                  // Team selection page
                  _buildTeamSelectionPage(),
                ],
              ),
            ),

            // Navigation buttons
            // Padded row for navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                // Space buttons apart
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (shown if not on first page)
                  if (_currentPage > 0)
                    Flexible(
                      child: ElevatedButton(
                        // Navigate to previous page
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        // Button styling
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                        ),
                        // Button text
                        child: const Text('Back'),
                      ),
                    ),
                  // Next button (shown if not on last page)
                  if (_currentPage < 2)
                    Flexible(
                      child: ElevatedButton(
                        // Navigate to next page
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        // Button styling
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        // Button text
                        child: const Text('Next'),
                      ),
                    ),
                  // Finish button (shown only on last page)
                  if (_currentPage == 2)
                    Flexible(
                      child: ElevatedButton(
                        // Complete onboarding, disabled when loading
                        onPressed: _isLoading ? null : _completeOnboarding,
                        // Button styling
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        // Button content - loading indicator or text
                        child: _isLoading
                            ? const DiceLoadingSmall(size: 20)
                            : const Text('Finish'),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Override dispose method to clean up resources
  @override
  void dispose() {
    // Dispose page controller to prevent memory leaks
    _pageController.dispose();
    // Dispose username controller to prevent memory leaks
    _usernameController.dispose();
    // Dispose full name controller to prevent memory leaks
    _fullNameController.dispose();
    // Dispose bio controller to prevent memory leaks
    _bioController.dispose();
    // Call super dispose to complete cleanup
    super.dispose();
  }
}
