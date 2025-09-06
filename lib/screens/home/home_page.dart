import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_assignment/core/services/fcm_servisec.dart';
import 'package:todo_assignment/core/services/todo_service.dart';
import 'package:todo_assignment/core/services/notification_sender_service.dart';
import 'package:todo_assignment/core/theme/theme_provider.dart';
import 'package:todo_assignment/core/widgets/theme_toggle_button.dart';
import 'package:todo_assignment/screens/todos/todo_form_screen.dart';
import '../../core/models/todo_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "User";
  String userEmail = "";
  String? userPhotoUrl;

  final TodoService _todoService = TodoService();

  List<TodoModel> pendingTasks = [];
  List<TodoModel> completedTasks = [];
  Map<String, int> stats = {'total': 0, 'pending': 0, 'completed': 0, 'overdue': 0};
  bool isLoading = true;

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await FcmService().init();
    _loadUserData();
    _fetchTodos();
    _subscribeToTodos();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userName = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@')[0] ??
            "User";
        userEmail = user.email ?? "";
        userPhotoUrl = user.userMetadata?['avatar_url'] ??
            user.userMetadata?['picture'];
      });
    }
  }

  Future<void> _fetchTodos() async {
    setState(() => isLoading = true);

    final todos = await _todoService.getTodos();
    final pending = todos.where((t) => !t.isCompleted).toList();
    final completed = todos.where((t) => t.isCompleted).toList();
    final statsData = await _todoService.getTodoStats();

    setState(() {
      pendingTasks = pending;
      completedTasks = completed;
      stats = statsData;
      isLoading = false;
    });
  }

  void _subscribeToTodos() {
    try {
      _subscription = _todoService.subscribeTodos((todos) {
        final pending = todos.where((t) => !t.isCompleted).toList();
        final completed = todos.where((t) => t.isCompleted).toList();
        final overdue = todos.where((t) => t.isOverdue).toList();

        setState(() {
          pendingTasks = pending;
          completedTasks = completed;
          stats = {
            'total': todos.length,
            'pending': pending.length,
            'completed': completed.length,
            'overdue': overdue.length,
          };
        });
      });
    } catch (e) {
      debugPrint('Error subscribing to todos: $e');
    }
  }

  // Todo action methods
  Future<void> _toggleTaskCompletion(TodoModel task) async {
    try {
      await _todoService.toggleTodoCompletion(task.id);
      _fetchTodos(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: ${e.toString()}')),
      );
    }
  }

  Future<void> _editTodo(TodoModel task) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TodoFormScreen(
          existingTodo: task,
          isEditing: true,
        ),
      ),
    );

    if (result != null) {
      _fetchTodos(); // Refresh the list
    }
  }

  Future<void> _deleteTodo(TodoModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _todoService.deleteTodo(task.id);
        if (success) {
          _fetchTodos(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todo deleted successfully')),
          );
        } else {
          throw Exception('Failed to delete todo');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting todo: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    try {
      await _todoService.signOut();
      // The AuthGate will automatically handle navigation back to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _testNotifications() async {
    try {
      // Show options for different tests
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Check Pending Notifications'),
                subtitle: const Text('Check for existing pending notifications'),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationSenderService().checkNowForTesting();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checked for pending notifications. Check console for details.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Create Test Notification'),
                subtitle: const Text('Create a notification that triggers immediately'),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationSenderService().createTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification created. Check console for details.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Create Future Test'),
                subtitle: const Text('Create a notification that triggers in 10 seconds'),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationSenderService().createTestTodoNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Future test notification created. Should trigger in 10 seconds.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error testing notifications: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 400;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark(context);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, // 5% of screen width
                vertical: screenHeight * 0.02,  // 2% of screen height
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 0.85,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with profile and theme toggle
                            _buildHeader(isDark, screenWidth, isSmallScreen),
                            SizedBox(height: screenHeight * 0.03),

                            // Task statistics cards
                            _buildTaskStats(isDark, screenWidth, isSmallScreen),
                            SizedBox(height: screenHeight * 0.03),

                            // Pending tasks section
                            _buildPendingTasks(isDark, screenWidth, isSmallScreen),
                            SizedBox(height: screenHeight * 0.025),

                            // Completed tasks section
                            _buildCompletedTasks(isDark, screenWidth, isSmallScreen),

                            SizedBox(height: screenHeight * 0.1), // Space for FAB
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(isDark, isSmallScreen),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, double screenWidth, bool isSmallScreen) {
    final avatarSize = isSmallScreen ? 40.0 : 50.0;
    final welcomeFontSize = isSmallScreen ? 14.0 : 16.0;
    final dateFontSize = isSmallScreen ? 9.0 : 10.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final spacing = isSmallScreen ? 8.0 : 15.0;
    
    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF334155) : Colors.grey[300],
            image: userPhotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(userPhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: userPhotoUrl == null
              ? Icon(
                  Icons.person,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  size: avatarSize * 0.5,
                )
              : null,
        ),
        SizedBox(width: spacing),

        // Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, $userName!",
                style: TextStyle(
                  fontSize: welcomeFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                "Friday, September 5, 2025",
                style: TextStyle(
                  fontSize: dateFontSize,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Action buttons
        Row(
          children: [
            GestureDetector(
              onTap: _testNotifications,
              child: Icon(
                Icons.notifications_active,
                color: isDark ? Colors.white70 : Colors.grey[600],
                size: iconSize,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            ThemeToggleButton(size: iconSize),
            SizedBox(width: isSmallScreen ? 8 : 12),
            GestureDetector(
              onTap: _showLogoutDialog,
              child: Icon(
                Icons.logout,
                color: isDark ? Colors.white70 : Colors.grey[600],
                size: iconSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskStats(bool isDark, double screenWidth, bool isSmallScreen) {
    final cardSpacing = isSmallScreen ? 8.0 : 15.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total",
            "${stats['total'] ?? 0}",
            Colors.blue,
            isDark,
            screenWidth,
            isSmallScreen,
          ),
        ),
        SizedBox(width: cardSpacing),
        Expanded(
          child: _buildStatCard(
            "Pending",
            "${stats['pending'] ?? 0}",
            Colors.orange,
            isDark,
            screenWidth,
            isSmallScreen,
          ),
        ),
        SizedBox(width: cardSpacing),
        Expanded(
          child: _buildStatCard(
            "Overdue",
            "${stats['overdue'] ?? 0}",
            Colors.red,
            isDark,
            screenWidth,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, Color color, bool isDark, double screenWidth, bool isSmallScreen) {
    final cardPadding = isSmallScreen ? 12.0 : 20.0;
    final labelFontSize = isSmallScreen ? 12.0 : 14.0;
    final countFontSize = isSmallScreen ? 24.0 : 32.0;
    final circleSize = isSmallScreen ? 10.0 : 13.0;
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            count,
            style: TextStyle(
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasks(bool isDark, double screenWidth, bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final badgeFontSize = isSmallScreen ? 11.0 : 12.0;
    final spacing = isSmallScreen ? 12.0 : 15.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                "Pending Tasks",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8, 
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFfff7ed),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                "${pendingTasks.length}",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: badgeFontSize,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        if (pendingTasks.isEmpty)
          Text(
            "No pending tasks", 
            style: TextStyle(
              color: Colors.grey,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          )
        else
          ...pendingTasks.map((task) => _buildTaskCard(task, isDark, screenWidth, isSmallScreen)),
      ],
    );
  }

  Widget _buildCompletedTasks(bool isDark, double screenWidth, bool isSmallScreen) {
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final badgeFontSize = isSmallScreen ? 11.0 : 13.0;
    final spacing = isSmallScreen ? 12.0 : 15.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                "Completed",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8, 
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "${completedTasks.length}",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: badgeFontSize,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        if (completedTasks.isEmpty)
          Text(
            "No completed tasks", 
            style: TextStyle(
              color: Colors.grey,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          )
        else
          ...completedTasks.map((task) => _buildTaskCard(task, isDark, screenWidth, isSmallScreen)),
      ],
    );
  }

  Widget _buildTaskCard(TodoModel task, bool isDark, double screenWidth, bool isSmallScreen) {
    final bool isCompleted = task.isCompleted;
    final cardPadding = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final descriptionFontSize = isSmallScreen ? 12.0 : 14.0;
    final metaFontSize = isSmallScreen ? 10.0 : 12.0;
    final badgeFontSize = isSmallScreen ? 9.0 : 10.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    final checkboxSize = isSmallScreen ? 20.0 : 24.0;
    final cardMargin = isSmallScreen ? 8.0 : 12.0;

    return GestureDetector(
      onTap: () => _editTodo(task),
      child: Container(
        margin: EdgeInsets.only(bottom: cardMargin),
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: isDark 
            ? (isCompleted ? const Color(0xFF334155) : const Color(0xFF475569))
            : (isCompleted ? const Color(0xFFF0FDF4) : (task.isOverdue) ? const Color(0xfffef2f2) : const Color(0xFFfff7ed)),
          borderRadius: BorderRadius.circular(16),
          border: isCompleted 
            ? Border.all(color: Colors.green.withOpacity(0.3)) : (task.isOverdue) ? Border.all(color: Colors.red.withOpacity(0.3))
            : Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                        ? (isCompleted ? Colors.white60 : Colors.white)
                        : Colors.blueGrey,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: isSmallScreen ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    SizedBox(height: isSmallScreen ? 3 : 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: isDark 
                          ? (isCompleted ? Colors.white38 : Colors.white70)
                          : Colors.grey[600],
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: isSmallScreen ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (!isCompleted && task.dueDate != null) ...[
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: isSmallScreen ? 14 : 16, 
                          color: task.isOverdue 
                            ? Colors.red 
                            : (task.isDueSoon ? Colors.orange : Colors.blue),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.isOverdue 
                            ? "Overdue" 
                            : "Due in ${task.timeUntilDue}",
                          style: TextStyle(
                            fontSize: metaFontSize,
                            color: task.isOverdue 
                              ? Colors.red 
                              : (task.isDueSoon ? Colors.orange : Colors.blue),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (task.isOverdue 
                              ? Colors.red 
                              : (task.isDueSoon ? Colors.orange : Colors.blue)
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.isOverdue 
                              ? "Overdue" 
                              : (task.isDueSoon ? "Due Soon" : "Upcoming"),
                            style: TextStyle(
                              fontSize: badgeFontSize,
                              color: task.isOverdue 
                                ? Colors.red 
                                : (task.isDueSoon ? Colors.orange : Colors.blue),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isCompleted) ...[
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: isSmallScreen ? 14 : 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "Completed",
                          style: TextStyle(
                            fontSize: metaFontSize,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Done",
                            style: TextStyle(
                              fontSize: badgeFontSize,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Column(
              children: [
                GestureDetector(
                  onTap: () => _toggleTaskCompletion(task),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: isCompleted ? Colors.green : Colors.orange,
                    size: checkboxSize,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                GestureDetector(
                  onTap: () => _editTodo(task),
                  child: Icon(
                    Icons.edit_outlined, 
                    color: isDark ? Colors.white70 : Colors.blueGrey, 
                    size: iconSize,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                GestureDetector(
                  onTap: () => _deleteTodo(task),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withOpacity(0.7), 
                    size: iconSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark, bool isSmallScreen) {
    final fabSize = isSmallScreen ? 48.0 : 56.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    
    return FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const TodoFormScreen(isEditing: false),
          ),
        );
        
        if (result != null) {
          // Refresh the todos list
          _fetchTodos();
        }
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: fabSize,
        height: fabSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00D4D4),
              Color(0xFF00B4D8),
              Color(0xFF0EA5E9),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B4D8).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
