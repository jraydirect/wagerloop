import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification.dart';
import '../services/notification_data_service.dart';
import '../services/supabase_config.dart';
import '../widgets/profile_avatar.dart';
import 'social_feed_page.dart';
import 'user_profile_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationDataService _notificationService = NotificationDataService(SupabaseConfig.supabase);
  
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealTimeUpdates();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final notifications = await _notificationService.fetchUserNotifications();
      final unreadCount = await _notificationService.getUnreadNotificationCount();

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  void _setupRealTimeUpdates() {
    _notificationService.subscribeToNotifications().listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    });

    _notificationService.subscribeToUnreadCount().listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    });
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markNotificationsAsRead();
      await _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notifications as read: $e')),
      );
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markNotificationAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read first
    await _markAsRead(notification);

    // Navigate based on notification type
    switch (notification.type) {
      case 'comment':
        if (notification.postId != null) {
          _navigateToPost(notification.postId!);
        }
        break;
      case 'like':
        if (notification.postId != null) {
          _navigateToPost(notification.postId!);
        }
        break;
      case 'follow':
        if (notification.followerId != null) {
          _navigateToUserProfile(notification.followerId!);
        }
        break;
      default:
        print('Unknown notification type: ${notification.type}');
    }
  }

  void _navigateToPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SocialFeedPage(),
      ),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: userId),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    switch (notification.type) {
      case 'comment':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.comment,
            color: Colors.blue,
            size: 20,
          ),
        );
      case 'like':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 20,
          ),
        );
      case 'follow':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_add,
            color: Colors.green,
            size: 20,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications,
            color: Colors.grey,
            size: 20,
          ),
        );
    }
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return ListTile(
      leading: _buildNotificationIcon(notification),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          color: notification.isRead ? Colors.grey[600] : Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.body,
            style: TextStyle(
              color: notification.isRead ? Colors.grey[600] : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeago.format(notification.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
      onTap: () => _handleNotificationTap(notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You\'ll see notifications here when people interact with your posts',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: _buildNotificationTile(notification),
                          );
                        },
                      ),
                    ),
    );
  }
} 