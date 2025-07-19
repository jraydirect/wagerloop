// lib/pages/create_community_page.dart
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/supabase_config.dart';
import '../widgets/dice_loading_widget.dart';
import '../utils/loading_utils.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({Key? key}) : super(key: key);

  @override
  _CreateCommunityPageState createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  final _communityService = SupabaseConfig.communityService;
  
  bool _isPrivate = false;
  String? _selectedSport;
  bool _isSubmitting = false;

  final List<String> _sports = [
    'NFL',
    'NBA',
    'MLB',
    'NHL',
    'UFC',
    'Soccer',
    'Tennis',
    'Golf',
    'Basketball',
    'Football',
    'Baseball',
    'Hockey',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createCommunity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse tags from comma-separated string
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final community = await _communityService.createCommunity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
        sport: _selectedSport,
        tags: tags,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${community.name} created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create community: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    String? description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[800]!.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
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
            'Create Community',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _isSubmitting
                ? const Center(
                    child: DiceLoadingWidget(
                      message: 'Creating community...',
                      size: 80,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.withOpacity(0.2),
                                  Colors.pink.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.group_add,
                                  size: 48,
                                  color: Colors.purple[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Build Your Community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create a space where fans can connect, share, and engage with fellow enthusiasts.',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Community Name
                          _buildFormField(
                            label: 'Community Name',
                            description: 'Choose a memorable name for your community',
                            child: _buildTextField(
                              controller: _nameController,
                              hintText: 'e.g., Lakers Nation, NFL Draft Hub',
                              maxLength: 50,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Community name is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Description
                          _buildFormField(
                            label: 'Description',
                            description: 'Tell people what your community is about',
                            child: _buildTextField(
                              controller: _descriptionController,
                              hintText: 'Describe your community\'s purpose and what members can expect...',
                              maxLines: 4,
                              maxLength: 300,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Description is required';
                                }
                                if (value.trim().length < 10) {
                                  return 'Description must be at least 10 characters';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Sport Selection
                          _buildFormField(
                            label: 'Sport (Optional)',
                            description: 'Associate your community with a specific sport',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[600]!),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedSport,
                                hint: Text(
                                  'Select a sport',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                style: const TextStyle(color: Colors.white),
                                dropdownColor: Colors.grey[800],
                                underline: Container(),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('No specific sport'),
                                  ),
                                  ..._sports.map((sport) {
                                    return DropdownMenuItem(
                                      value: sport,
                                      child: Text(sport),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSport = value;
                                  });
                                },
                              ),
                            ),
                          ),

                          // Tags
                          _buildFormField(
                            label: 'Tags (Optional)',
                            description: 'Add tags separated by commas to help people find your community',
                            child: _buildTextField(
                              controller: _tagsController,
                              hintText: 'e.g., fantasy, trades, rookies, playoffs',
                              maxLength: 100,
                            ),
                          ),

                          // Privacy Settings
                          _buildFormField(
                            label: 'Privacy Settings',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[600]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isPrivate ? 'Private Community' : 'Public Community',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isPrivate 
                                              ? 'Only invited members can see and join'
                                              : 'Anyone can discover and join this community',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isPrivate,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPrivate = value;
                                      });
                                    },
                                    activeColor: Colors.purple,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Create Button
                          Container(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _createCommunity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey[600],
                              ),
                              child: Text(
                                _isSubmitting ? 'Creating...' : 'Create Community',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Guidelines
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[300],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Community Guidelines',
                                      style: TextStyle(
                                        color: Colors.blue[300],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Keep discussions respectful and on-topic\n'
                                  '• No spam, self-promotion, or offensive content\n'
                                  '• Respect member privacy and follow platform rules',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
} 