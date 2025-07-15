# Notification System Implementation

## Overview

This document describes the comprehensive notification system implemented for the WagerLoop app. The system provides both local and push notifications for various user interactions, with a focus on comment notifications as requested.

## Features

### 1. Comment Notifications
- Users receive notifications when someone comments on their posts
- Includes commenter username and comment content
- Navigate directly to the post when tapped
- Real-time updates via database triggers

### 2. Extensible Architecture
- Easy to add new notification types (likes, follows, etc.)
- Modular service design for maintainability
- Database-driven notification storage
- User preference management

### 3. User Control
- Granular notification settings
- Enable/disable specific notification types
- Mark notifications as read
- Clear notification history

## Architecture

### Services

#### 1. NotificationService (`lib/services/notification_service.dart`)
- Handles local and push notifications
- Firebase Cloud Messaging integration
- Notification channel management
- Permission handling

#### 2. NotificationDataService (`lib/services/notification_data_service.dart`)
- Database operations for notifications
- User settings management
- Real-time subscription handling
- CRUD operations for notifications

### Models

#### 1. AppNotification (`lib/models/notification.dart`)
- Represents individual notifications
- Type-specific data access methods
- Serialization/deserialization

#### 2. NotificationSettings (`lib/models/notification.dart`)
- User notification preferences
- FCM token management
- Settings persistence

### Pages

#### 1. NotificationsPage (`lib/pages/notifications_page.dart`)
- Display user notifications
- Mark as read functionality
- Navigation to related content
- Real-time updates

#### 2. NotificationSettingsPage (`lib/pages/notification_settings_page.dart`)
- Manage notification preferences
- Toggle notification types
- User-friendly interface

## Database Schema

### Tables

#### 1. user_notification_settings
```sql
CREATE TABLE user_notification_settings (
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
```

#### 2. notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Triggers

#### Comment Notification Trigger
```sql
CREATE OR REPLACE FUNCTION send_comment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Get post author and commenter info
  -- Insert notification for post author
  -- Skip if commenting on own post
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_send_comment_notification
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION send_comment_notification();
```

## Setup Instructions

### 1. Dependencies
Add the following to `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^16.3.2
  firebase_messaging: ^14.7.20
  firebase_core: ^2.24.2
```

### 2. Database Migration
Run the SQL migration in your Supabase SQL Editor:
```sql
-- See notification_settings_migration.sql for complete migration
```

### 3. Firebase Setup
1. Create a Firebase project
2. Add your app to Firebase
3. Download and add the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

### 4. Initialize Services
In your main app initialization:
```dart
// Initialize notification service
await NotificationService().initialize();

// Initialize notification data service
final notificationDataService = NotificationDataService(SupabaseConfig.supabase);
```

## Usage Examples

### 1. Sending a Comment Notification
```dart
// This is handled automatically by the database trigger
// But you can also send local notifications:

await NotificationService().showCommentNotification(
  commenterUsername: 'john_doe',
  postId: 'post-uuid',
  commentContent: 'Great pick!',
);
```

### 2. Fetching User Notifications
```dart
final notifications = await notificationDataService.fetchUserNotifications(
  limit: 20,
  unreadOnly: false,
);
```

### 3. Updating Notification Settings
```dart
await notificationDataService.upsertNotificationSettings(
  commentNotifications: true,
  likeNotifications: false,
  followNotifications: true,
);
```

### 4. Marking Notifications as Read
```dart
// Mark single notification
await notificationDataService.markNotificationAsRead('notification-id');

// Mark all notifications
await notificationDataService.markNotificationsAsRead();
```

## Integration Points

### 1. Social Feed Integration
The notification system is integrated into the social feed service:
- Comment creation triggers notifications
- Real-time updates for new notifications
- Navigation to posts from notifications

### 2. Navigation Integration
Notifications can navigate to:
- Post details (for comment/like notifications)
- User profiles (for follow notifications)
- General app sections (for general notifications)

### 3. Real-time Updates
- Database triggers create notifications
- Real-time subscriptions update UI
- Badge counts update automatically

## User Experience

### 1. Notification Flow
1. User receives comment on their post
2. Database trigger creates notification
3. Local notification appears on device
4. User can tap to navigate to post
5. Notification marked as read

### 2. Settings Management
1. User accesses notification settings
2. Toggles specific notification types
3. Changes saved to database
4. Settings applied immediately

### 3. Notification Display
- Clean, card-based design
- Type-specific icons and colors
- Read/unread status indicators
- Timestamp information

## Security Considerations

### 1. Row Level Security (RLS)
- Users can only access their own notifications
- Settings are user-specific
- Proper authentication checks

### 2. Data Privacy
- Notification data is encrypted in transit
- FCM tokens are securely stored
- User preferences are respected

### 3. Permission Handling
- Explicit permission requests
- Graceful degradation if permissions denied
- Clear user feedback

## Testing

### 1. Manual Testing
- Create posts and comments
- Verify notification creation
- Test notification settings
- Check navigation functionality

### 2. Automated Testing
- Unit tests for services
- Widget tests for UI components
- Integration tests for database operations

## Future Enhancements

### 1. Additional Notification Types
- Like notifications
- Follow notifications
- Betting result notifications
- Achievement notifications

### 2. Advanced Features
- Notification grouping
- Custom notification sounds
- Scheduled notifications
- Rich media notifications

### 3. Analytics
- Notification engagement tracking
- User preference analytics
- Performance monitoring

## Troubleshooting

### Common Issues

#### 1. Notifications Not Appearing
- Check Firebase configuration
- Verify notification permissions
- Check database triggers
- Review notification settings

#### 2. Database Errors
- Verify RLS policies
- Check table structure
- Review trigger functions
- Monitor error logs

#### 3. Navigation Issues
- Verify notification data structure
- Check navigation routes
- Review error handling

### Debug Information
- Enable debug logging in notification services
- Monitor Firebase console for FCM issues
- Check Supabase logs for database errors
- Review device notification settings

## Support

For issues or questions about the notification system:
1. Check this documentation
2. Review the code comments
3. Test with the provided examples
4. Check the troubleshooting section

## Conclusion

The notification system provides a robust, scalable foundation for user engagement in the WagerLoop app. It's designed to be easily extensible and maintainable, with a focus on user experience and performance. 