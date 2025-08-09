# URGENT FIX: Like Count Synchronization Issue

## The Problem You're Experiencing

When you like a post:
- **Expected**: Like count shows 1
- **Actual**: Like count shows 0

When you unlike a post:
- **Expected**: Like count shows 0  
- **Actual**: Like count shows -1

## Root Cause

The `like_count` field in the `community_posts` table is **out of sync** with the actual number of likes in the `community_post_likes` table. This happens because:

1. **Database triggers aren't working properly** - The triggers that should automatically update like counts are either missing or broken
2. **Race conditions** - Multiple like operations happening simultaneously
3. **Previous bugs** - Historical data inconsistencies that never got fixed

## Immediate Fix Required

### Step 1: Fix the Database (CRITICAL - Do this first)

Run this SQL in your Supabase SQL editor:

```sql
-- Fix all existing like counts
UPDATE community_posts 
SET like_count = (
  SELECT COUNT(*) 
  FROM community_post_likes 
  WHERE post_id = community_posts.id
);

-- Recreate the trigger function
CREATE OR REPLACE FUNCTION update_community_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts 
    SET like_count = (
      SELECT COUNT(*) 
      FROM community_post_likes 
      WHERE post_id = NEW.post_id
    )
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts 
    SET like_count = (
      SELECT COUNT(*) 
      FROM community_post_likes 
      WHERE post_id = OLD.post_id
    )
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Recreate the triggers
DROP TRIGGER IF EXISTS trigger_update_like_count_on_insert ON community_post_likes;
DROP TRIGGER IF EXISTS trigger_update_like_count_on_delete ON community_post_likes;

CREATE TRIGGER trigger_update_like_count_on_insert
  AFTER INSERT ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();

CREATE TRIGGER trigger_update_like_count_on_delete
  AFTER DELETE ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();
```

### Step 2: Update the Service Code

Replace the `toggleLike` method in your service with this version that ensures count accuracy:

```dart
Future<Map<String, dynamic>> toggleLike(String postId) async {
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'User not authenticated';

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
      await _supabase
          .from('community_post_likes')
          .delete()
          .eq('id', existingLike['id']);
      newLikeStatus = false;
    } else {
      // Like the post
      await _supabase.from('community_post_likes').insert({
        'post_id': postId,
        'user_id': user.id,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      newLikeStatus = true;
    }

    // CRITICAL: Get actual count and sync it
    final actualLikesResponse = await _supabase
        .from('community_post_likes')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('post_id', postId);
    
    final actualLikeCount = actualLikesResponse.count ?? 0;
    
    // Update the stored count to match actual count
    await _supabase
        .from('community_posts')
        .update({'like_count': actualLikeCount})
        .eq('id', postId);

    return {
      'isLiked': newLikeStatus,
      'likeCount': actualLikeCount,
    };
  } catch (e) {
    throw Exception('Failed to toggle like: $e');
  }
}
```

### Step 3: Update the Fetch Method

Also update the `fetchCommunityPosts` method to always use actual counts:

```dart
// In the post fetching loop, replace like count logic with:
final actualLikesResponse = await _supabase
    .from('community_post_likes')
    .select('id', const FetchOptions(count: CountOption.exact))
    .eq('post_id', postId);

final actualLikeCount = actualLikesResponse.count ?? 0;

// Create post with actual count
final post = CommunityPost.fromJson({
  ...postData,
  'is_liked': isLiked,
  'like_count': actualLikeCount, // Always use actual count
});
```

## Why This Fixes the Problem

### Before (Broken):
1. User likes post → `community_post_likes` table gets new row
2. UI shows stored `like_count` from `community_posts` table (which is wrong)
3. Result: UI shows 0 even though user liked it

### After (Fixed):
1. User likes post → `community_post_likes` table gets new row
2. Service counts actual likes from `community_post_likes` table
3. Service updates `community_posts.like_count` with correct count
4. UI shows actual count
5. Result: UI shows correct number (1, 2, 3, etc.)

## Testing the Fix

After implementing:

1. **Like a post** → Should show count = 1
2. **Refresh page** → Should still show count = 1  
3. **Unlike the post** → Should show count = 0
4. **Have another user like it** → Should show count = 1
5. **Both users like it** → Should show count = 2

## Prevention

The database triggers will prevent this issue in the future, but the service code also includes fallbacks to ensure counts stay accurate even if triggers fail.

## Emergency Rollback Plan

If something goes wrong, you can temporarily disable the triggers:
```sql
DROP TRIGGER IF EXISTS trigger_update_like_count_on_insert ON community_post_likes;
DROP TRIGGER IF EXISTS trigger_update_like_count_on_delete ON community_post_likes;
```

Then manually fix counts later with:
```sql
UPDATE community_posts 
SET like_count = (
  SELECT COUNT(*) 
  FROM community_post_likes 
  WHERE post_id = community_posts.id
);
```

**This fix should resolve the 0/-1 count issue immediately.**
