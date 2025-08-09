// CRITICAL FIX: Like Count Synchronization Issue
// This fixes the problem where like counts show 0 when they should show 1, and -1 when unliking

// UPDATED toggleLike method for community_posts_service_fixed.dart
// Replace the existing toggleLike method with this version:

Future<Map<String, dynamic>> toggleLike(String postId) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    print('Toggling like for post: $postId, user: ${user.id}');

    // Check current like status
    final existingLike = await _supabase
        .from('community_post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    bool newLikeStatus;
    
    if (existingLike != null) {
      // Unlike the post
      print('Removing like...');
      await _supabase
          .from('community_post_likes')
          .delete()
          .eq('id', existingLike['id']);
      newLikeStatus = false;
    } else {
      // Like the post
      print('Adding like...');
      await _supabase.from('community_post_likes').insert({
        'post_id': postId,
        'user_id': user.id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      newLikeStatus = true;
    }

    // CRITICAL FIX: Get the actual count directly from community_post_likes table
    // Don't rely on the like_count field in community_posts table
    final actualLikesResponse = await _supabase
        .from('community_post_likes')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('post_id', postId);
    
    final actualLikeCount = actualLikesResponse.count ?? 0;
    
    // CRITICAL FIX: Update the community_posts table with the correct count
    // This ensures the stored count matches the actual count
    await _supabase
        .from('community_posts')
        .update({'like_count': actualLikeCount})
        .eq('id', postId);
    
    print('Toggle complete: isLiked=$newLikeStatus, actualCount=$actualLikeCount');

    return {
      'isLiked': newLikeStatus,
      'likeCount': actualLikeCount,
    };
  } catch (e) {
    print('Error in toggleLike: $e');
    throw Exception('Failed to toggle like: $e');
  }
}

// ALSO UPDATE the fetchCommunityPosts method to always use actual counts:
// Replace the like count fetching part with this:

Future<List<CommunityPost>> fetchCommunityPosts({
  required String communityId,
  int limit = 20,
  int offset = 0,
}) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

    print('Fetching community posts for community: $communityId, user: ${user.id}');

    // Fetch posts from the community
    final response = await _supabase
        .from('community_posts')
        .select('*')
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    print('Raw response: $response');

    final posts = <CommunityPost>[];

    for (final postData in response) {
      final postId = postData['id'];
      
      // CRITICAL FIX: Always get actual counts from the likes table
      // Don't trust the stored like_count field
      
      // Check if user liked this post
      final userLike = await _supabase
          .from('community_post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();
      
      final isLiked = userLike != null;
      
      // Get the ACTUAL like count from the likes table
      final actualLikesResponse = await _supabase
          .from('community_post_likes')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('post_id', postId);
      
      final actualLikeCount = actualLikesResponse.count ?? 0;
      
      // CRITICAL FIX: Update the stored count if it's wrong
      final storedCount = postData['like_count'] ?? 0;
      if (storedCount != actualLikeCount) {
        print('Count mismatch for post $postId: stored=$storedCount, actual=$actualLikeCount. Fixing...');
        await _supabase
            .from('community_posts')
            .update({'like_count': actualLikeCount})
            .eq('id', postId);
      }
      
      print('Post $postId: isLiked=$isLiked, actualCount=$actualLikeCount');

      // Create post object with ACTUAL counts (not stored counts)
      final post = CommunityPost.fromJson({
        ...postData,
        'is_liked': isLiked,
        'like_count': actualLikeCount, // Use actual count, not stored count
      });

      posts.add(post);
    }

    print('Returning ${posts.length} posts');
    return posts;
  } catch (e) {
    print('Error in fetchCommunityPosts: $e');
    throw Exception('Failed to fetch community posts: $e');
  }
}
