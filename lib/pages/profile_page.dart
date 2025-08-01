import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';
import '../services/follow_notifier.dart';
import '../services/image_upload_service.dart';
import '../models/post.dart';
import '../models/pick_post.dart';
import '../models/comment.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/picks_display_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'followers_list_page.dart';
import 'dart:convert'; // Added for jsonDecode

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final _authService = AuthService();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  String? _error;

  // Tab controller for posts/comments/likes tabs
  late TabController _tabController;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _cloudsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _cloudsAnimation;

  // User data
  Map<String, dynamic>? _userData;
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();

  // Follower counts
  int _followersCount = 0;
  int _followingCount = 0;
  final FollowNotifier _followNotifier = FollowNotifier();

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  // Teams data
  List<dynamic> _userPosts = []; // Can contain both Post and PickPost objects
  bool _isLoadingPosts = false;

  // Add state for liked posts
  List<dynamic> _likedPosts = [];
  bool _isLoadingLikedPosts = false;

  // Add state for user comments
  List<Map<String, dynamic>> _userComments = [];
  bool _isLoadingComments = false;
  bool _isDeletingComment = false;

  // Available teams for selection
  final Map<String, List<String>> _availableTeams = {
    'NFL': [
      'Arizona Cardinals', 'Atlanta Falcons', 'Baltimore Ravens', 'Buffalo Bills',
      'Carolina Panthers', 'Chicago Bears', 'Cincinnati Bengals', 'Cleveland Browns',
      'Dallas Cowboys', 'Denver Broncos', 'Detroit Lions', 'Green Bay Packers',
      'Houston Texans', 'Indianapolis Colts', 'Jacksonville Jaguars', 'Kansas City Chiefs',
      'Las Vegas Raiders', 'Los Angeles Chargers', 'Los Angeles Rams', 'Miami Dolphins',
      'Minnesota Vikings', 'New England Patriots', 'New Orleans Saints', 'New York Giants',
      'New York Jets', 'Philadelphia Eagles', 'Pittsburgh Steelers', 'San Francisco 49ers',
      'Seattle Seahawks', 'Tampa Bay Buccaneers', 'Tennessee Titans', 'Washington Commanders'
    ],
    'NBA': [
      'Atlanta Hawks', 'Boston Celtics', 'Brooklyn Nets', 'Charlotte Hornets',
      'Chicago Bulls', 'Cleveland Cavaliers', 'Dallas Mavericks', 'Denver Nuggets',
      'Detroit Pistons', 'Golden State Warriors', 'Houston Rockets', 'Indiana Pacers',
      'LA Clippers', 'Los Angeles Lakers', 'Memphis Grizzlies', 'Miami Heat',
      'Milwaukee Bucks', 'Minnesota Timberwolves', 'New Orleans Pelicans', 'New York Knicks',
      'Oklahoma City Thunder', 'Orlando Magic', 'Philadelphia 76ers', 'Phoenix Suns',
      'Portland Trail Blazers', 'Sacramento Kings', 'San Antonio Spurs', 'Toronto Raptors',
      'Utah Jazz', 'Washington Wizards'
    ],
    'MLB': [
      'Arizona Diamondbacks', 'Atlanta Braves', 'Baltimore Orioles', 'Boston Red Sox',
      'Chicago Cubs', 'Chicago White Sox', 'Cincinnati Reds', 'Cleveland Guardians',
      'Colorado Rockies', 'Detroit Tigers', 'Houston Astros', 'Kansas City Royals',
      'Los Angeles Angels', 'Los Angeles Dodgers', 'Miami Marlins', 'Milwaukee Brewers',
      'Minnesota Twins', 'New York Mets', 'New York Yankees', 'Oakland Athletics',
      'Philadelphia Phillies', 'Pittsburgh Pirates', 'San Diego Padres', 'San Francisco Giants',
      'Seattle Mariners', 'St. Louis Cardinals', 'Tampa Bay Rays', 'Texas Rangers',
      'Toronto Blue Jays', 'Washington Nationals'
    ],
    'NHL': [
      'Anaheim Ducks', 'Arizona Coyotes', 'Boston Bruins', 'Buffalo Sabres',
      'Calgary Flames', 'Carolina Hurricanes', 'Chicago Blackhawks', 'Colorado Avalanche',
      'Columbus Blue Jackets', 'Dallas Stars', 'Detroit Red Wings', 'Edmonton Oilers',
      'Florida Panthers', 'Los Angeles Kings', 'Minnesota Wild', 'Montreal Canadiens',
      'Nashville Predators', 'New Jersey Devils', 'New York Islanders', 'New York Rangers',
      'Ottawa Senators', 'Philadelphia Flyers', 'Pittsburgh Penguins', 'San Jose Sharks',
      'Seattle Kraken', 'St Louis Blues', 'Tampa Bay Lightning', 'Toronto Maple Leafs',
      'Vancouver Canucks', 'Vegas Golden Knights', 'Washington Capitals', 'Winnipeg Jets'
    ],
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _cloudsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _cloudsAnimation = Tween<double>(
      begin: -30.0,
      end: 30.0,
    ).animate(CurvedAnimation(
      parent: _cloudsController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _backgroundController.repeat();
    _floatingController.repeat(reverse: true);
    _cloudsController.repeat(reverse: true);
    
    _loadUserProfile();
    _loadUserPosts();
    _loadFollowerCounts();
    _loadLikedPosts();
    _loadUserComments();
    // Listen for follow events to update counts instantly
    _followNotifier.addListener(_onFollowChanged);
  }

  void _onFollowChanged() {
    // Reload follower counts when someone is followed/unfollowed
    _loadFollowerCounts();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh counts when widget updates
    _loadFollowerCounts();
  }

  Future<void> _loadFollowerCounts() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Load followers and following counts
      final followers = await _authService.getFollowers(userId);
      final following = await _authService.getFollowing(userId);

      setState(() {
        _followersCount = followers.length;
        _followingCount = following.length;
      });
    } catch (e) {
      print('Error loading follower counts: $e');
      // Keep counts as 0 if there's an error
    }
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadUserProfile(),
      _loadUserPosts(),
      _loadFollowerCounts(),
      _loadLikedPosts(),
      _loadUserComments(),
    ]);
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // First check if we have storage access
      final hasAccess = await ImageUploadService.checkStorageAccess();
      if (!hasAccess) {
        throw 'Unable to access storage. Please check your connection and try again.';
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await image.readAsBytes();
      final userId = _authService.currentUser?.id;
      
      if (userId == null) {
        throw 'User not authenticated';
      }

      // Delete old image if exists
      final oldAvatarUrl = _userData?['avatar_url'];
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        print('Deleting old avatar: $oldAvatarUrl');
        await ImageUploadService.deleteProfileImage(oldAvatarUrl);
      }

      // Upload new image
      String? imageUrl;
      try {
        imageUrl = await ImageUploadService.uploadProfileImage(bytes, userId);
        print('Image uploaded, got URL: ' + (imageUrl ?? 'null'));
      } catch (e) {
        print('Primary upload failed, trying fallback method: $e');
        imageUrl = await ImageUploadService.uploadProfileImageFallback(bytes, userId);
        print('Fallback image uploaded, got URL: ' + (imageUrl ?? 'null'));
      }
      
      if (imageUrl == null || imageUrl.isEmpty) {
        throw 'Failed to get image URL from upload';
      }

      print('Image uploaded successfully: $imageUrl');

      // Update profile with new image URL
      await _authService.updateProfile(avatarUrl: imageUrl);
      
      // Add a longer delay to ensure database is updated and cache is cleared
      await Future.delayed(const Duration(seconds: 2));
      
      // Force refresh the profile data
      await _loadUserProfile();
      
      // Force a rebuild of the widget tree
      if (mounted) {
        setState(() {});
      }
      
      print('=== UPLOAD COMPLETE DEBUG ===');
      print('Final uploaded image URL: $imageUrl');
      print('Profile after reload: $_userData');
      print('Avatar URL after reload: ${_userData?['avatar_url']}');
      print('========================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StorageException catch (e) {
      print('Storage exception: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage error: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[700],
        title: const Text(
          'Update Profile Picture',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage();
              },
            ),
            if (_userData?['avatar_url'] != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Picture',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeProfilePicture();
                },
              ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.orange),
              title: const Text(
                'Run Storage Diagnostics',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _runStorageDiagnostics();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runStorageDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.grey,
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(width: 16),
            Text('Running storage diagnostics...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final result = await ImageUploadService.diagnoseStorageIssue();
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show results dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[700],
            title: const Text(
              'Storage Diagnostics',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDiagnosticItem('Authentication', result['isAuthenticated']),
                  _buildDiagnosticItem('Bucket Access', result['canAccessBucket']),
                  _buildDiagnosticItem('List Files', result['canListFiles']),
                  _buildDiagnosticItem('Test Upload', result['canUploadTest']),
                  
                  if (result['errors'].isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Errors:',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    ...(result['errors'] as List).map<Widget>((error) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('• $error', style: const TextStyle(color: Colors.red)),
                      )
                    ),
                  ],
                  
                  if (result['suggestions'].isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Suggestions:',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    ...(result['suggestions'] as List).map<Widget>((suggestion) => 
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text('• $suggestion', style: const TextStyle(color: Colors.blue)),
                      )
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Diagnostic failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDiagnosticItem(String label, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    try {
      setState(() => _isUploadingImage = true);

      final oldAvatarUrl = _userData?['avatar_url'];
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await ImageUploadService.deleteProfileImage(oldAvatarUrl);
      }

      // Update profile to remove avatar URL
      await _authService.updateProfile(avatarUrl: null);
      
      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _authService.getCurrentUserProfile();
      final user = _authService.currentUser;

      if (profile != null && user != null) {
        setState(() {
          _userData = profile;
          _usernameController.text = profile['username'] ?? '';
          _fullNameController.text = profile['full_name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to load profile');
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showTeamSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[700],
          title: const Text(
            'Select Favorite Teams',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(text: 'NFL'),
                      Tab(text: 'NBA'),
                      Tab(text: 'MLB'),
                      Tab(text: 'NHL'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _availableTeams.entries.map((entry) {
                        return _buildTeamSelectionList(entry.key, entry.value, setDialogState);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelectionList(String league, List<String> teams, StateSetter setDialogState) {
    final favoriteTeams = (_userData?['favorite_teams'] as List<dynamic>?) ?? [];
    
    return ListView.builder(
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        final isSelected = favoriteTeams.contains(team);
        
        return CheckboxListTile(
          title: Text(
            team,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          value: isSelected,
          activeColor: Colors.green,
          checkColor: Colors.white,
          onChanged: (bool? value) {
            _toggleFavoriteTeam(team, value ?? false);
            // Update the dialog state immediately
            setDialogState(() {});
          },
        );
      },
    );
  }

  Future<void> _toggleFavoriteTeam(String team, bool isSelected) async {
    try {
      List<dynamic> currentTeams = List.from(_userData?['favorite_teams'] ?? []);
      
      if (isSelected && !currentTeams.contains(team)) {
        currentTeams.add(team);
      } else if (!isSelected && currentTeams.contains(team)) {
        currentTeams.remove(team);
      }

      // Update local state IMMEDIATELY for instant UI feedback
      setState(() {
        _userData!['favorite_teams'] = currentTeams;
      });

      // Update in database
      await _authService.updateFavoriteTeams(currentTeams);
    } catch (e) {
      // If database update fails, revert the local state
      await _loadUserProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorite teams: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final posts = await _socialFeedService.fetchUserPosts(user.id);
        
        // Update like and repost status for current user
        for (final post in posts) {
          final postId = post is Post ? post.id : (post as PickPost).id;
          try {
            // Check if user liked this post
            final likeExists = await _authService.supabase
                .from('likes')
                .select()
                .eq('post_id', postId)
                .eq('user_id', user.id)
                .maybeSingle();
            
            if (post is Post) {
              post.isLiked = likeExists != null;
            } else if (post is PickPost) {
              post.isLiked = likeExists != null;
            }

            // Check if user reposted this post
            final repostExists = await _authService.supabase
                .from('reposts')
                .select()
                .eq('post_id', postId)
                .eq('user_id', user.id)
                .maybeSingle();
            
            if (post is Post) {
              post.isReposted = repostExists != null;
            } else if (post is PickPost) {
              post.isReposted = repostExists != null;
            }
          } catch (e) {
            print('Error fetching post stats for $postId: $e');
          }
        }
        
        setState(() => _userPosts = posts);
      }
    } catch (e) {
      print('Error loading user posts: $e');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _toggleLike(dynamic post) async {
    // Optimistically update UI
    setState(() {
      if (post is Post) {
        post.isLiked = !post.isLiked;
        post.likes += post.isLiked ? 1 : -1;
      } else if (post is PickPost) {
        post.isLiked = !post.isLiked;
        post.likes += post.isLiked ? 1 : -1;
      }
    });

    try {
      final postId = post is Post ? post.id : (post as PickPost).id;
      await _socialFeedService.toggleLike(postId);
    } catch (e) {
      // Revert on error
      setState(() {
        if (post is Post) {
          post.isLiked = !post.isLiked;
          post.likes += post.isLiked ? 1 : -1;
        } else if (post is PickPost) {
          post.isLiked = !post.isLiked;
          post.likes += post.isLiked ? 1 : -1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like. Please try again.')),
      );
      print('Error toggling like: $e');
    }
  }

  Future<void> _toggleRepost(dynamic post) async {
    // Optimistically update UI
    setState(() {
      if (post is Post) {
        post.isReposted = !post.isReposted;
        post.reposts += post.isReposted ? 1 : -1;
      } else if (post is PickPost) {
        post.isReposted = !post.isReposted;
        post.reposts += post.isReposted ? 1 : -1;
      }
    });

    try {
      final postId = post is Post ? post.id : (post as PickPost).id;
      await _socialFeedService.toggleRepost(postId);
    } catch (e) {
      // Revert on error
      setState(() {
        if (post is Post) {
          post.isReposted = !post.isReposted;
          post.reposts += post.isReposted ? 1 : -1;
        } else if (post is PickPost) {
          post.isReposted = !post.isReposted;
          post.reposts += post.isReposted ? 1 : -1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update repost. Please try again.')),
      );
      print('Error toggling repost: $e');
    }
  }

  // Animated background methods
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            _buildPrimaryOrbitalSystem(),
            _buildSecondaryAmbientLayer(),
            _buildTertiaryDetailLayer(),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryOrbitalSystem() {
    return Positioned.fill(
      child: CustomPaint(
        painter: OrbitalPainter(
          animation: _backgroundAnimation.value,
          color: Colors.green.withOpacity(0.03),
          strokeWidth: 1.5,
          radius: 120,
        ),
      ),
    );
  }

  Widget _buildSecondaryAmbientLayer() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlePainter(
          animation: _backgroundAnimation.value,
          particleCount: 25,
          color: Colors.white.withOpacity(0.02),
        ),
      ),
    );
  }

  Widget _buildTertiaryDetailLayer() {
    return Positioned.fill(
      child: CustomPaint(
        painter: FlowingLinesPainter(
          animation: _backgroundAnimation.value,
          color: Colors.green.withOpacity(0.015),
          lineCount: 3,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 120, // Fixed height to control the overlap
      child: Stack(
        children: [
          // Turf background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/turfBackground.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          // Football laces bar positioned to overlap header turf bottom
          Positioned(
            bottom: 0, // Moved down just a tiny bit more
            left: -10, // Extended slightly to the left
            right: -10, // Extended slightly to the right
            child: Opacity(
              opacity: 0.65, // More transparent while still visible
              child: Container(
                height: 28, // Increased height slightly
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/lacesbar.png'),
                    fit: BoxFit.fitWidth,
                    repeat: ImageRepeat.repeatX,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.grey,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        username: _usernameController.text,
        fullName: _fullNameController.text,
        bio: _bioController.text,
      );

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      await _loadUserProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[700],
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _socialFeedService.deletePost(postId);
        
        // Remove from local list
        setState(() {
          _userPosts.removeWhere((post) => post.id == postId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTeamsList() {
    final favoriteTeams = _userData?['favorite_teams'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Teams',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showTeamSelectionDialog,
              child: Text(
                'Edit',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (favoriteTeams.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No favorite teams selected',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: favoriteTeams
                .map((team) => Chip(
                      label: Text(
                        team,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.grey[600],
                      deleteIcon: const Icon(
                        Icons.close, 
                        size: 18, 
                        color: Colors.white70,
                      ),
                      onDeleted: () => _toggleFavoriteTeam(team, false),
                      side: BorderSide(
                        color: Colors.grey[500]!,
                        width: 1,
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (_userPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No posts yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        
        // Extract common properties
        final content = post is Post ? post.content : (post as PickPost).content;
        final timestamp = post is Post ? post.timestamp : (post as PickPost).timestamp;
        final likes = post is Post ? post.likes : (post as PickPost).likes;
        final comments = post is Post ? post.comments : (post as PickPost).comments;
        final reposts = post is Post ? post.reposts : (post as PickPost).reposts;
        final isLiked = post is Post ? post.isLiked : (post as PickPost).isLiked;
        final isReposted = post is Post ? post.isReposted : (post as PickPost).isReposted;
        final postId = post is Post ? post.id : (post as PickPost).id;
        final avatarUrl = post is Post ? post.avatarUrl : (post as PickPost).avatarUrl;
        final username = post is Post ? post.username : (post as PickPost).username;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[750],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      avatarUrl: avatarUrl,
                      username: username,
                      radius: 24,
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(timestamp),
                            style: TextStyle(
                              color: Colors.grey[400], 
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _deletePost(postId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                
                // Show picks if this is a PickPost
                if (post is PickPost && post.hasPicks) ...[
                  const SizedBox(height: 20),
                  PicksDisplayWidget(
                    picks: post.picks,
                    showParlayBadge: true,
                    compact: false,
                  ),
                ],
                
                const SizedBox(height: 16),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: likes.toString(),
                        onTap: () => _toggleLike(post),
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: comments.length.toString(),
                        onTap: () {
                          // TODO: Implement comment functionality
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.repeat,
                        label: reposts.toString(),
                        onTap: () => _toggleRepost(post),
                        color: isReposted ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fetch liked posts for the current user
  Future<void> _loadLikedPosts() async {
    setState(() => _isLoadingLikedPosts = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Query posts that the user has liked
        final response = await _authService.supabase
            .from('likes')
            .select('post_id, post:posts(*)')
            .eq('user_id', user.id);
        final likedPostsRaw = response as List<dynamic>;
        final posts = <dynamic>[];
        for (final item in likedPostsRaw) {
          final postData = item['post'];
          if (postData == null) continue;
          final postType = postData['post_type'] ?? 'text';
          // Fetch counts for this post
          final postId = postData['id'];
          final likesCountResp = await _authService.supabase
              .from('likes')
              .select('id')
              .eq('post_id', postId);
          final repostsCountResp = await _authService.supabase
              .from('reposts')
              .select('id')
              .eq('post_id', postId);
          final commentsCountResp = await _authService.supabase
              .from('comments')
              .select('id')
              .eq('post_id', postId);
          final likesCount = likesCountResp.length;
          final repostsCount = repostsCountResp.length;
          final commentsCount = commentsCountResp.length;
          
          if (postType == 'pick' && postData['picks_data'] != null) {
            List<Pick> picks = [];
            try {
              final picksJson = jsonDecode(postData['picks_data']);
              picks = (picksJson as List).map((pickJson) => Pick.fromJson(pickJson)).toList();
            } catch (e) {
              print('Error parsing picks data: $e');
            }
            posts.add(PickPost(
              id: postData['id'],
              userId: postData['profile_id'] ?? postData['user_id'] ?? '',
              username: postData['username'] ?? 'Anonymous',
              content: postData['content'],
              timestamp: DateTime.parse(postData['created_at']).toLocal(),
              likes: likesCount,
              comments: List.generate(commentsCount, (index) => Comment(
                id: 'placeholder_$index',
                username: 'placeholder',
                content: 'placeholder',
                timestamp: DateTime.now(),
              )),
              reposts: repostsCount,
              isLiked: true,
              isReposted: false,
              avatarUrl: postData['avatar_url'],
              picks: picks,
            ));
          } else {
            posts.add(Post(
              id: postData['id'],
              userId: postData['profile_id'] ?? postData['user_id'] ?? '',
              username: postData['username'] ?? 'Anonymous',
              content: postData['content'],
              timestamp: DateTime.parse(postData['created_at']).toLocal(),
              likes: likesCount,
              comments: List.generate(commentsCount, (index) => Comment(
                id: 'placeholder_$index',
                username: 'placeholder',
                content: 'placeholder',
                timestamp: DateTime.now(),
              )),
              reposts: repostsCount,
              isLiked: true,
              isReposted: false,
              avatarUrl: postData['avatar_url'],
            ));
          }
        }
        setState(() => _likedPosts = posts);
      }
    } catch (e) {
      print('Error loading liked posts: $e');
    } finally {
      setState(() => _isLoadingLikedPosts = false);
    }
  }

  // Fetch user comments
  Future<void> _loadUserComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final comments = await _socialFeedService.fetchUserComments(user.id);
        setState(() => _userComments = comments);
      }
    } catch (e) {
      print('Error loading user comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  // Show delete comment confirmation dialog
  Future<void> _showDeleteCommentDialog(String commentId, int commentIndex) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: const Text(
            'Delete Comment',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _isDeletingComment ? null : () async {
                Navigator.of(context).pop();
                await _deleteComment(commentId, commentIndex);
              },
              child: _isDeletingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Delete comment
  Future<void> _deleteComment(String commentId, int commentIndex) async {
    setState(() => _isDeletingComment = true);
    try {
      await _socialFeedService.deleteComment(commentId);
      
      // Remove comment from local list
      setState(() {
        _userComments.removeAt(commentIndex);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDeletingComment = false);
    }
  }

  Widget _buildLikedPostsList() {
    if (_isLoadingLikedPosts) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_likedPosts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No liked posts yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _likedPosts.length,
      itemBuilder: (context, index) {
        final post = _likedPosts[index];
        final content = post is Post ? post.content : (post as PickPost).content;
        final timestamp = post is Post ? post.timestamp : (post as PickPost).timestamp;
        final likes = post is Post ? post.likes : (post as PickPost).likes;
        final comments = post is Post ? post.comments : (post as PickPost).comments;
        final reposts = post is Post ? post.reposts : (post as PickPost).reposts;
        final isLiked = true;
        final isReposted = post is Post ? post.isReposted : (post as PickPost).isReposted;
        final avatarUrl = post is Post ? post.avatarUrl : (post as PickPost).avatarUrl;
        final username = post is Post ? post.username : (post as PickPost).username;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[750],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      avatarUrl: avatarUrl,
                      username: username,
                      radius: 24,
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(timestamp),
                            style: TextStyle(
                              color: Colors.grey[400], 
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                
                if (post is PickPost && post.hasPicks) ...[
                  const SizedBox(height: 20),
                  PicksDisplayWidget(
                    picks: post.picks,
                    showParlayBadge: true,
                    compact: false,
                  ),
                ],
                
                const SizedBox(height: 16),
                // Actions
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.favorite,
                        label: likes.toString(),
                        onTap: () {},
                        color: Colors.red,
                      ),
                      _buildActionButton(
                        icon: Icons.comment_outlined,
                        label: comments.length.toString(),
                        onTap: () {},
                      ),
                      _buildActionButton(
                        icon: Icons.repeat,
                        label: reposts.toString(),
                        onTap: () {},
                        color: isReposted ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsList() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator(color: Colors.green));
    }
    if (_userComments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No comments yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        final comment = _userComments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[750],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment header with delete button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment['content'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteCommentDialog(comment['id'], index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Original post info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800]?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(
                            avatarUrl: comment['post_author_avatar'],
                            username: comment['post_author'] ?? 'Anonymous',
                            radius: 16,
                            backgroundColor: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['post_author'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: comment['post_type'] == 'pick' 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: comment['post_type'] == 'pick' 
                                    ? Colors.green.withOpacity(0.5)
                                    : Colors.blue.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              comment['post_type'] == 'pick' ? 'PICK' : 'POST',
                              style: TextStyle(
                                color: comment['post_type'] == 'pick' 
                                    ? Colors.green
                                    : Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment['post_content'],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Comment timestamp
                Text(
                  timeago.format(DateTime.parse(comment['created_at'])),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/turfBackground.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.darken,
              ),
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/turfBackground.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned.fill(
              child: _buildAnimatedBackground(),
            ),
            // Main content
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: RefreshIndicator(
                      onRefresh: _refreshProfile,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Header
                          SliverToBoxAdapter(
                            child: _buildHeader(),
                          ),
                          
                          // Profile content
                          SliverToBoxAdapter(
                            child: Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerDialog,
                        child: Stack(
                          children: [
                            ProfileAvatar(
                              avatarUrl: _userData?['avatar_url'],
                              username: _userData?['username'] ?? 'Anonymous',
                              radius: 50,
                              backgroundColor: Colors.green,
                            ),
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[800]!, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userData?['username'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userData?['bio'] != null && _userData!['bio'].isNotEmpty && !_isEditing) ...[
                        const SizedBox(height: 8),
                        Text(
                          _userData?['bio'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Posts count
                      Expanded(
                        child: InkWell(
                          onTap: null, // Could navigate to posts list in future
                          child: Column(
                            children: [
                              Text(
                                _userPosts.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Posts',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Followers count
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersListPage(
                                  userId: _userData!['id'],
                                  isFollowers: true,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                _followersCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Followers',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Following count
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersListPage(
                                  userId: _userData!['id'],
                                  isFollowers: false,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                _followingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Following',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Profile Fields - Only show when editing
                if (_isEditing) ...[
                  Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _usernameController,
                    enabled: _isEditing,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _fullNameController,
                    enabled: _isEditing,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.badge, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    enabled: _isEditing,
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.info, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    enabled: false,
                    style: TextStyle(color: Colors.grey),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.email, color: Colors.grey),
                    ),
                  ),

                  SizedBox(height: 32),
                ],

                SizedBox(height: 32),
                _buildTeamsList(),

                SizedBox(height: 32),
                // Tabbed interface for Posts, Comments, and Likes
                Container(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(text: 'Posts'),
                          Tab(text: 'Comments/Replies'),
                          Tab(text: 'Likes'),
                        ],
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.green,
                      ),
                      SizedBox(
                        height: 400, // Fixed height for the tab content
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SingleChildScrollView(
                              child: _buildPostsList(),
                            ),
                            SingleChildScrollView(
                              child: _buildCommentsList(),
                            ),
                            SingleChildScrollView(
                              child: _buildLikedPostsList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                                    SizedBox(height: 32),
                                    ElevatedButton(
                                      onPressed: _signOut,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        minimumSize: Size(double.infinity, 50),
                                      ),
                                      child: Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Clouds positioned higher up with side-to-side animation
            Positioned(
              top: -40, // Moved up much higher
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _cloudsAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_cloudsAnimation.value, 0),
                    child: Opacity(
                      opacity: 0.9, // Less transparent, more visible
                      child: Image.asset(
                        'assets/clouds.png',
                        fit: BoxFit.cover,
                        height: 120, // Increased height further to compensate
                      ),
                    ),
                  );
                },
              ),
            ),
            // WagerLoop logo floating above clouds with animation
            Positioned(
              top: 50, // Same position as in header
              left: 24,
              right: 24,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Center(
                      child: Image.asset(
                        'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
                        height: 44,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Floating edit/save buttons
            Positioned(
              top: 50,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditing) ...[
                    // Cancel button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            // Reset form fields to original values
                            _usernameController.text = _userData?['username'] ?? '';
                            _fullNameController.text = _userData?['full_name'] ?? '';
                            _bioController.text = _userData?['bio'] ?? '';
                          });
                        },
                      ),
                    ),
                    // Save button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: _updateProfile,
                      ),
                    ),
                  ] else ...[
                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          setState(() => _isEditing = true);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _followNotifier.removeListener(_onFollowChanged);
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    
    // Dispose animation controllers
    _fadeController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _cloudsController.dispose();
    
    super.dispose();
  }
}

// Custom Painters for animated background
class OrbitalPainter extends CustomPainter {
  final double animation;
  final Color color;
  final double strokeWidth;
  final double radius;

  OrbitalPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw orbital circles
    for (int i = 0; i < 3; i++) {
      final orbitalRadius = radius + (i * 80);
      canvas.drawCircle(center, orbitalRadius, paint);
      
      // Draw orbiting dots
      final angle = animation + (i * pi / 2);
      final dotX = center.dx + cos(angle) * orbitalRadius;
      final dotY = center.dy + sin(angle) * orbitalRadius;
      
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()..color = color.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(OrbitalPainter oldDelegate) => animation != oldDelegate.animation;
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final int particleCount;
  final Color color;

  ParticlePainter({
    required this.animation,
    required this.particleCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      // Add floating motion
      final floatX = x + sin(animation + i) * 20;
      final floatY = y + cos(animation + i * 0.7) * 15;
      
      canvas.drawCircle(
        Offset(floatX, floatY),
        random.nextDouble() * 3 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => animation != oldDelegate.animation;
}

class FlowingLinesPainter extends CustomPainter {
  final double animation;
  final Color color;
  final int lineCount;

  FlowingLinesPainter({
    required this.animation,
    required this.color,
    required this.lineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < lineCount; i++) {
      final path = Path();
      final startY = (size.height / lineCount) * i + 50;
      
      path.moveTo(-50, startY);
      
      for (double x = -50; x < size.width + 50; x += 20) {
        final y = startY + sin((x / 100) + animation + (i * pi / 3)) * 30;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FlowingLinesPainter oldDelegate) => animation != oldDelegate.animation;
}


