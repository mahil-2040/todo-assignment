import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  Future<void> scheduleNotificationForTodo(TodoModel todo) async {
    try {
      if (todo.dueDate == null) {
        if (kDebugMode) {
          print('Cannot schedule notification for todo "${todo.title}" - no due date');
        }
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('Cannot schedule notification - no user logged in');
        }
        return;
      }

      final notificationTime = todo.dueDate!.subtract(const Duration(hours: 1));
      
      if (kDebugMode) {
        print('Todo "${todo.title}" due at: ${todo.dueDate!.toIso8601String()}');
        print('Notification would be scheduled for: ${notificationTime.toIso8601String()}');
        print('Current time: ${DateTime.now().toUtc().toIso8601String()}');
      }
      
      if (notificationTime.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('Notification time is in the past for todo: ${todo.title}');
        }
        return;
      }

      final notificationData = {
        'todo_id': todo.id,
        'user_id': user.id,
        'title': 'Todo Reminder',
        'body': 'Your task "${todo.title}" is due in 1 hour!',
        'scheduled_for': notificationTime.toUtc().toIso8601String(),
        'is_sent': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (kDebugMode) {
        print('Creating notification with data: $notificationData');
      }

      final existingNotification = await _supabase
          .from('scheduled_notifications')
          .select()
          .eq('todo_id', todo.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingNotification != null) {
        await _supabase
            .from('scheduled_notifications')
            .update(notificationData)
            .eq('id', existingNotification['id']);
        
        if (kDebugMode) {
          print('Updated existing notification for todo: ${todo.title}');
        }
      } else {
        final result = await _supabase
            .from('scheduled_notifications')
            .insert(notificationData)
            .select()
            .single();
        
        if (kDebugMode) {
          print('Created new notification: $result');
        }
      }

      if (kDebugMode) {
        print('Successfully scheduled notification for todo: ${todo.title} at $notificationTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> cancelNotificationForTodo(String todoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('scheduled_notifications')
          .delete()
          .eq('todo_id', todoId)
          .eq('user_id', user.id);

      if (kDebugMode) {
        print('Cancelled notification for todo: $todoId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling notification: $e');
      }
    }
  }

  Future<void> markTodoCompleted(String todoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('scheduled_notifications')
          .update({'is_sent': true})
          .eq('todo_id', todoId)
          .eq('user_id', user.id);

      if (kDebugMode) {
        print('Marked notification as completed for todo: $todoId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as completed: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications() async {
    try {
      final now = DateTime.now().toUtc();
      
      if (kDebugMode) {
        print('Looking for notifications scheduled before: ${now.toIso8601String()}');
      }
      
      final allNotifications = await _supabase
          .from('scheduled_notifications')
          .select('*')
          .eq('is_sent', false);
      
      if (kDebugMode) {
        print('Total unsent notifications in database: ${allNotifications.length}');
        for (var notif in allNotifications) {
          print('Notification: ${notif['title']} scheduled for ${notif['scheduled_for']}');
        }
      }
      
      final notifications = await _supabase
          .from('scheduled_notifications')
          .select('''
            *,
            todos!inner(title, is_completed, due_date)
          ''')
          .eq('is_sent', false)
          .lte('scheduled_for', now.toIso8601String())
          .eq('todos.is_completed', false);

      if (kDebugMode) {
        print('Pending notifications found: ${notifications.length}');
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending notifications: $e');
      }
      return [];
    }
  }

  /// Mark notification as sent
  Future<void> markNotificationAsSent(int notificationId) async {
    try {
      await _supabase
          .from('scheduled_notifications')
          .update({
            'is_sent': true,
            'sent_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', notificationId);

      if (kDebugMode) {
        print('Marked notification as sent: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as sent: $e');
      }
    }
  }

  /// Clean up old notifications (sent notifications older than 7 days)
  Future<void> cleanupOldNotifications() async {
    try {
      final cutoffDate = DateTime.now()
          .subtract(const Duration(days: 7))
          .toUtc()
          .toIso8601String();

      await _supabase
          .from('scheduled_notifications')
          .delete()
          .eq('is_sent', true)
          .lt('sent_at', cutoffDate);

      if (kDebugMode) {
        print('Cleaned up old notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old notifications: $e');
      }
    }
  }
}
