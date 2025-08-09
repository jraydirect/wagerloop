-- DATABASE FIX: Synchronize Like Counts
-- Run this SQL in your Supabase SQL editor to fix existing data inconsistencies

-- 1. First, let's see what posts have incorrect like counts
-- This query shows posts where the stored count doesn't match actual likes
SELECT 
  cp.id,
  cp.like_count as stored_count,
  COUNT(cpl.id) as actual_count,
  (COUNT(cpl.id) - cp.like_count) as difference
FROM community_posts cp
LEFT JOIN community_post_likes cpl ON cp.id = cpl.post_id
GROUP BY cp.id, cp.like_count
HAVING cp.like_count != COUNT(cpl.id)
ORDER BY difference DESC;

-- 2. Fix all like counts to match actual likes
-- This updates the like_count field to match the actual number of likes
UPDATE community_posts 
SET like_count = (
  SELECT COUNT(*) 
  FROM community_post_likes 
  WHERE post_id = community_posts.id
);

-- 3. Verify the fix worked
-- This should return no rows if everything is now synchronized
SELECT 
  cp.id,
  cp.like_count as stored_count,
  COUNT(cpl.id) as actual_count
FROM community_posts cp
LEFT JOIN community_post_likes cpl ON cp.id = cpl.post_id
GROUP BY cp.id, cp.like_count
HAVING cp.like_count != COUNT(cpl.id);

-- 4. Check if the database triggers exist and are working
-- This creates the trigger function if it doesn't exist
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

-- 5. Recreate the triggers to ensure they're working
DROP TRIGGER IF EXISTS trigger_update_like_count_on_insert ON community_post_likes;
DROP TRIGGER IF EXISTS trigger_update_like_count_on_delete ON community_post_likes;

CREATE TRIGGER trigger_update_like_count_on_insert
  AFTER INSERT ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();

CREATE TRIGGER trigger_update_like_count_on_delete
  AFTER DELETE ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();

-- 6. Test the triggers work
-- After running this, you can test by inserting/deleting likes manually
-- The like_count should update automatically

-- Example test (replace with actual post_id and user_id):
-- INSERT INTO community_post_likes (post_id, user_id) VALUES ('your-post-id', 'your-user-id');
-- Check if like_count increased in community_posts table
-- DELETE FROM community_post_likes WHERE post_id = 'your-post-id' AND user_id = 'your-user-id';
-- Check if like_count decreased in community_posts table
