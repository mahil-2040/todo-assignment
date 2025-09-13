import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_model.dart';
import 'notification_service.dart';

class TodoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Create a new todo
  Future<TodoModel?> createTodo({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final todo = TodoModel(
        id: '',
        userId: currentUserId!,
        title: title,
        description: description,
        isCompleted: false,
        priority: priority,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('todos')
          .insert(todo.toCreateJson())
          .select()
          .single();

      final createdTodo = TodoModel.fromJson(response);
      
      // Schedule notification if todo has a due date
      if (createdTodo.dueDate != null) {
        await _notificationService.scheduleNotificationForTodo(createdTodo);
      }

      return createdTodo;
    } catch (e) {
      print('Error creating todo: $e');
      return null;
    }
  }

  // Get all todos for current user
  Future<List<TodoModel>> getTodos({
    bool? isCompleted,
    TaskPriority? priority,
  }) async {
    try {
      if (currentUserId == null) return [];

      var query = _supabase
          .from('todos')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      if (isCompleted != null) {
        final response = await _supabase
            .from('todos')
            .select()
            .eq('user_id', currentUserId!)
            .eq('is_completed', isCompleted)
            .order('created_at', ascending: false);
        
        return (response as List)
            .map((json) => TodoModel.fromJson(json))
            .toList();
      }

      if (priority != null) {
        final response = await _supabase
            .from('todos')
            .select()
            .eq('user_id', currentUserId!)
            .eq('priority', priority.name)
            .order('created_at', ascending: false);
        
        return (response as List)
            .map((json) => TodoModel.fromJson(json))
            .toList();
      }

      final response = await query;
      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching todos: $e');
      return [];
    }
  }

  // Get pending todos (not completed)
  Future<List<TodoModel>> getPendingTodos() async {
    return await getTodos(isCompleted: false);
  }

  // Get completed todos
  Future<List<TodoModel>> getCompletedTodos() async {
    return await getTodos(isCompleted: true);
  }

  // Get overdue todos
  Future<List<TodoModel>> getOverdueTodos() async {
    try {
      if (currentUserId == null) return [];

      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_completed', false)
          .lt('due_date', now)
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching overdue todos: $e');
      return [];
    }
  }

  // Get todos due soon (within 24 hours)
  Future<List<TodoModel>> getTodosDueSoon() async {
    try {
      if (currentUserId == null) return [];

      final now = DateTime.now();
      final in24Hours = now.add(const Duration(hours: 24));

      final response = await _supabase
          .from('todos')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_completed', false)
          .gte('due_date', now.toIso8601String())
          .lte('due_date', in24Hours.toIso8601String())
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => TodoModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching todos due soon: $e');
      return [];
    }
  }

  // Update a todo
  Future<TodoModel?> updateTodo(String todoId, {
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final Map<String, dynamic> updates = {};
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (isCompleted != null) updates['is_completed'] = isCompleted;
      if (priority != null) updates['priority'] = priority.name;
      if (dueDate != null) updates['due_date'] = dueDate.toUtc().toIso8601String();

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('todos')
          .update(updates)
          .eq('id', todoId)
          .eq('user_id', currentUserId!)
          .select()
          .single();

      final updatedTodo = TodoModel.fromJson(response);
      
      if (isCompleted == true) {
        await _notificationService.markTodoCompleted(todoId);
      } else if (dueDate != null) {
        await _notificationService.scheduleNotificationForTodo(updatedTodo);
      } else if (title != null) {
        await _notificationService.scheduleNotificationForTodo(updatedTodo);
      }

      return updatedTodo;
    } catch (e) {
      print('Error updating todo: $e');
      return null;
    }
  }

  Future<TodoModel?> toggleTodoCompletion(String todoId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final currentTodo = await _supabase
          .from('todos')
          .select('is_completed')
          .eq('id', todoId)
          .eq('user_id', currentUserId!)
          .single();

      final newCompletionStatus = !(currentTodo['is_completed'] as bool);

      final response = await _supabase
          .from('todos')
          .update({'is_completed': newCompletionStatus})
          .eq('id', todoId)
          .eq('user_id', currentUserId!)
          .select()
          .single();

      final updatedTodo = TodoModel.fromJson(response);
      
      if (newCompletionStatus) {
        await _notificationService.markTodoCompleted(todoId);
      } else {
        if (updatedTodo.dueDate != null) {
          await _notificationService.scheduleNotificationForTodo(updatedTodo);
        }
      }

      return updatedTodo;
    } catch (e) {
      print('Error toggling todo completion: $e');
      return null;
    }
  }

  Future<bool> deleteTodo(String todoId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _notificationService.cancelNotificationForTodo(todoId);

      await _supabase
          .from('todos')
          .delete()
          .eq('id', todoId)
          .eq('user_id', currentUserId!);

      return true;
    } catch (e) {
      print('Error deleting todo: $e');
      return false;
    }
  }

  Future<Map<String, int>> getTodoStats() async {
    try {
      if (currentUserId == null) return {'total': 0, 'pending': 0, 'completed': 0, 'overdue': 0};

      final allTodos = await getTodos();
      final pendingTodos = allTodos.where((todo) => !todo.isCompleted).toList();
      final completedTodos = allTodos.where((todo) => todo.isCompleted).toList();
      final overdueTodos = allTodos.where((todo) => todo.isOverdue).toList();

      return {
        'total': allTodos.length,
        'pending': pendingTodos.length,
        'completed': completedTodos.length,
        'overdue': overdueTodos.length,
      };
    } catch (e) {
      print('Error getting todo stats: $e');
      return {'total': 0, 'pending': 0, 'completed': 0, 'overdue': 0};
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<UserProfile?> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final Map<String, dynamic> updates = {};
      
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', currentUserId!)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  RealtimeChannel subscribeTodos(Function(List<TodoModel>) onData) {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _supabase
        .channel('todos_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'todos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId!,
          ),
          callback: (payload) async {
            final todos = await getTodos();
            onData(todos);
          },
        )
        .subscribe();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
