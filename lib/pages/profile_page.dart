import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_config.dart';
import '../models/post.dart';
import 'package:timeago/timeago.dart' as timeago;
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

  // Posts data
  List<Post> _userPosts = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserPosts();
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

  Widget _buildTeamsList() {
    final favoriteTeams = _userData?['favorite_teams'] as List<dynamic>? ?? [];
    if (favoriteTeams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No favorite teams selected',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: favoriteTeams
          .map((team) => Chip(
                label: Text(team),
                backgroundColor: Colors.green.withOpacity(0.2), // Changed from blue to green
                labelStyle: const TextStyle(color: Colors.white),
              ))
          .toList(),
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
                Text(
                  post.content,
                  style: const TextStyle(color: Colors.white),
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
      body: SingleChildScrollView(
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
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green, // Changed from blue to green
                        child: Text(
                          _userData?['username']?[0].toUpperCase() ?? 'A',
                          style: TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _userData?['username'] ?? '',
                        style: TextStyle(
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
                                (_userData?['followers_count'] ?? 0).toString(),
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
                                (_userData?['following_count'] ?? 0).toString(),
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
                Text(
                  'Favorite Teams',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
