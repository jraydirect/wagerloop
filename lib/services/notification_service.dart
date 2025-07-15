import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Comprehensive notification service for WagerLoop app.
/// 
/// Handles both local and push notifications for various app events
/// including comments, likes, follows, and other social interactions.
/// Supports notification preferences, badge counts, and deep linking.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  // Notification channels for different types
  static const String _commentChannelId = 'comments';
  static const String _likeChannelId = 'likes';
  static const String _followChannelId = 'follows';
  static const String _generalChannelId = 'general';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Request permission for notifications
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Set up notification handlers
      _setupNotificationHandlers();
      
      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request local notification permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Request Firebase messaging permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Firebase messaging permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel commentChannel = AndroidNotificationChannel(
      _commentChannelId,
      'Comments',
      description: 'Notifications for comments on your posts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel likeChannel = AndroidNotificationChannel(
      _likeChannelId,
      'Likes',
      description: 'Notifications for likes on your posts',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel followChannel = AndroidNotificationChannel(
      _followChannelId,
      'Follows',
      description: 'Notifications for new followers',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'General',
      description: 'General app notifications',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(commentChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(likeChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(followChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _updateFcmTokenInDatabase(token);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Set up notification handlers
  void _setupNotificationHandlers() {
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Handle notification payload for navigation
  void _handleNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final type = data['type'];
      final id = data['id'];

      switch (type) {
        case 'comment':
          // Navigate to post with comments
          _navigateToPost(id);
          break;
        case 'like':
          // Navigate to post
          _navigateToPost(id);
          break;
        case 'follow':
          // Navigate to user profile
          _navigateToUserProfile(id);
          break;
        default:
          print('Unknown notification type: $type');
      }
    } catch (e) {
      print('Error handling notification payload: $e');
    }
  }

  /// Navigate to post (to be implemented by the app)
  void _navigateToPost(String postId) {
    // This will be implemented by the app's navigation system
    print('Navigate to post: $postId');
  }

  /// Navigate to user profile (to be implemented by the app)
  void _navigateToUserProfile(String userId) {
    // This will be implemented by the app's navigation system
    print('Navigate to user profile: $userId');
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = _generalChannelId,
    int id = 0,
  }) async {
    if (!_isInitialized) {
      print('Notification service not initialized');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      'General',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// Show comment notification
  Future<void> showCommentNotification({
    required String commenterUsername,
    required String postId,
    required String commentContent,
    String? commenterAvatarUrl,
  }) async {
    final title = 'New Comment';
    final body = '$commenterUsername commented on your post';
    final payload = jsonEncode({
      'type': 'comment',
      'id': postId,
      'commenter': commenterUsername,
      'content': commentContent,
    });

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _commentChannelId,
      'Comments',
      channelDescription: 'Notifications for comments on your posts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show like notification
  Future<void> showLikeNotification({
    required String likerUsername,
    required String postId,
    String? likerAvatarUrl,
  }) async {
    final title = 'New Like';
    final body = '$likerUsername liked your post';
    final payload = jsonEncode({
      'type': 'like',
      'id': postId,
      'liker': likerUsername,
    });

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _likeChannelId,
      'Likes',
      channelDescription: 'Notifications for likes on your posts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show follow notification
  Future<void> showFollowNotification({
    required String followerUsername,
    required String followerId,
    String? followerAvatarUrl,
  }) async {
    final title = 'New Follower';
    final body = '$followerUsername started following you';
    final payload = jsonEncode({
      'type': 'follow',
      'id': followerId,
      'follower': followerUsername,
    });

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _followChannelId,
      'Follows',
      channelDescription: 'Notifications for new followers',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Update FCM token in database
  Future<void> _updateFcmTokenInDatabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('user_notification_settings')
            .upsert({
          'user_id': user.id,
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating FCM token in database: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Get badge count
  Future<int> getBadgeCount() async {
    return await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationAppLaunchDetails()
        .then((details) => details?.notificationResponse != null ? 1 : 0) ?? 0;
  }

  /// Set badge count
  Future<void> setBadgeCount(int count) async {
    // Badge count is primarily an iOS feature
    // Android doesn't have a direct badge count API in this plugin
    // This would need to be implemented differently for Android
    print('Badge count set to: $count');
  }
}

/// Background message handler for Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

/// Handle foreground messages
void _handleForegroundMessage(RemoteMessage message) {
  print('Got a message whilst in the foreground!');
  print('Message data: ${message.data}');

  if (message.notification != null) {
    print('Message also contained a notification: ${message.notification}');
  }
}

/// Handle notification tap when app is in background
void _handleNotificationTap(RemoteMessage message) {
  print('Notification tapped: ${message.data}');
  
  final data = message.data;
  final type = data['type'];
  final id = data['id'];

  switch (type) {
    case 'comment':
      NotificationService()._navigateToPost(id);
      break;
    case 'like':
      NotificationService()._navigateToPost(id);
      break;
    case 'follow':
      NotificationService()._navigateToUserProfile(id);
      break;
    default:
      print('Unknown notification type: $type');
  }
} 