import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_data_service.dart';
import '../services/supabase_config.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationDataService _notificationService = NotificationDataService(SupabaseConfig.supabase);
  
  NotificationSettings? _settings;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize settings if they don't exist
      final settings = await _notificationService.initializeNotificationSettings();

      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notification settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String settingName, bool value) async {
    if (_settings == null) return;

    try {
      final updatedSettings = await _notificationService.upsertNotificationSettings(
        commentNotifications: settingName == 'comment' ? value : _settings!.commentNotifications,
        likeNotifications: settingName == 'like' ? value : _settings!.likeNotifications,
        followNotifications: settingName == 'follow' ? value : _settings!.followNotifications,
        generalNotifications: settingName == 'general' ? value : _settings!.generalNotifications,
      );

      setState(() {
        _settings = updatedSettings;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${settingName.capitalize()} notifications ${value ? 'enabled' : 'disabled'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required String settingName,
    required IconData icon,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.grey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) => _updateSetting(settingName, newValue),
        activeColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
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
                        onPressed: _loadSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _settings == null
                  ? const Center(
                      child: Text(
                        'No settings found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  title: 'Comment Notifications',
                                  subtitle: 'Get notified when someone comments on your posts',
                                  value: _settings!.commentNotifications,
                                  settingName: 'comment',
                                  icon: Icons.comment,
                                  iconColor: Colors.blue,
                                ),
                                const Divider(height: 1),
                                _buildSettingTile(
                                  title: 'Like Notifications',
                                  subtitle: 'Get notified when someone likes your posts',
                                  value: _settings!.likeNotifications,
                                  settingName: 'like',
                                  icon: Icons.favorite,
                                  iconColor: Colors.red,
                                ),
                                const Divider(height: 1),
                                _buildSettingTile(
                                  title: 'Follow Notifications',
                                  subtitle: 'Get notified when someone follows you',
                                  value: _settings!.followNotifications,
                                  settingName: 'follow',
                                  icon: Icons.person_add,
                                  iconColor: Colors.green,
                                ),
                                const Divider(height: 1),
                                _buildSettingTile(
                                  title: 'General Notifications',
                                  subtitle: 'Get notified about app updates and announcements',
                                  value: _settings!.generalNotifications,
                                  settingName: 'general',
                                  icon: Icons.notifications,
                                  iconColor: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'About Notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'You can control which types of notifications you receive. '
                                    'Disabling a notification type will prevent you from receiving '
                                    'those notifications, but you can always re-enable them later.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Notifications are sent to your device and can also be viewed in the app.',
                                          style: TextStyle(
                                            color: Colors.blue[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 