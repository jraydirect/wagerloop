import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if avatar URL changes
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _hasImageError = false;
    }
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
    
    // Test URL accessibility if we have a URL
    if (hasValidUrl) {
      _testUrlAccessibility(widget.avatarUrl!);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.green,
        backgroundImage: hasValidUrl
            ? NetworkImage(widget.avatarUrl!)
            : null,
        onBackgroundImageError: hasValidUrl
            ? (exception, stackTrace) {
                print('Error loading avatar image: $exception');
                print('Stack trace: $stackTrace');
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
  
  Future<void> _testUrlAccessibility(String url) async {
    try {
      print('Testing URL accessibility: $url');
      final response = await http.head(Uri.parse(url));
      print('URL test response: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
    } catch (e) {
      print('URL accessibility test failed: $e');
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
