import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';
import '../services/follow_notifier.dart';
import '../services/image_upload_service.dart';
import '../models/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'followers_list_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  String? _error;

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
  List<Post> _userPosts = [];
  bool _isLoadingPosts = false;

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
    _loadUserProfile();
    _loadUserPosts();
    _loadFollowerCounts();
    
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

      print('Starting image upload for user: $userId');
      print('Image size: ${bytes.length} bytes');

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
      
      // Reload profile to show new image
      await _loadUserProfile();
      print('Profile after reload: \n');
      print(_userData);
      print('Avatar URL after reload: ' + (_userData?['avatar_url']?.toString() ?? 'null'));

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
        setState(() => _userPosts = posts);
      }
    } catch (e) {
      print('Error loading user posts: $e');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
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
      return const Center(child: CircularProgressIndicator(color: Colors.green)); // Changed to green
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
        return Card(
          color: Colors.grey[700], // Changed from grey[900] to grey[700]
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header with delete button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.content,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _deletePost(post.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      timeago.format(post.timestamp, locale: 'en'),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          post.likes.toString(),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.comment, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          post.comments.length.toString(),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
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
        backgroundColor: Colors.grey[800], // Changed from black to gray
        appBar: AppBar(
          backgroundColor: Colors.grey[800], // Changed from black to gray
          title: Image.asset(
            'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.green)), // Changed to green
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[800], // Changed from black to gray
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Changed from black to gray
        title: Image.asset(
          'assets/9d514000-7637-4e02-bc87-df46fcb2fe36_removalai_preview.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: Colors.green, // Changed from white to green
            ),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green,
                              backgroundImage: _userData?['avatar_url'] != null
                                  ? NetworkImage(_userData!['avatar_url'])
                                  : null,
                              child: _userData?['avatar_url'] == null
                                  ? Text(
                                      _userData?['username']?[0].toUpperCase() ?? 'A',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
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

                // Profile Fields
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
                _buildTeamsList(),

                SizedBox(height: 32),
                Text(
                  'My Posts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildPostsList(),

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
      ),
    );
  }

  @override
  void dispose() {
    _followNotifier.removeListener(_onFollowChanged);
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
