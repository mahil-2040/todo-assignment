import 'package:flutter_test/flutter_test.dart';
import 'package:todo_assignment/core/models/todo_model.dart';

void main() {
  test('timezone fix verification', () {
    // Test 1: Simple local time calculation
    final now = DateTime.now();
    final dueIn5Minutes = now.add(const Duration(minutes: 5));
    
    final todo = TodoModel(
      id: '1',
      userId: 'user1',
      title: 'Test Todo',
      isCompleted: false,
      priority: TaskPriority.medium,
      dueDate: dueIn5Minutes,
      createdAt: now,
      updatedAt: now,
    );
    
    print('Local Time Test:');
    print('Current time: $now');
    print('Due time: $dueIn5Minutes');
    print('Time until due: ${todo.timeUntilDue}');
    
    // Should be around 5 minutes
    expect(todo.timeUntilDue.contains('minutes'), true);
    
    // Test 2: UTC to Local conversion
    final utcNow = DateTime.now().toUtc();
    final utcDueIn3Minutes = utcNow.add(const Duration(minutes: 3));
    
    // Simulate data coming from database (stored as UTC)
    final json = {
      'id': '2',
      'user_id': 'user2',
      'title': 'UTC Test Todo',
      'description': null,
      'is_completed': false,
      'priority': 'medium',
      'due_date': utcDueIn3Minutes.toIso8601String(),
      'created_at': utcNow.toIso8601String(),
      'updated_at': utcNow.toIso8601String(),
    };
    
    final todoFromDb = TodoModel.fromJson(json);
    
    print('\nUTC to Local Test:');
    print('UTC due time: $utcDueIn3Minutes');
    print('Local due time: ${todoFromDb.dueDate}');
    print('Time until due: ${todoFromDb.timeUntilDue}');
    
    // Should show minutes, not hours
    expect(todoFromDb.timeUntilDue.contains('minutes'), true);
    expect(todoFromDb.timeUntilDue.contains('hours'), false);
  });
}
