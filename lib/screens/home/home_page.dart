import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_assignment/core/theme/theme_provider.dart';
import 'package:todo_assignment/core/widgets/theme_toggle_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "User";
  String userEmail = "";
  String? userPhotoUrl;
  
  final List<Task> pendingTasks = [
    Task(
      title: "Complete project proposal",
      dueIn: "1 hours",
      status: "Due Soon",
      priority: TaskPriority.high,
    ),
    Task(
      title: "Review team feedback",
      dueIn: "23 hours",
      status: "Due Soon",
      priority: TaskPriority.medium,
    ),
  ];

  final List<Task> completedTasks = [
    Task(
      title: "Update documentation",
      status: "Done",
      priority: TaskPriority.low,
      isCompleted: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark(context);
        
        return Scaffold(
          backgroundColor: isDark 
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with profile and theme toggle
                  _buildHeader(isDark),
                  const SizedBox(height: 30),
                  
                  // Task statistics cards
                  _buildTaskStats(isDark),
                  const SizedBox(height: 30),
                  
                  // Pending tasks section
                  _buildPendingTasks(isDark),
                  const SizedBox(height: 25),
                  
                  // Completed tasks section
                  _buildCompletedTasks(isDark),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(isDark),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Profile picture
        Container(
          width: 50,
          height: 50,
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
                  size: 25,
                )
              : null,
        ),
        const SizedBox(width: 15),
        
        // Welcome text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back, $userName!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                "Friday, September 5, 2025",
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons
        Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: isDark ? Colors.white70 : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            ThemeToggleButton(size: 24),
            const SizedBox(width: 12),
            Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white70 : Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskStats(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total",
            "3",
            Colors.blue,
            isDark,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            "Pending",
            "2",
            Colors.orange,
            isDark,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            "Overdue",
            "0",
            Colors.red,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
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
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasks(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Pending Tasks",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFfff7ed),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                "${pendingTasks.length}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...pendingTasks.map((task) => _buildTaskCard(task, isDark)),
      ],
    );
  }

  Widget _buildCompletedTasks(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Completed",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "${completedTasks.length}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...completedTasks.map((task) => _buildTaskCard(task, isDark)),
      ],
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    final bool isCompleted = task.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted 
          ? (Color(0xFFF0FDF4))
          : (Color(0xFFfff7ed)),
        borderRadius: BorderRadius.circular(16),
        border: isCompleted 
          ? Border.all(color: Colors.green.withOpacity(0.3))
          : null,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:  Colors.blueGrey ,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isCompleted && task.dueIn != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Due in ${task.dueIn}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.status,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Completed",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Done",
                          style: const TextStyle(
                            fontSize: 10,
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
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                color: isCompleted ? Colors.green :  Colors.orange ,
                size: 24,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                color: Colors.blueGrey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.delete_outline,
                color: Colors.red.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return Container(
      width: 56,
      height: 56,
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
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

// Task model
class Task {
  final String title;
  final String? dueIn;
  final String status;
  final TaskPriority priority;
  final bool isCompleted;

  Task({
    required this.title,
    this.dueIn,
    required this.status,
    required this.priority,
    this.isCompleted = false,
  });
}

enum TaskPriority { high, medium, low }