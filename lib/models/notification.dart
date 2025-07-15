// lib/models/notification.dart
import 'dart:convert';

/// Model representing a notification in the WagerLoop app.
/// 
/// Handles different types of notifications including comments,
/// likes, follows, and general notifications with associated data.
class AppNotification {
  final String id;
  final String userId;
  final String type; // 'comment', 'like', 'follow', 'general'
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  /// Check if the notification has been read
  bool get isRead => readAt != null;

  /// Get notification data as a specific type
  T? getData<T>(String key) {
    if (data == null) return null;
    final value = data![key];
    if (value is T) return value;
    return null;
  }

  /// Get comment-specific data
  String? get commenterUsername => getData<String>('commenter_username');
  String? get commentContent => getData<String>('comment_content');
  String? get postId => getData<String>('post_id');
  String? get commentId => getData<String>('comment_id');

  /// Get like-specific data
  String? get likerUsername => getData<String>('liker_username');

  /// Get follow-specific data
  String? get followerUsername => getData<String>('follower_username');
  String? get followerId => getData<String>('follower_id');

  /// Create a copy of the notification with modified properties
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert notification to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert notification to JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Create a notification from a map
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['user_id'],
      type: map['type'],
      title: map['title'],
      body: map['body'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Create a notification from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification.fromMap(json);
  }

  /// Create a notification from database row
  factory AppNotification.fromDatabaseRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'],
      userId: row['user_id'],
      type: row['type'],
      title: row['title'],
      body: row['body'],
      data: row['data'] != null ? Map<String, dynamic>.from(row['data']) : null,
      readAt: row['read_at'] != null ? DateTime.parse(row['read_at']) : null,
      createdAt: DateTime.parse(row['created_at']),
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model representing user notification settings
class NotificationSettings {
  final String id;
  final String userId;
  final String? fcmToken;
  final bool commentNotifications;
  final bool likeNotifications;
  final bool followNotifications;
  final bool generalNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettings({
    required this.id,
    required this.userId,
    this.fcmToken,
    this.commentNotifications = true,
    this.likeNotifications = true,
    this.followNotifications = true,
    this.generalNotifications = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of the settings with modified properties
  NotificationSettings copyWith({
    String? id,
    String? userId,
    String? fcmToken,
    bool? commentNotifications,
    bool? likeNotifications,
    bool? followNotifications,
    bool? generalNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      likeNotifications: likeNotifications ?? this.likeNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      generalNotifications: generalNotifications ?? this.generalNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert settings to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'fcm_token': fcmToken,
      'comment_notifications': commentNotifications,
      'like_notifications': likeNotifications,
      'follow_notifications': followNotifications,
      'general_notifications': generalNotifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert settings to JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// Create settings from a map
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      id: map['id'],
      userId: map['user_id'],
      fcmToken: map['fcm_token'],
      commentNotifications: map['comment_notifications'] ?? true,
      likeNotifications: map['like_notifications'] ?? true,
      followNotifications: map['follow_notifications'] ?? true,
      generalNotifications: map['general_notifications'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Create settings from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings.fromMap(json);
  }

  /// Create settings from database row
  factory NotificationSettings.fromDatabaseRow(Map<String, dynamic> row) {
    return NotificationSettings(
      id: row['id'],
      userId: row['user_id'],
      fcmToken: row['fcm_token'],
      commentNotifications: row['comment_notifications'] ?? true,
      likeNotifications: row['like_notifications'] ?? true,
      followNotifications: row['follow_notifications'] ?? true,
      generalNotifications: row['general_notifications'] ?? true,
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
    );
  }

  @override
  String toString() {
    return 'NotificationSettings(userId: $userId, commentNotifications: $commentNotifications, likeNotifications: $likeNotifications)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 