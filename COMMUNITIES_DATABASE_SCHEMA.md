# Communities Database Schema

This document outlines the database tables and configuration required for the Communities feature in WagerLoop.

## Required Tables

### 1. `communities` Table

This is the main table that stores community information.

```sql
CREATE TABLE communities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  creator_username TEXT NOT NULL,
  creator_avatar_url TEXT,
  is_private BOOLEAN DEFAULT false,
  sport TEXT, -- Optional: NFL, NBA, MLB, NHL, UFC, etc.
  tags TEXT[] DEFAULT '{}', -- Array of tags
  image_url TEXT,
  member_count INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. `community_members` Table

This table manages the many-to-many relationship between users and communities.

```sql
CREATE TABLE community_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'moderator', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(community_id, user_id)
);
```

## Indexes

Add these indexes for better query performance:

```sql
-- Communities indexes
CREATE INDEX idx_communities_creator_id ON communities(creator_id);
CREATE INDEX idx_communities_sport ON communities(sport);
CREATE INDEX idx_communities_is_private ON communities(is_private);
CREATE INDEX idx_communities_member_count ON communities(member_count DESC);
CREATE INDEX idx_communities_created_at ON communities(created_at DESC);
CREATE INDEX idx_communities_name_search ON communities USING gin(to_tsvector('english', name || ' ' || description));

-- Community members indexes
CREATE INDEX idx_community_members_community_id ON community_members(community_id);
CREATE INDEX idx_community_members_user_id ON community_members(user_id);
CREATE INDEX idx_community_members_joined_at ON community_members(joined_at DESC);
```

## Row Level Security (RLS) Policies

Enable RLS and create the following policies:

### Communities Table Policies

```sql
-- Enable RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read public communities
CREATE POLICY "Public communities are viewable by everyone" ON communities
  FOR SELECT USING (NOT is_private);

-- Allow authenticated users to read private communities they're members of
CREATE POLICY "Private communities viewable by members" ON communities
  FOR SELECT USING (
    is_private AND 
    auth.uid() IN (
      SELECT user_id FROM community_members 
      WHERE community_id = communities.id
    )
  );

-- Allow authenticated users to create communities
CREATE POLICY "Users can create communities" ON communities
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Allow community owners to update their communities
CREATE POLICY "Owners can update their communities" ON communities
  FOR UPDATE USING (auth.uid() = creator_id);

-- Allow community owners to delete their communities
CREATE POLICY "Owners can delete their communities" ON communities
  FOR DELETE USING (auth.uid() = creator_id);
```

### Community Members Table Policies

```sql
-- Enable RLS
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

-- Allow community members to view other members of their communities
CREATE POLICY "Community members can view other members" ON community_members
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM community_members cm
      WHERE cm.community_id = community_members.community_id
    )
  );

-- Allow users to join public communities
CREATE POLICY "Users can join public communities" ON community_members
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND NOT is_private
    )
  );

-- Allow community owners to add members to their communities
CREATE POLICY "Owners can add members" ON community_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );

-- Allow users to leave communities (except owners)
CREATE POLICY "Users can leave communities" ON community_members
  FOR DELETE USING (
    auth.uid() = user_id AND 
    role != 'owner'
  );

-- Allow community owners to remove members
CREATE POLICY "Owners can remove members" ON community_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );
```

## Database Functions (Optional)

You can create these functions for better performance and consistency:

### Update Member Count Function

```sql
CREATE OR REPLACE FUNCTION update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE communities 
    SET member_count = member_count + 1 
    WHERE id = NEW.community_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE communities 
    SET member_count = GREATEST(0, member_count - 1) 
    WHERE id = OLD.community_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER trigger_update_member_count_on_insert
  AFTER INSERT ON community_members
  FOR EACH ROW EXECUTE FUNCTION update_community_member_count();

CREATE TRIGGER trigger_update_member_count_on_delete
  AFTER DELETE ON community_members
  FOR EACH ROW EXECUTE FUNCTION update_community_member_count();
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

-- Create trigger for communities table
CREATE TRIGGER trigger_communities_updated_at
  BEFORE UPDATE ON communities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Setup Instructions

1. **Create the tables** by running the SQL statements above in your Supabase SQL editor.

2. **Enable RLS** on both tables and add the policies.

3. **Create indexes** for better performance.

4. **Optional: Add the triggers** for automatic member count updates and updated_at timestamps.

5. **Verify the setup** by testing basic operations:
   - Create a community
   - Join a community
   - Leave a community
   - Search communities

## Data Migration (If Needed)

If you have existing communities data, you may need to:

1. Migrate existing data to match the new schema
2. Update any foreign key references
3. Recalculate member counts

## Notes

- The `creator_username` and `creator_avatar_url` fields are denormalized for performance
- Community names should be unique (consider adding a unique constraint)
- The `tags` field uses PostgreSQL arrays for efficient querying
- Sports should use standardized values (NFL, NBA, MLB, NHL, etc.)
- Consider adding a `categories` or `topics` table for better organization if needed

## Testing Queries

Here are some example queries to test the setup:

```sql
-- Test creating a community
INSERT INTO communities (name, description, creator_id, creator_username)
VALUES ('Test Community', 'A test community', 'user-id-here', 'testuser');

-- Test joining a community
INSERT INTO community_members (community_id, user_id)
VALUES ('community-id-here', 'user-id-here');

-- Test searching communities
SELECT * FROM communities 
WHERE name ILIKE '%test%' AND NOT is_private 
ORDER BY member_count DESC;
``` 