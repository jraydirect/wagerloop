// lib/pages/community_details_page.dart
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/community_post.dart';
import '../models/community_post_comment.dart';
import '../services/supabase_config.dart';
import '../services/community_posts_service.dart';
import '../services/auth_service.dart';
import '../widgets/dice_loading_widget.dart';
import '../widgets/profile_avatar.dart';
import '../utils/loading_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class CommunityDetailsPage extends StatefulWidget {
  final String communityId;

  const CommunityDetailsPage({Key? key, required this.communityId}) : super(key: key);

  @override
  _CommunityDetailsPageState createState() => _CommunityDetailsPageState();
}

class _CommunityDetailsPageState extends State<CommunityDetailsPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _communityService = SupabaseConfig.communityService;
  final _communityPostsService = CommunityPostsService(SupabaseConfig.supabase);
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  Community? _community;
  List<Map<String, dynamic>> _members = [];
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _isMembersLoading = false;
  bool _isPostsLoading = false;
  bool _isCreatingPost = false;
  String? _error;
  int _selectedTabIndex = 0;

  // Post creation controllers
  final _postContentController = TextEditingController();
  CommunityPostType _selectedPostType = CommunityPostType.chat;
  Uint8List? _selectedMediaBytes;
  String? _selectedMediaMimeType;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCommunityDetails();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _postContentController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunityDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final community = await _communityService.getCommunityById(widget.communityId);
      
      setState(() {
        _community = community;
        _isLoading = false;
      });

      // Load members and posts after community details
      _loadMembers();
      _loadPosts();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isMembersLoading = true;
    });

    try {
      final members = await _communityService.getCommunityMembers(
        communityId: widget.communityId,
      );

      setState(() {
        _members = members;
        _isMembersLoading = false;
      });
    } catch (e) {
      setState(() {
        _isMembersLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load members: ${e.toString()}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isPostsLoading = true;
    });

    try {
      final posts = await _communityPostsService.fetchCommunityPosts(
        communityId: widget.communityId,
      );

      setState(() {
        _posts = posts;
        _isPostsLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPostsLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load posts: ${e.toString()}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _joinCommunity() async {
    if (_community == null) return;

    try {
      LoadingUtils.showLoading(context, message: 'Joining community...');
      
      final updatedCommunity = await _communityService.joinCommunity(_community!.id);
      
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      setState(() {
        _community = updatedCommunity;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${_community!.name}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload members list
      _loadMembers();
    } catch (e) {
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join community: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _leaveCommunity() async {
    if (_community == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Leave Community',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to leave ${_community!.name}?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      LoadingUtils.showLoading(context, message: 'Leaving community...');
      
      final updatedCommunity = await _communityService.leaveCommunity(_community!.id);
      
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      setState(() {
        _community = updatedCommunity;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${_community!.name}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload members list
      _loadMembers();
    } catch (e) {
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave community: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCommunityHeader() {
    if (_community == null) return Container();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.pink.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Community avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.group,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Community name
          Text(
            _community!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Sport badge
          if (_community!.sport != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                _community!.sport!,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'Members',
                value: _community!.memberCount.toString(),
              ),
              _buildStatItem(
                icon: Icons.calendar_today,
                label: 'Created',
                value: timeago.format(_community!.createdAt),
              ),
              _buildStatItem(
                icon: Icons.person,
                label: 'Creator',
                value: _community!.creatorUsername,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (_community!.description.isNotEmpty) ...[
            Text(
              _community!.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Tags
          if (_community!.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _community!.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Join/Leave button
          Container(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _community!.isJoined ? _leaveCommunity : _joinCommunity,
              style: ElevatedButton.styleFrom(
                backgroundColor: _community!.isJoined 
                    ? Colors.red.withOpacity(0.8)
                    : Colors.green.withOpacity(0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _community!.isJoined ? 'Leave Community' : 'Join Community',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 
                      ? Colors.purple.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Members',
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 
                      ? Colors.purple.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Posts',
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isMembersLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: DiceLoadingWidget(
            message: 'Loading members...',
            size: 60,
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No members yet',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final user = member['user'];
        final role = member['role'];
        final joinedAt = DateTime.parse(member['joined_at']);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[600]!.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              ProfileAvatar(
                avatarUrl: user['avatar_url'],
                username: user['username'] ?? 'Unknown',
                radius: 20,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['username'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (role == 'owner') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'OWNER',
                              style: TextStyle(
                                color: Colors.purple[300],
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Joined ${timeago.format(joinedAt)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectMedia() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedMediaBytes = bytes;
          _selectedMediaMimeType = file.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select media: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createPost() async {
    if (_postContentController.text.trim().isEmpty && _selectedPostType == CommunityPostType.chat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat posts must have content'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if ((_selectedPostType == CommunityPostType.image || _selectedPostType == CommunityPostType.video) && 
        _selectedMediaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedPostType == CommunityPostType.image ? 'Image' : 'Video'} posts must have media'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      CommunityPost newPost;

      switch (_selectedPostType) {
        case CommunityPostType.chat:
          newPost = await _communityPostsService.createChatPost(
            communityId: widget.communityId,
            content: _postContentController.text.trim(),
          );
          break;
        
        case CommunityPostType.image:
          newPost = await _communityPostsService.createImagePost(
            communityId: widget.communityId,
            content: _postContentController.text.trim(),
            imageBytes: _selectedMediaBytes!,
            mimeType: _selectedMediaMimeType!,
          );
          break;
        
        case CommunityPostType.video:
          newPost = await _communityPostsService.createVideoPost(
            communityId: widget.communityId,
            content: _postContentController.text.trim(),
            videoBytes: _selectedMediaBytes!,
            mimeType: _selectedMediaMimeType!,
          );
          break;
      }

      // Add new post to the top of the list
      setState(() {
        _posts.insert(0, newPost);
        _postContentController.clear();
        _selectedMediaBytes = null;
        _selectedMediaMimeType = null;
        _selectedPostType = CommunityPostType.chat;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingPost = false;
      });
    }
  }

  Widget _buildCreatePostSection() {
    if (_community?.isJoined != true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post type selector
          Row(
            children: [
              Text(
                'Post Type:',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<CommunityPostType>(
                  value: _selectedPostType,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  items: [
                    DropdownMenuItem(
                      value: CommunityPostType.chat,
                      child: Row(
                        children: [
                          Icon(Icons.chat, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          const Text('Chat'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: CommunityPostType.image,
                      child: Row(
                        children: [
                          Icon(Icons.image, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          const Text('Image'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: CommunityPostType.video,
                      child: Row(
                        children: [
                          Icon(Icons.videocam, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          const Text('Video'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPostType = value;
                        if (value == CommunityPostType.chat) {
                          _selectedMediaBytes = null;
                          _selectedMediaMimeType = null;
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content input
          TextField(
            controller: _postContentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _selectedPostType == CommunityPostType.chat 
                  ? 'What\'s on your mind?'
                  : 'Add a caption (optional)...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[700]!.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          // Media selection for image/video posts
          if (_selectedPostType != CommunityPostType.chat) ...[
            const SizedBox(height: 16),
            if (_selectedMediaBytes != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedPostType == CommunityPostType.image
                      ? Image.memory(
                          _selectedMediaBytes!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[700],
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedMediaBytes = null;
                    _selectedMediaMimeType = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _selectMedia,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[600]!),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  _selectedPostType == CommunityPostType.image 
                      ? Icons.image 
                      : Icons.videocam,
                ),
                label: Text('Select ${_selectedPostType == CommunityPostType.image ? 'Image' : 'Video'}'),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Post button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreatingPost ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isCreatingPost 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isCreatingPost ? 'Posting...' : 'Post'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isPostsLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: DiceLoadingWidget(
            message: 'Loading posts...',
            size: 60,
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.forum_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _community?.isJoined == true 
                    ? 'Be the first to post in this community!'
                    : 'Join the community to see posts',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostItem(_posts[index]),
    );
  }

  Widget _buildPostItem(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[600]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Row(
            children: [
              ProfileAvatar(
                avatarUrl: post.userAvatarUrl,
                username: post.username,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPostTypeColor(post.postType),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getPostTypeLabel(post.postType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      timeago.format(post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post content
          if (post.content.isNotEmpty) ...[
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Media content
          if (post.hasMedia) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.isImagePost
                    ? Image.network(
                        post.mediaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[700],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[700],
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Post actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _togglePostLike(post),
                child: Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.likeCount.toString(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.commentCount.toString(),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (post.hasMedia) ...[
                Text(
                  post.formattedFileSize,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePostLike(CommunityPost post) async {
    try {
      final newLikeStatus = await _communityPostsService.toggleLike(post.id);
      
      setState(() {
        post.isLiked = newLikeStatus;
        post.likeCount += newLikeStatus ? 1 : -1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle like: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Color _getPostTypeColor(CommunityPostType type) {
    switch (type) {
      case CommunityPostType.chat:
        return Colors.blue.withOpacity(0.8);
      case CommunityPostType.image:
        return Colors.green.withOpacity(0.8);
      case CommunityPostType.video:
        return Colors.orange.withOpacity(0.8);
    }
  }

  String _getPostTypeLabel(CommunityPostType type) {
    switch (type) {
      case CommunityPostType.chat:
        return 'CHAT';
      case CommunityPostType.image:
        return 'IMAGE';
      case CommunityPostType.video:
        return 'VIDEO';
    }
  }

  Widget _buildActivityFeed() {
    return Column(
      children: [
        _buildCreatePostSection(),
        _buildPostsList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: _community != null
            ? Text(
                _community!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: DiceLoadingWidget(
                message: 'Loading community...',
                size: 80,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading community',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCommunityDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildCommunityHeader(),
                            _buildTabBar(),
                            _selectedTabIndex == 0
                                ? _buildMembersList()
                                : _buildActivityFeed(),
                            const SizedBox(height: 100), // Bottom padding
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 