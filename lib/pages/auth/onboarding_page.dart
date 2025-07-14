import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/dice_loading_widget.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _authService = AuthService();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form controllers
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final Set<String> _selectedTeams = {};

  // Sample teams data structure
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _usernameController.text = profile['username'] ?? '';
          _fullNameController.text = profile['full_name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          if (profile['favorite_teams'] != null) {
            _selectedTeams.addAll(List<String>.from(profile['favorite_teams']));
          }
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _completeOnboarding() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check authentication state first
      final user = _authService.currentUser;
      final session = _authService.currentSession;
      
      print('User in onboarding completion: $user');
      print('Session in onboarding completion: $session');
      
      if (user == null || session == null) {
        // Debug authentication state
        await _authService.debugAuthState();
        throw 'User not authenticated. Please sign in again.';
      }

      // Refresh session to ensure it's still valid
      try {
        await _authService.supabase.auth.refreshSession();
        print('Session refreshed successfully');
      } catch (refreshError) {
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

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      print('Onboarding completion error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildWelcomePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'Welcome to WagerLoop!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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

  Widget _buildProfileInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Username*',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.person, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.badge, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              labelStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.edit, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionPage() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your favorite teams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final league = _teams.entries.elementAt(index);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.key,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: league.value.map((team) {
                        final isSelected = _selectedTeams.contains(team);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            team,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selectedColor: Colors.green,
                          backgroundColor: Colors.grey[700],
                          onSelected: (selected) {
                            setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[900],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildProfileInfoPage(),
                  _buildTeamSelectionPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage < 2)
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  if (_currentPage == 2)
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
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

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
