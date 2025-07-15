import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

/// Service for managing notification data in the database.
/// 
/// Handles fetching, creating, and updating notifications and
/// user notification settings in Supabase.
class NotificationDataService {
  final SupabaseClient _supabase;

  NotificationDataService(this._supabase);

  /// Fetch user's notifications
  Future<List<AppNotification>> fetchUserNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      List<AppNotification> notifications = (response as List<dynamic>)
          .map((notification) => AppNotification.fromDatabaseRow(notification))
          .toList();

      // Filter unread notifications if requested
      if (unreadOnly) {
        notifications = notifications.where((n) => !n.isRead).toList();
      }

      return notifications;
    } catch (e) {
      print('Error fetching user notifications: $e');
      rethrow;
    }
  }

  /// Fetch user's notification settings
  Future<NotificationSettings?> fetchUserNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final response = await _supabase
          .from('user_notification_settings')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return NotificationSettings.fromDatabaseRow(response);
    } catch (e) {
      print('Error fetching user notification settings: $e');
      rethrow;
    }
  }

  /// Create or update user notification settings
  Future<NotificationSettings> upsertNotificationSettings({
    String? fcmToken,
    bool? commentNotifications,
    bool? likeNotifications,
    bool? followNotifications,
    bool? generalNotifications,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final updateData = <String, dynamic>{
        'user_id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fcmToken != null) updateData['fcm_token'] = fcmToken;
      if (commentNotifications != null) updateData['comment_notifications'] = commentNotifications;
      if (likeNotifications != null) updateData['like_notifications'] = likeNotifications;
      if (followNotifications != null) updateData['follow_notifications'] = followNotifications;
      if (generalNotifications != null) updateData['general_notifications'] = generalNotifications;

      final response = await _supabase
          .from('user_notification_settings')
          .upsert(updateData)
          .select()
          .single();

      return NotificationSettings.fromDatabaseRow(response);
    } catch (e) {
      print('Error upserting notification settings: $e');
      rethrow;
    }
  }

  /// Mark notifications as read
  Future<int> markNotificationsAsRead({List<String>? notificationIds}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      var query = _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', user.id);

      if (notificationIds != null && notificationIds.isNotEmpty) {
        query = query.in_('id', notificationIds);
      }

      final response = await query;

      return response.length;
    } catch (e) {
      print('Error marking notifications as read: $e');
      rethrow;
    }
  }

  /// Mark a single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      await _supabase
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.id);

      // Filter unread notifications manually
      int count = 0;
      for (final notification in response) {
        if (notification['read_at'] == null) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all user notifications
  Future<void> deleteAllUserNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      print('Error deleting all user notifications: $e');
      rethrow;
    }
  }

  /// Create a notification manually (for testing or custom notifications)
  Future<AppNotification> createNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? targetUserId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      final userId = targetUserId ?? user.id;

      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'type': type,
            'title': title,
            'body': body,
            'data': data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return AppNotification.fromDatabaseRow(response);
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Check if user has notification settings
  Future<bool> hasNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_notification_settings')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  /// Initialize default notification settings for user
  Future<NotificationSettings> initializeNotificationSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Check if settings already exist
      final existing = await hasNotificationSettings();
      if (existing) {
        final settings = await fetchUserNotificationSettings();
        if (settings == null) {
          throw 'Failed to fetch existing notification settings';
        }
        return settings;
      }

      // Create default settings
      return await upsertNotificationSettings();
    } catch (e) {
      print('Error initializing notification settings: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time notification updates
  Stream<List<AppNotification>> subscribeToNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at')
        .map((event) => event
            .map((notification) => AppNotification.fromDatabaseRow(notification))
            .toList());
  }

  /// Subscribe to unread notification count updates
  Stream<int> subscribeToUnreadCount() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((event) {
          int count = 0;
          for (final notification in event) {
            if (notification['read_at'] == null) {
              count++;
            }
          }
          return count;
        });
  }
} 