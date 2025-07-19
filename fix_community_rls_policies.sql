-- Fix Community RLS Policies - Infinite Recursion Bug Fix
-- Run this in your Supabase SQL Editor to fix the infinite recursion issue

-- First, drop the problematic policies that cause infinite recursion
DROP POLICY IF EXISTS "Community members can view other members" ON community_members;
DROP POLICY IF EXISTS "Private communities viewable by members" ON communities;

-- Fix the community_members policies with non-recursive approaches
-- Policy 1: Users can view their own memberships (simple, no recursion)
CREATE POLICY "Users can view their own memberships" ON community_members
  FOR SELECT USING (auth.uid() = user_id);

-- Policy 2: Allow reading community_members for public communities
CREATE POLICY "Public community members are viewable" ON community_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND NOT is_private
    )
  );

-- Policy 3: Community owners can view all members of their communities
CREATE POLICY "Community owners can view their members" ON community_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );

-- Fix the communities table policy to avoid recursion as well
-- This policy allows viewing private communities only if user is the creator
CREATE POLICY "Private communities viewable by creators only" ON communities
  FOR SELECT USING (
    NOT is_private OR auth.uid() = creator_id
  );

-- Alternative approach: If you need members to see private communities they joined,
-- you'll need to handle this in application logic rather than RLS to avoid recursion

-- Ensure the basic policies for community_members operations are correct
-- Policy for joining communities (non-recursive)
DROP POLICY IF EXISTS "Users can join public communities" ON community_members;
CREATE POLICY "Users can join public communities" ON community_members
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND NOT is_private
    )
  );

-- Policy for leaving communities (non-recursive)
DROP POLICY IF EXISTS "Users can leave communities" ON community_members;
CREATE POLICY "Users can leave communities" ON community_members
  FOR DELETE USING (
    auth.uid() = user_id AND 
    role != 'owner'
  );

-- Policy for owners to manage members (non-recursive)
DROP POLICY IF EXISTS "Owners can add members" ON community_members;
CREATE POLICY "Owners can add members" ON community_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Owners can remove members" ON community_members;
CREATE POLICY "Owners can remove members" ON community_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM communities 
      WHERE id = community_id AND creator_id = auth.uid()
    )
  );

-- Verify the policies are working
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('communities', 'community_members') 
ORDER BY tablename, policyname; 