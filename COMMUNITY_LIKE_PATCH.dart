// PATCH: community_details_page.dart
// Apply these changes to fix the community like persistence issue

// 1. UPDATE IMPORT (add this import)
import '../services/community_posts_service_fixed.dart';

// 2. UPDATE SERVICE INITIALIZATION 
// FIND this line:
// final _communityPostsService = CommunityPostsService(SupabaseConfig.supabase);
// REPLACE with:
final _communityPostsService = CommunityPostsServiceFixed(SupabaseConfig.supabase);

// 3. REPLACE THE _togglePostLike METHOD
// FIND the existing _togglePostLike method and REPLACE it with:

Future<void> _togglePostLike(CommunityPost post) async {
  try {
    // Store original state for rollback on error
    final originalIsLiked = post.isLiked;
    final originalLikeCount = post.likeCount;
    
    // Optimistic UI update for immediate feedback
    setState(() {
      post.isLiked = !post.isLiked;
      post.likeCount += post.isLiked ? 1 : -1;
    });
    
    // Call the improved service method that returns like status and count
    final result = await _communityPostsService.toggleLike(post.id);
    
    // Update with actual values from database to ensure accuracy
    setState(() {
      post.isLiked = result['isLiked'];
      post.likeCount = result['likeCount'];
    });
    
    print('Like toggled successfully: ${post.isLiked ? 'liked' : 'unliked'} (count: ${post.likeCount})');
    
  } catch (e) {
    // Rollback optimistic update on error to maintain UI consistency
    setState(() {
      post.isLiked = originalIsLiked;
      post.likeCount = originalLikeCount;
    });
    
    print('Error toggling like: $e');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to toggle like: $e'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// That's it! These 3 changes will fix the like persistence issue.
// 
// The key improvements:
// 1. Uses the enhanced service with better database queries
// 2. Handles both like status and count from the service response
// 3. Implements proper error handling with UI rollback
// 4. Adds debug logging to track like operations
//
// After making these changes:
// - Community post likes will persist after page refresh
// - Like counts will be accurate and consistent
// - Users will get proper feedback if like operations fail
// - The app will handle network issues gracefully
