-- Comment Replies Migration for WagerLoop
-- Run this in your Supabase SQL Editor

-- Add reply-related columns to the comments table
ALTER TABLE comments 
ADD COLUMN IF NOT EXISTS parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS reply_to_username VARCHAR(255),
ADD COLUMN IF NOT EXISTS reply_count INTEGER DEFAULT 0;

-- Create index for parent_comment_id for better performance
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id);

-- Create a function to update reply counts
CREATE OR REPLACE FUNCTION update_comment_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment reply count when a new reply is added
    UPDATE comments 
    SET reply_count = reply_count + 1 
    WHERE id = NEW.parent_comment_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement reply count when a reply is deleted
    UPDATE comments 
    SET reply_count = reply_count - 1 
    WHERE id = OLD.parent_comment_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update reply counts
DROP TRIGGER IF EXISTS trigger_update_reply_count ON comments;
CREATE TRIGGER trigger_update_reply_count
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_reply_count();

-- Add RLS policies for comment replies
-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view all comments" ON comments;
DROP POLICY IF EXISTS "Users can insert comments" ON comments;
DROP POLICY IF EXISTS "Users can update own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON comments;

-- Allow users to view all comments (including replies)
CREATE POLICY "Users can view all comments" ON comments
  FOR SELECT USING (true);

-- Allow authenticated users to insert comments (including replies)
CREATE POLICY "Users can insert comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own comments
CREATE POLICY "Users can update own comments" ON comments
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own comments
CREATE POLICY "Users can delete own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);

-- Enable RLS on comments table if not already enabled
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Verify the migration
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'comments' 
ORDER BY ordinal_position; 