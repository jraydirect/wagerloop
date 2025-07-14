import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ProfileAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    required this.avatarUrl,
    required this.username,
    this.radius = 20,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasImageError = false;
  bool _isLoading = false;
  String? _lastUrl;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _lastUrl = widget.avatarUrl;
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if avatar URL changes
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _hasImageError = false;
      _lastUrl = widget.avatarUrl;
      _testUrlAccessibility();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = widget.avatarUrl != null && 
                       widget.avatarUrl!.isNotEmpty && 
                       !_hasImageError;
    
    // Debug logging
    print('ProfileAvatar Debug:');
    print('- Avatar URL: ${widget.avatarUrl}');
    print('- Username: ${widget.username}');
    print('- Has valid URL: $hasValidUrl');
    print('- Has image error: $_hasImageError');
    print('- Is loading: $_isLoading');
    
    return GestureDetector(
      onTap: widget.onTap,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.green,
        backgroundImage: hasValidUrl
            ? NetworkImage(
                widget.avatarUrl!,
                headers: {
                  'Cache-Control': 'no-cache',
                  'Pragma': 'no-cache',
                },
              )
            : null,
        onBackgroundImageError: hasValidUrl
            ? (exception, stackTrace) {
                print('Error loading avatar image: $exception');
                print('Stack trace: $stackTrace');
                print('Failed URL: ${widget.avatarUrl}');
                if (mounted) {
                  setState(() {
                    _hasImageError = true;
                  });
                }
              }
            : null,
        child: !hasValidUrl
            ? Text(
                _getInitials(widget.username),
                style: TextStyle(
                  fontSize: widget.radius * 0.6,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
  
  void _testUrlAccessibility() {
    // Debounce the URL test to avoid too many requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
        _performUrlTest(widget.avatarUrl!);
      }
    });
  }

  Future<void> _performUrlTest(String url) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Testing URL accessibility: $url');
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('URL test response: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      
      if (response.statusCode != 200) {
        print('Warning: URL returned status code ${response.statusCode}');
        if (mounted && !_hasImageError) {
          setState(() {
            _hasImageError = true;
          });
        }
      }
    } catch (e) {
      print('URL accessibility test failed: $e');
      if (mounted && !_hasImageError) {
        setState(() {
          _hasImageError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String username) {
    if (username.isEmpty) return 'A';
    
    final words = username.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return username[0].toUpperCase();
    }
  }
}
