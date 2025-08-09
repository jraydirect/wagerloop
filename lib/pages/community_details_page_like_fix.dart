// Updated _togglePostLike method for community_details_page.dart
// Replace the existing _togglePostLike method with this improved version

Future<void> _togglePostLike(CommunityPost post) async {
  try {
    // Store original state for rollback on error
    final originalIsLiked = post.isLiked;
    final originalLikeCount = post.likeCount;
    
    // Optimistic UI update
    setState(() {
      post.isLiked = !post.isLiked;
      post.likeCount += post.isLiked ? 1 : -1;
    });
    
    // Call the improved service method
    final result = await _communityPostsService.toggleLike(post.id);
    
    // Update with actual values from database
    setState(() {
      post.isLiked = result['isLiked'];
      post.likeCount = result['likeCount'];
    });
    
    print('Like toggled successfully: ${post.isLiked ? 'liked' : 'unliked'}');
  } catch (e) {
    // Rollback optimistic update on error
    setState(() {
      post.isLiked = originalIsLiked;
      post.likeCount = originalLikeCount;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to toggle like: $e'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Also update the service initialization at the top of the class:
// Replace this line:
// final _communityPostsService = CommunityPostsService(SupabaseConfig.supabase);
// With:
// final _communityPostsService = CommunityPostsServiceFixed(SupabaseConfig.supabase);
