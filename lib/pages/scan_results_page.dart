import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/scan_service.dart';
import '../models/pick_post.dart';
import '../services/supabase_config.dart';
import '../services/auth_service.dart';
import '../widgets/picks_display_widget.dart';

class ScanResultsPage extends StatefulWidget {
  final ScanResult scanResult;

  const ScanResultsPage({
    Key? key,
    required this.scanResult,
  }) : super(key: key);

  @override
  _ScanResultsPageState createState() => _ScanResultsPageState();
}

class _ScanResultsPageState extends State<ScanResultsPage> {
  final _contentController = TextEditingController();
  final _socialFeedService = SupabaseConfig.socialFeedService;
  final _authService = AuthService();
  
  List<Pick> _selectedPicks = [];
  bool _isCreatingPost = false;

  @override
  void initState() {
    super.initState();
    _initializePicks();
  }

  void _initializePicks() {
    if (widget.scanResult.extractedPicks != null) {
      _selectedPicks = widget.scanResult.extractedPicks!
          .map((extractedPick) => extractedPick.toPick())
          .toList();
    }
    
    // Set default content
    if (widget.scanResult.extractedPicks != null && 
        widget.scanResult.extractedPicks!.isNotEmpty) {
      if (widget.scanResult.extractedPicks!.length > 1) {
        _contentController.text = 'My ${widget.scanResult.extractedPicks!.length}-leg parlay from betting slip';
      } else {
        _contentController.text = 'My pick from betting slip: ${widget.scanResult.extractedPicks!.first.teamName}';
      }
    }
  }

  Future<void> _createPickPost() async {
    final selectedPicks = _selectedPicks.where((pick) => pick.isSelected).toList();
    if (selectedPicks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No picks selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      // Get current user info
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Get user profile for username
      String username = 'current_user';
      try {
        final profile = await _authService.getCurrentUserProfile();
        username = profile?['username'] ?? currentUser.email ?? 'current_user';
      } catch (e) {
        print('Could not get user profile, using email: $e');
        username = currentUser.email ?? 'current_user';
      }

      // Create content
      String content = _contentController.text.trim();
      if (content.isEmpty) {
        if (selectedPicks.length > 1) {
          content = 'My ${selectedPicks.length}-leg parlay from betting slip';
        } else {
          content = 'My pick from betting slip: ${selectedPicks.first.game.homeTeam}';
        }
      }

      // Create the pick post with only selected picks
      final pickPost = PickPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id,
        username: username,
        content: content,
        timestamp: DateTime.now(),
        picks: selectedPicks,
      );

      // Save to Supabase using social feed service
      final createdPickPost = await _socialFeedService.createPickPost(pickPost);

      if (mounted) {
        final selectedCount = _selectedPicks.where((pick) => pick.isSelected).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(selectedCount > 1 ? 'Parlay posted successfully!' : 'Pick posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, createdPickPost); // Return the created post for instant addition
      }
    } catch (e) {
      print('Error creating pick post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPost = false;
        });
      }
    }
  }

  void _togglePickSelection(int index) {
    setState(() {
      if (_selectedPicks[index].isSelected) {
        _selectedPicks[index] = _selectedPicks[index].copyWith(isSelected: false);
      } else {
        _selectedPicks[index] = _selectedPicks[index].copyWith(isSelected: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: Colors.grey[800],
        actions: [
          if (_selectedPicks.isNotEmpty)
            TextButton(
              onPressed: _isCreatingPost ? null : _createPickPost,
              child: _isCreatingPost
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original image
            if (widget.scanResult.imagePath != null) ...[
              Card(
                color: Colors.grey[700],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Original Slip:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb 
                          ? Image.network(
                              widget.scanResult.imagePath!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[600],
                                  child: const Center(
                                    child: Text(
                                      'Image preview not available on web',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(widget.scanResult.imagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Scan summary
            Card(
              color: Colors.grey[700],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Summary:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.scanResult.totalOdds != null) ...[
                      _buildSummaryRow('Total Odds:', widget.scanResult.totalOdds!),
                    ],
                    if (widget.scanResult.stake != null) ...[
                      _buildSummaryRow('Stake:', '\$${widget.scanResult.stake!.toStringAsFixed(2)}'),
                    ],
                    if (widget.scanResult.potentialWin != null) ...[
                      _buildSummaryRow('Potential Win:', '\$${widget.scanResult.potentialWin!.toStringAsFixed(2)}'),
                    ],
                    _buildSummaryRow('Picks Found:', '${widget.scanResult.extractedPicks?.length ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content input
            Card(
              color: Colors.grey[700],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Post Content:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add your thoughts about these picks...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Extracted picks
            if (widget.scanResult.extractedPicks != null) ...[
              const Text(
                'Extracted Picks:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.scanResult.extractedPicks!.asMap().entries.map((entry) {
                final index = entry.key;
                final extractedPick = entry.value;
                final pick = _selectedPicks[index];
                
                return Card(
                  color: Colors.grey[700],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: pick.isSelected,
                              onChanged: (value) => _togglePickSelection(index),
                              activeColor: Colors.green,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${extractedPick.teamName} vs ${extractedPick.opponent}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${extractedPick.league} - ${extractedPick.sport}',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                extractedPick.odds,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                extractedPick.betType,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(extractedPick.confidence * 100).toInt()}% confidence',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],

            // Preview of selected picks
            if (_selectedPicks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Preview:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.grey[700],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PicksDisplayWidget(
                    picks: _selectedPicks.where((pick) => pick.isSelected).toList(),
                    showParlayBadge: _selectedPicks.where((pick) => pick.isSelected).length > 1,
                    compact: false,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
} 