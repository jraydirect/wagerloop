# Community Posts Database Schema

This document outlines the database tables and configuration required for the Community Posts feature in WagerLoop, allowing users to post different types of content (chat, picture, video) within communities.

## Required Tables

### 1. `community_posts` Table

This is the main table that stores community post information with support for different content types.

```sql
CREATE TABLE community_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  user_avatar_url TEXT,
  post_type TEXT NOT NULL CHECK (post_type IN ('chat', 'image', 'video')),
  content TEXT NOT NULL,
  media_url TEXT, -- For image and video posts
  media_thumbnail_url TEXT, -- For video thumbnails
  media_file_size BIGINT, -- File size in bytes
  media_mime_type TEXT, -- MIME type of media file
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. `community_post_likes` Table

This table manages likes on community posts.

```sql
CREATE TABLE community_post_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);
```

### 3. `community_post_comments` Table

This table manages comments on community posts.

```sql
CREATE TABLE community_post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  user_avatar_url TEXT,
  content TEXT NOT NULL,
  parent_comment_id UUID REFERENCES community_post_comments(id) ON DELETE CASCADE,
  reply_to_username TEXT,
  reply_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Indexes

Add these indexes for better query performance:

```sql
-- Community posts indexes
CREATE INDEX idx_community_posts_community_id ON community_posts(community_id);
CREATE INDEX idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX idx_community_posts_post_type ON community_posts(post_type);
CREATE INDEX idx_community_posts_created_at ON community_posts(created_at DESC);
CREATE INDEX idx_community_posts_like_count ON community_posts(like_count DESC);

-- Community post likes indexes
CREATE INDEX idx_community_post_likes_post_id ON community_post_likes(post_id);
CREATE INDEX idx_community_post_likes_user_id ON community_post_likes(user_id);
CREATE INDEX idx_community_post_likes_created_at ON community_post_likes(created_at DESC);

-- Community post comments indexes
CREATE INDEX idx_community_post_comments_post_id ON community_post_comments(post_id);
CREATE INDEX idx_community_post_comments_user_id ON community_post_comments(user_id);
CREATE INDEX idx_community_post_comments_parent_id ON community_post_comments(parent_comment_id);
CREATE INDEX idx_community_post_comments_created_at ON community_post_comments(created_at DESC);
```

## Row Level Security (RLS) Policies

Enable RLS and create the following policies:

### Community Posts Table Policies

```sql
-- Enable RLS
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Allow users to view posts from communities they're members of
CREATE POLICY "Users can view posts from their communities" ON community_posts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM community_members 
      WHERE community_id = community_posts.community_id 
      AND user_id = auth.uid()
    )
  );

-- Allow users to view posts from public communities
CREATE POLICY "Public community posts are viewable" ON community_posts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND NOT is_private
    )
  );

-- Allow community members to create posts
CREATE POLICY "Community members can create posts" ON community_posts
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM community_members 
      WHERE community_id = community_posts.community_id 
      AND user_id = auth.uid()
    )
  );

-- Allow users to update their own posts
CREATE POLICY "Users can update their own posts" ON community_posts
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own posts
CREATE POLICY "Users can delete their own posts" ON community_posts
  FOR DELETE USING (auth.uid() = user_id);

-- Allow community owners to delete posts
CREATE POLICY "Community owners can delete posts" ON community_posts
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );
```

### Community Post Likes Table Policies

```sql
-- Enable RLS
ALTER TABLE community_post_likes ENABLE ROW LEVEL SECURITY;

-- Allow users to view likes on posts they can see
CREATE POLICY "Users can view likes on accessible posts" ON community_post_likes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN community_members cm ON cp.community_id = cm.community_id
      WHERE cp.id = post_id AND cm.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN communities c ON cp.community_id = c.id
      WHERE cp.id = post_id AND NOT c.is_private
    )
  );

-- Allow users to like posts
CREATE POLICY "Users can like posts" ON community_post_likes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN community_members cm ON cp.community_id = cm.community_id
      WHERE cp.id = post_id AND cm.user_id = auth.uid()
    )
  );

-- Allow users to unlike their own likes
CREATE POLICY "Users can unlike posts" ON community_post_likes
  FOR DELETE USING (auth.uid() = user_id);
```

### Community Post Comments Table Policies

```sql
-- Enable RLS
ALTER TABLE community_post_comments ENABLE ROW LEVEL SECURITY;

-- Allow users to view comments on posts they can see
CREATE POLICY "Users can view comments on accessible posts" ON community_post_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN community_members cm ON cp.community_id = cm.community_id
      WHERE cp.id = post_id AND cm.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN communities c ON cp.community_id = c.id
      WHERE cp.id = post_id AND NOT c.is_private
    )
  );

-- Allow community members to comment on posts
CREATE POLICY "Community members can comment on posts" ON community_post_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN community_members cm ON cp.community_id = cm.community_id
      WHERE cp.id = post_id AND cm.user_id = auth.uid()
    )
  );

-- Allow users to update their own comments
CREATE POLICY "Users can update their own comments" ON community_post_comments
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own comments
CREATE POLICY "Users can delete their own comments" ON community_post_comments
  FOR DELETE USING (auth.uid() = user_id);

-- Allow community owners to delete comments
CREATE POLICY "Community owners can delete comments" ON community_post_comments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM community_posts cp
      JOIN communities c ON cp.community_id = c.id
      WHERE cp.id = post_id AND c.creator_id = auth.uid()
    )
  );
```

