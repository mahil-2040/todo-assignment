import 'package:flutter_test/flutter_test.dart';
import 'package:todo_assignment/core/models/todo_model.dart';

void main() {
  group('TodoModel Timezone Tests', () {
    test('timeUntilDue should handle timezone correctly', () {
      // Create a todo with due date 5 minutes from now
      final now = DateTime.now();
      final fiveMinutesLater = now.add(const Duration(minutes: 5));
      
      final todo = TodoModel(
        id: '1',
        userId: 'user1',
        title: 'Test Todo',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: fiveMinutesLater,
        createdAt: now,
        updatedAt: now,
      );

      // Should show approximately 5 minutes (allow 4-5 minutes due to execution time)
      expect(todo.timeUntilDue.contains('minutes'), true);
      expect(todo.timeUntilDue, anyOf('4 minutes', '5 minutes'));
    });

    test('timeUntilDue should handle UTC conversion correctly', () {
      final now = DateTime.now();
      
      // Simulate a UTC date coming from the database
      final utcDueDate = now.add(const Duration(minutes: 3)).toUtc();
      
      // Create todo with UTC date (simulating data from database)
      final json = {
        'id': '1',
        'user_id': 'user1',
        'title': 'Test Todo',
        'description': null,
        'is_completed': false,
        'priority': 'medium',
        'due_date': utcDueDate.toIso8601String(),
        'created_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

      final todo = TodoModel.fromJson(json);
      
      // Should show approximately 3 minutes, not hours (allow 2-3 minutes due to execution time)
      expect(todo.timeUntilDue.contains('minutes'), true);
      expect(todo.timeUntilDue, anyOf('2 minutes', '3 minutes'));
      // Most importantly, should NOT contain 'hours'
      expect(todo.timeUntilDue.contains('hours'), false);
    });

    test('isOverdue should handle timezone correctly', () {
      final now = DateTime.now();
      final pastDue = now.subtract(const Duration(minutes: 10));
      
      final todo = TodoModel(
        id: '1',
        userId: 'user1',
        title: 'Test Todo',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: pastDue,
        createdAt: now,
        updatedAt: now,
      );

      expect(todo.isOverdue, true);
    });

    test('isDueSoon should handle timezone correctly', () {
      final now = DateTime.now();
      final soonDue = now.add(const Duration(hours: 2));
      
      final todo = TodoModel(
        id: '1',
        userId: 'user1',
        title: 'Test Todo',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: soonDue,
        createdAt: now,
        updatedAt: now,
      );

      expect(todo.isDueSoon, true);
    });

    test('timeUntilDue should show hours correctly', () {
      final now = DateTime.now();
      final hoursLater = now.add(const Duration(hours: 2, minutes: 30));
      
      final todo = TodoModel(
        id: '1',
        userId: 'user1',
        title: 'Test Todo',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: hoursLater,
        createdAt: now,
        updatedAt: now,
      );

      // Should show hours, not minutes when it's more than an hour away
      expect(todo.timeUntilDue, '2 hours');
    });
  });
}
