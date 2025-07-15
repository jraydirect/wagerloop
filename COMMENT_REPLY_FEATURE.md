# Comment Reply Feature Implementation

## Overview
This update adds threaded comment replies to the WagerLoop social feed, allowing users to engage in deeper discussions by replying to specific comments.

## New Features

### 1. Threaded Comments
- Users can now reply to any comment in the social feed
- Replies are visually nested under their parent comments
- Clear visual hierarchy with indentation and reply indicators

### 2. Reply Interface
- "Reply" button on each comment
- Inline reply input field that appears when replying
- Shows "Replying to [username]" indicator
- Cancel reply option with X button

### 3. Visual Indicators
- Reply icon (↩️) next to usernames for replies
- Reply count display for comments with replies
- Indented layout for nested replies
- Color-coded reply indicators (green for reply targets)

## Database Changes

### New Columns Added to `comments` Table:
- `parent_comment_id`: UUID reference to parent comment (for replies)
- `reply_to_username`: VARCHAR storing the username being replied to
- `reply_count`: INTEGER tracking number of replies to a comment

### Database Triggers:
- Automatic reply count updates when replies are added/removed
- Cascading deletes for replies when parent comments are deleted

### Indexes:
- `idx_comments_parent_id`: For efficient reply queries

## Code Changes

### 1. Comment Model Updates (`lib/models/comment.dart`)
- Added `parentCommentId`, `replyToUsername`, `replyCount`, and `replies` fields
- Added helper methods: `isReply` and `hasReplies`
- Updated serialization methods to handle new fields

### 2. Social Feed Service Updates (`lib/services/social_feed_service.dart`)
- Enhanced `addComment()` method to support replies
- Updated `fetchComments()` to organize comments into threaded structure
- Added `_organizeCommentsIntoThreads()` helper method
- Added `fetchCommentReplies()` method for loading specific comment replies

### 3. New Threaded Comments Widget (`lib/widgets/threaded_comments_widget.dart`)
- Complete rewrite of comment display system
- Supports nested reply display with proper indentation
- Inline reply functionality with real-time updates
- Improved UI with cards and better visual hierarchy

### 4. Social Feed Page Updates (`lib/pages/social_feed_page.dart`)
- Integrated new `ThreadedCommentsWidget`
- Removed old comment display logic
- Updated comment modal to use threaded display

## User Experience

### Adding Comments:
1. Click comment icon on any post
2. Type comment in the input field at bottom
3. Click send button to post

### Replying to Comments:
1. Click "Reply" button on any comment
2. Reply input field appears inline
3. Type your reply (shows "Replying to [username]")
4. Click send to post reply
5. Click X to cancel reply

### Visual Features:
- Replies are indented under parent comments
- Reply indicators show who you're replying to
- Reply counts show how many replies a comment has
- Clean card-based design for better readability

## Technical Implementation

### Threading Logic:
```dart
List<Comment> _organizeCommentsIntoThreads(List<Comment> comments) {
  // Creates a map of all comments
  // Organizes replies under parent comments
  // Returns top-level comments with nested replies
}
```

### Reply Creation:
```dart
await _socialFeedService.addComment(
  postId,
  content,
  parentCommentId: commentId,
  replyToUsername: username,
);
```

### Real-time Updates:
- Comment counts update immediately
- Reply counts update automatically
- UI refreshes to show new replies

## Database Migration

Run the following SQL in your Supabase SQL Editor:

```sql
-- Add reply columns
ALTER TABLE comments 
ADD COLUMN IF NOT EXISTS parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS reply_to_username VARCHAR(255),
ADD COLUMN IF NOT EXISTS reply_count INTEGER DEFAULT 0;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id);

-- Add triggers for reply count updates
-- (See comment_replies_migration.sql for full implementation)
```

## Future Enhancements

### Potential Improvements:
1. **Reply Notifications**: Notify users when their comments receive replies
2. **Reply Likes**: Add ability to like individual replies
3. **Reply Search**: Search through replies within a post
4. **Reply Pagination**: Load replies on demand for very long threads
5. **Reply Moderation**: Report inappropriate replies
6. **Reply Analytics**: Track reply engagement metrics

### Performance Optimizations:
1. **Lazy Loading**: Load replies only when expanded
2. **Caching**: Cache frequently accessed comment threads
3. **Virtual Scrolling**: For posts with many comments/replies
4. **Real-time Replies**: Live reply updates without page refresh

## Testing Recommendations

### Test Cases:
1. **Basic Reply Functionality**: Verify replies are created and displayed correctly
2. **Threading**: Ensure replies appear under correct parent comments
3. **Reply Counts**: Verify reply counts update accurately
4. **Nested Replies**: Test multiple levels of replies
5. **Reply Cancellation**: Test canceling reply input
6. **Real-time Updates**: Test reply updates in real-time
7. **Error Handling**: Test behavior when reply creation fails

### Manual Testing:
1. Create a post and add comments
2. Reply to different comments
3. Verify reply threading and indentation
4. Test reply counts and indicators
5. Test canceling replies
6. Verify real-time updates work

## Security Considerations

### Row Level Security (RLS):
- Users can only view all comments (including replies)
- Users can only create replies for their own account
- Users can only update/delete their own replies
- Proper foreign key constraints prevent orphaned replies

### Data Validation:
- Reply content is validated before saving
- Username references are validated
- Parent comment existence is verified

This implementation provides a solid foundation for threaded discussions in WagerLoop while maintaining good performance and user experience. 