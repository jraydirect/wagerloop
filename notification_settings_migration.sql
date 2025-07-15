-- Notification Settings Migration for WagerLoop
-- Run this in your Supabase SQL Editor

-- Create user notification settings table
CREATE TABLE IF NOT EXISTS user_notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  fcm_token TEXT,
  comment_notifications BOOLEAN DEFAULT true,
  like_notifications BOOLEAN DEFAULT true,
  follow_notifications BOOLEAN DEFAULT true,
  general_notifications BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create notifications table to track sent notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL, -- 'comment', 'like', 'follow', 'general'
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Additional data like post_id, commenter_id, etc.
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_notification_settings_user_id ON user_notification_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at);

-- Add RLS policies for user_notification_settings
ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

-- Users can only view and update their own notification settings
CREATE POLICY "Users can view own notification settings" ON user_notification_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification settings" ON user_notification_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification settings" ON user_notification_settings
  FOR UPDATE USING (auth.uid() = user_id);

-- Add RLS policies for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications" ON notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user_notification_settings
CREATE TRIGGER update_user_notification_settings_updated_at
  BEFORE UPDATE ON user_notification_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to send comment notification
CREATE OR REPLACE FUNCTION send_comment_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_author_id UUID;
  commenter_username TEXT;
  post_content TEXT;
BEGIN
  -- Get the post author ID
  SELECT profile_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't send notification if commenting on own post
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get commenter username
  SELECT username INTO commenter_username
  FROM profiles
  WHERE id = NEW.user_id;
  
  -- Get post content (truncated)
  SELECT LEFT(content, 100) INTO post_content
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Insert notification
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    data
  ) VALUES (
    post_author_id,
    'comment',
    'New Comment',
    commenter_username || ' commented on your post',
    jsonb_build_object(
      'post_id', NEW.post_id,
      'comment_id', NEW.id,
      'commenter_id', NEW.user_id,
      'commenter_username', commenter_username,
      'comment_content', NEW.content,
      'post_content', post_content
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for comment notifications
DROP TRIGGER IF EXISTS trigger_send_comment_notification ON comments;
CREATE TRIGGER trigger_send_comment_notification
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION send_comment_notification();

-- Create function to send like notification
CREATE OR REPLACE FUNCTION send_like_notification()
RETURNS TRIGGER AS $$
DECLARE
  post_author_id UUID;
  liker_username TEXT;
  post_content TEXT;
BEGIN
  -- Get the post author ID
  SELECT profile_id INTO post_author_id
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Don't send notification if liking own post
  IF post_author_id = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Get liker username
  SELECT username INTO liker_username
  FROM profiles
  WHERE id = NEW.user_id;
  
  -- Get post content (truncated)
  SELECT LEFT(content, 100) INTO post_content
  FROM posts
  WHERE id = NEW.post_id;
  
  -- Insert notification
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    data
  ) VALUES (
    post_author_id,
    'like',
    'New Like',
    liker_username || ' liked your post',
    jsonb_build_object(
      'post_id', NEW.post_id,
      'liker_id', NEW.user_id,
      'liker_username', liker_username,
      'post_content', post_content
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for like notifications (assuming you have a likes table)
-- Uncomment and modify if you have a likes table
/*
DROP TRIGGER IF EXISTS trigger_send_like_notification ON likes;
CREATE TRIGGER trigger_send_like_notification
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION send_like_notification();
*/

-- Create function to send follow notification
CREATE OR REPLACE FUNCTION send_follow_notification()
RETURNS TRIGGER AS $$
DECLARE
  follower_username TEXT;
BEGIN
  -- Get follower username
  SELECT username INTO follower_username
  FROM profiles
  WHERE id = NEW.follower_id;
  
  -- Insert notification
  INSERT INTO notifications (
    user_id,
    type,
    title,
    body,
    data
  ) VALUES (
    NEW.following_id,
    'follow',
    'New Follower',
    follower_username || ' started following you',
    jsonb_build_object(
      'follower_id', NEW.follower_id,
      'follower_username', follower_username
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for follow notifications (assuming you have a follows table)
-- Uncomment and modify if you have a follows table
/*
DROP TRIGGER IF EXISTS trigger_send_follow_notification ON follows;
CREATE TRIGGER trigger_send_follow_notification
  AFTER INSERT ON follows
  FOR EACH ROW EXECUTE FUNCTION send_follow_notification();
*/

-- Create function to mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE notifications
  SET read_at = NOW()
  WHERE user_id = user_uuid AND read_at IS NULL;
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  count INTEGER;
BEGIN
  SELECT COUNT(*) INTO count
  FROM notifications
  WHERE user_id = user_uuid AND read_at IS NULL;
  
  RETURN count;
END;
$$ LANGUAGE plpgsql; 