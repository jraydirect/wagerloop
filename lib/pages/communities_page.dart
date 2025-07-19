// lib/pages/communities_page.dart
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/supabase_config.dart';
import '../widgets/dice_loading_widget.dart';
import '../utils/loading_utils.dart';
import 'create_community_page.dart';
import 'community_details_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({Key? key}) : super(key: key);

  @override
  _CommunitiesPageState createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _communityService = SupabaseConfig.communityService;
  final _searchController = TextEditingController();
  
  List<Community> _searchResults = [];
  List<Community> _popularCommunities = [];
  List<Community> _joinedCommunities = [];
  
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  String _selectedSport = 'All';

  final List<String> _sports = [
    'All',
    'NFL',
    'NBA',
    'MLB',
    'NHL',
    'UFC',
    'Soccer',
    'Tennis',
    'Golf',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadInitialData();
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final popularFuture = _communityService.getPopularCommunities();
      final joinedFuture = _communityService.getJoinedCommunities();

      final results = await Future.wait([popularFuture, joinedFuture]);
      
      setState(() {
        _popularCommunities = results[0];
        _joinedCommunities = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCommunities() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _communityService.searchCommunities(
        query: query,
        sport: _selectedSport == 'All' ? null : _selectedSport,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _joinCommunity(Community community) async {
    try {
      LoadingUtils.showLoading(context, message: 'Joining community...');
      
      final updatedCommunity = await _communityService.joinCommunity(community.id);
      
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      setState(() {
        // Update the community in all lists
        _updateCommunityInLists(updatedCommunity);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${community.name}!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Future<void> _leaveCommunity(Community community) async {
    try {
      LoadingUtils.showLoading(context, message: 'Leaving community...');
      
      final updatedCommunity = await _communityService.leaveCommunity(community.id);
      
      LoadingUtils.hideLoading(context); // Close loading dialog
      
      setState(() {
        // Update the community in all lists
        _updateCommunityInLists(updatedCommunity);
        // Remove from joined communities
        _joinedCommunities.removeWhere((c) => c.id == community.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Left ${community.name}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  void _updateCommunityInLists(Community updatedCommunity) {
    // Update in search results
    final searchIndex = _searchResults.indexWhere((c) => c.id == updatedCommunity.id);
    if (searchIndex != -1) {
      _searchResults[searchIndex] = updatedCommunity;
    }

    // Update in popular communities
    final popularIndex = _popularCommunities.indexWhere((c) => c.id == updatedCommunity.id);
    if (popularIndex != -1) {
      _popularCommunities[popularIndex] = updatedCommunity;
    }

    // Add to joined communities if now joined
    if (updatedCommunity.isJoined && !_joinedCommunities.any((c) => c.id == updatedCommunity.id)) {
      _joinedCommunities.insert(0, updatedCommunity);
    }
  }

  Widget _buildCommunityCard(Community community) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!.withOpacity(0.95),
            Colors.grey[800]!.withOpacity(0.9),
            Colors.grey[850]!.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityDetailsPage(communityId: community.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Community avatar/icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.pink],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Community info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  community.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (community.sport != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    community.sport!,
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${community.memberCount} members',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'by ${community.creatorUsername}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Join/Leave button
                    Container(
                      width: 80,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          if (community.isJoined) {
                            _leaveCommunity(community);
                          } else {
                            _joinCommunity(community);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: community.isJoined 
                              ? Colors.red.withOpacity(0.8)
                              : Colors.green.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          community.isJoined ? 'Leave' : 'Join',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (community.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    community.description,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags
                if (community.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: community.tags.take(3).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search communities...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[700]!.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _searchCommunities();
                      } else {
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[700]!.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSport,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey[800],
                    underline: Container(),
                    items: _sports.map((sport) {
                      return DropdownMenuItem(
                        value: sport,
                        child: Text(sport),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSport = value!;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _searchCommunities();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Communities',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCommunityPage(),
                ),
              );
              
              if (result == true) {
                _loadInitialData(); // Refresh the data
              }
            },
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: DiceLoadingWidget(
                message: 'Loading communities...',
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
                        'Error loading communities',
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
                        onPressed: _loadInitialData,
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
                      child: Column(
                        children: [
                          // Search section
                          _buildSearchSection(),

                          // Content
                          Expanded(
                            child: _searchController.text.isNotEmpty
                                ? _buildSearchResults()
                                : _buildDefaultContent(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: DiceLoadingWidget(
          message: 'Searching...',
          size: 60,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No communities found',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildCommunityCard(_searchResults[index]),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Joined Communities Section
          if (_joinedCommunities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Your Communities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Column(
              children: _joinedCommunities
                  .map((community) => _buildCommunityCard(community))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular Communities Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Popular Communities',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Column(
            children: _popularCommunities
                .map((community) => _buildCommunityCard(community))
                .toList(),
          ),
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }
} 