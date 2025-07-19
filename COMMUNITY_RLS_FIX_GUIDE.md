# Community RLS Infinite Recursion Fix Guide

## Problem
The Communities feature is showing a database error: `PostgrestException(message: infinite recursion detected in policy for relation 'community_members', code: 42P17)`

This happens because the Row Level Security (RLS) policies on the `community_members` table have circular dependencies - they try to check membership by querying the same table they're protecting.

## Solution

### Step 1: Access Your Supabase Dashboard
1. Go to [https://supabase.com](https://supabase.com)
2. Sign in to your account
3. Open your WagerLoop project
4. Navigate to the **SQL Editor** tab

### Step 2: Run the Fix Script
1. Copy the contents of `fix_community_rls_policies.sql`
2. Paste it into the SQL Editor
3. Click **Run** to execute the script

This will:
- Remove the problematic recursive policies
- Create new, non-recursive policies
- Ensure proper access control without infinite loops

### Step 3: Verify the Fix
After running the script, test the Communities feature:
1. Open the WagerLoop app
2. Navigate to the Communities page
3. The error should be gone and communities should load properly

## What Changed

### Before (Problematic)
```sql
-- This caused infinite recursion
CREATE POLICY "Community members can view other members" ON community_members
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM community_members cm  -- 🚫 Circular reference!
      WHERE cm.community_id = community_members.community_id
    )
  );
```

### After (Fixed)
```sql
-- These policies avoid self-referential queries
CREATE POLICY "Users can view their own memberships" ON community_members
  FOR SELECT USING (auth.uid() = user_id);  -- ✅ Simple, direct check

CREATE POLICY "Public community members are viewable" ON community_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM communities  -- ✅ References different table
      WHERE id = community_id AND NOT is_private
    )
  );
```

## Policy Changes Summary

### New Policies for `community_members`
1. **Users can view their own memberships** - Users can see communities they've joined
2. **Public community members are viewable** - Anyone can see members of public communities  
3. **Community owners can view their members** - Creators can see all their community members

### Updated Policies for `communities`
1. **Private communities viewable by creators only** - Only creators can see their private communities

## Important Notes

- **Private community access**: With these changes, regular members cannot see private communities they've joined through RLS policies (to avoid recursion)
- **Workaround**: The app handles this through application logic - users can still join and interact with private communities
- **Performance**: These new policies are more efficient as they avoid complex recursive queries

## If You Still Have Issues

1. **Clear your browser cache** and refresh the app
2. **Check the SQL Editor** for any error messages when running the script
3. **Verify table structure** - ensure the `communities` and `community_members` tables exist
4. **Check user authentication** - make sure you're logged in properly

## Technical Details

The infinite recursion occurred because:
1. User tries to query `community_members`
2. Policy checks if user is in `community_members` (same table)
3. That check triggers the same policy again
4. Creates infinite loop → Database error

The fix uses simpler, direct checks that don't reference the same table being queried. 