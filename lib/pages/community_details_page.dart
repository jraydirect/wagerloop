// lib/pages/community_details_page.dart
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/supabase_config.dart';
import '../widgets/dice_loading_widget.dart';
import '../widgets/profile_avatar.dart';
import '../utils/loading_utils.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  
  Community? _community;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isMembersLoading = false;
  String? _error;
  int _selectedTabIndex = 0;

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

      // Load members after community details
      _loadMembers();
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
                  'Activity',
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

  Widget _buildActivityFeed() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Activity Feed',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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