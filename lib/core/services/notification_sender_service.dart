import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'local_notification_service.dart';

/// This service handles the actual sending of push notifications
/// In a production app, this would typically run on a server/cloud function
/// For demo purposes, this can be called periodically from the app
class NotificationSenderService {
  static final NotificationSenderService _instance =
      NotificationSenderService._internal();
  factory NotificationSenderService() => _instance;
  NotificationSenderService._internal();

  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService();
  final _localNotificationService = LocalNotificationService();

  Timer? _notificationTimer;

  /// Start periodic checking for notifications to send
  void startNotificationScheduler(
      {Duration interval = const Duration(seconds: 30)}) {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(interval, (timer) {
      _checkAndSendNotifications();
    });

    if (kDebugMode) {
      print(
          'Notification scheduler started with ${interval.inSeconds} second intervals');
    }
  }

  // Stop the notification scheduler
  void stopNotificationScheduler() {
    _notificationTimer?.cancel();
    _notificationTimer = null;

    if (kDebugMode) {
      print('Notification scheduler stopped');
    }
  }

  // Check for pending notifications and send them
  Future<void> _checkAndSendNotifications() async {
    try {
      if (kDebugMode) {
        print('Checking for pending notifications...');
      }

      final pendingNotifications =
          await _notificationService.getPendingNotifications();

      if (pendingNotifications.isEmpty) {
        if (kDebugMode) {
          print('No pending notifications found');
        }
        return;
      }

      if (kDebugMode) {
        print('Found ${pendingNotifications.length} pending notifications');
      }

      for (final notification in pendingNotifications) {
        await _sendNotificationToUser(notification);
      }

      // Clean up old notifications periodically
      await _notificationService.cleanupOldNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for notifications: $e');
      }
    }
  }

  /// Send notification to a specific user
  Future<void> _sendNotificationToUser(
      Map<String, dynamic> notification) async {
    try {
      final userId = notification['user_id'];
      final notificationId = notification['id'];
      final title = notification['title'];
      final body = notification['body'];

      // Get user's device tokens
      final deviceTokens = await _supabase
          .from('device_tokens')
          .select('token')
          .eq('user_id', userId);

      if (deviceTokens.isEmpty) {
        if (kDebugMode) {
          print('No device tokens found for user: $userId');
        }
        // Mark as sent even though no tokens found to avoid retrying
        await _notificationService.markNotificationAsSent(notificationId);
        return;
      }

      // Send to all user devices
      bool anySent = false;
      for (final tokenData in deviceTokens) {
        final token = tokenData['token'];
        final sent = await _sendFcmNotification(token, title, body);
        if (sent) anySent = true;
      }

      if (anySent) {
        await _notificationService.markNotificationAsSent(notificationId);
        if (kDebugMode) {
          print('Sent notification: $title');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
    }
  }

  Future<bool> _sendFcmNotification(
      String token, String title, String body) async {
    try {
      // Use local notifications as a fallback for demo purposes
      await _localNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: 'todo_reminder',
      );
      
      if (kDebugMode) {
        print('Local notification sent:');
        print('Title: $title');
        print('Body: $body');
      }
      
      return true;
    } catch (e) {
      print("Error sending notification: $e");
    }
    return false;
  }

  /// Manually trigger notification check (useful for testing)
  Future<void> checkNowForTesting() async {
    if (kDebugMode) {
      print('Manually checking for notifications...');
    }
    await _checkAndSendNotifications();
  }

  /// Test method to create a test notification (for debugging)
  Future<void> createTestNotification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No user logged in for test notification');
        return;
      }

      // Create a test notification that should be sent immediately
      final testNotification = {
        'user_id': user.id,
        'title': 'Test Notification',
        'body': 'This is a test notification to verify the system is working!',
        'scheduled_for': DateTime.now().toUtc().toIso8601String(),
        'is_sent': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      print('Creating test notification...');
      final result = await _supabase
          .from('scheduled_notifications')
          .insert(testNotification)
          .select()
          .single();

      print('Test notification created: $result');
      print('Checking for pending notifications...');
      await checkNowForTesting();
    } catch (e) {
      print('Error creating test notification: $e');
    }
  }

  /// Create a test notification for a todo that should trigger soon
  Future<void> createTestTodoNotification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('No user logged in for test notification');
        return;
      }

      // Create a test notification that should trigger in 10 seconds
      final testTime = DateTime.now().add(const Duration(seconds: 10));
      final testNotification = {
        'user_id': user.id,
        'title': 'Todo Reminder Test',
        'body': 'Your test task is due soon!',
        'scheduled_for': testTime.toUtc().toIso8601String(),
        'is_sent': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      print('Creating test todo notification for: ${testTime.toIso8601String()}');
      final result = await _supabase
          .from('scheduled_notifications')
          .insert(testNotification)
          .select()
          .single();

      print('Test todo notification created: $result');
      print('This notification should trigger in 10 seconds...');
    } catch (e) {
      print('Error creating test todo notification: $e');
    }
  }
}