## Database Functions and Triggers

### Update Like Count Function

```sql
CREATE OR REPLACE FUNCTION update_community_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts 
    SET like_count = like_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts 
    SET like_count = GREATEST(0, like_count - 1) 
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for like count
CREATE TRIGGER trigger_update_like_count_on_insert
  AFTER INSERT ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();

CREATE TRIGGER trigger_update_like_count_on_delete
  AFTER DELETE ON community_post_likes
  FOR EACH ROW EXECUTE FUNCTION update_community_post_like_count();
```

### Update Comment Count Function

```sql
CREATE OR REPLACE FUNCTION update_community_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts 
    SET comment_count = comment_count + 1 
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts 
    SET comment_count = GREATEST(0, comment_count - 1) 
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for comment count
CREATE TRIGGER trigger_update_comment_count_on_insert
  AFTER INSERT ON community_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_community_post_comment_count();

CREATE TRIGGER trigger_update_comment_count_on_delete
  AFTER DELETE ON community_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_community_post_comment_count();
```

### Update Reply Count Function

```sql
CREATE OR REPLACE FUNCTION update_comment_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_comment_id IS NOT NULL THEN
    UPDATE community_post_comments 
    SET reply_count = reply_count + 1 
    WHERE id = NEW.parent_comment_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_comment_id IS NOT NULL THEN
    UPDATE community_post_comments 
    SET reply_count = GREATEST(0, reply_count - 1) 
    WHERE id = OLD.parent_comment_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for reply count
CREATE TRIGGER trigger_update_reply_count_on_insert
  AFTER INSERT ON community_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_reply_count();

CREATE TRIGGER trigger_update_reply_count_on_delete
  AFTER DELETE ON community_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_comment_reply_count();
```

### Updated At Function

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER trigger_community_posts_updated_at
  BEFORE UPDATE ON community_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_community_post_comments_updated_at
  BEFORE UPDATE ON community_post_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Setup Instructions

1. **Create the tables** by running the SQL statements above in your Supabase SQL editor.

2. **Enable RLS** on all tables and add the policies.

3. **Create indexes** for better performance.

4. **Add the triggers** for automatic count updates and updated_at timestamps.

5. **Set up storage bucket** for media files:
   - Create a new bucket called `community-media`
   - Configure appropriate file size limits (e.g., 10MB for images, 50MB for videos)
   - Set up RLS policies for media access

6. **Verify the setup** by testing basic operations:
   - Create a community post
   - Like a post
   - Comment on a post
   - Upload media content

## Post Type Specifications

### Chat Posts
- `post_type`: 'chat'
- `content`: Text content (required)
- `media_url`: NULL
- Example: General discussion, questions, announcements

### Image Posts
- `post_type`: 'image'
- `content`: Caption/description (optional)
- `media_url`: URL to uploaded image (required)
- `media_mime_type`: image/jpeg, image/png, etc.
- Supported formats: JPEG, PNG, GIF, WebP
- Max file size: 10MB

### Video Posts
- `post_type`: 'video'
- `content`: Caption/description (optional)
- `media_url`: URL to uploaded video (required)
- `media_thumbnail_url`: URL to video thumbnail (optional)
- `media_mime_type`: video/mp4, video/webm, etc.
- Supported formats: MP4, WebM, MOV
- Max file size: 50MB

## Security Considerations

1. **File Upload Validation**:
   - Validate file types and sizes on both client and server
   - Scan uploaded files for malware
   - Generate thumbnails on server side

2. **Content Moderation**:
   - Implement community reporting system
   - Add content flagging for inappropriate posts
   - Community owner moderation tools

3. **Rate Limiting**:
   - Limit posts per user per hour
   - Limit file uploads per user per day
   - Implement spam detection

4. **Privacy**:
   - Respect private community access controls
   - Ensure media files follow same privacy rules as posts
   - Implement proper data deletion for user privacy

## Performance Considerations

1. **Media Storage**:
   - Use CDN for media delivery
   - Implement image resizing and compression
   - Generate multiple thumbnail sizes

2. **Caching**:
   - Cache popular community posts
   - Implement pagination for large comment threads
   - Use database connection pooling

3. **Real-time Updates**:
   - Use Supabase real-time subscriptions for live post updates
   - Implement optimistic UI updates for better UX
   - Batch like count updates to reduce database load

## Future Enhancements

1. **Rich Media Support**:
   - GIF support
   - Multiple image galleries
   - Video streaming capabilities

2. **Advanced Features**:
   - Post scheduling
   - Post pinning for moderators
   - Thread/topic organization

3. **Community Tools**:
   - Post analytics for community owners
   - User engagement metrics
   - Community growth insights

This schema provides a solid foundation for community posts with different content types while maintaining security, performance, and scalability. 