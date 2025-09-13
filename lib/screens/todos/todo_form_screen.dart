import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_assignment/core/theme/theme_provider.dart';
import 'package:todo_assignment/core/models/todo_model.dart';
import 'package:todo_assignment/core/services/todo_service.dart';

class TodoFormScreen extends StatefulWidget {
  final TodoModel? existingTodo; // null for add, TodoModel for edit
  final bool isEditing;

  const TodoFormScreen({
    super.key,
    this.existingTodo,
    this.isEditing = false,
  });

  @override
  State<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TodoService _todoService = TodoService();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TaskPriority _selectedPriority = TaskPriority.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingTodo != null) {
      _initializeFormWithExistingData();
    }
  }

  void _initializeFormWithExistingData() {
    final todo = widget.existingTodo!;
    _titleController.text = todo.title;
    _descriptionController.text = todo.description ?? '';
    _selectedPriority = todo.priority;
    
    if (todo.dueDate != null) {
      final localDueDate = todo.dueDate!.toLocal();
      _selectedDate = DateTime(
        localDueDate.year,
        localDueDate.month,
        localDueDate.day,
      );
      _selectedTime = TimeOfDay(
        hour: localDueDate.hour,
        minute: localDueDate.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark(context);
    
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF00B4D8),
              surface: isDark ? const Color(0xFF334155) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        if (_selectedTime != null) {
          _validateDateTime();
        }
      });
    }
  }

  Future<void> _selectTime() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark(context);
    
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF00B4D8),
              surface: isDark ? const Color(0xFF334155) : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
        // If date is already selected, validate the combined datetime
        if (_selectedDate != null) {
          _validateDateTime();
        }
      });
    }
  }

  DateTime? get _combinedDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _validateDateTime() {
    if (_combinedDateTime != null) {
      final now = DateTime.now();
      if (_combinedDateTime!.isBefore(now)) {
        // Show warning if the selected datetime is in the past
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected date and time cannot be in the past'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  bool _isDateTimeValid() {
    if (_combinedDateTime == null) return true; // No datetime selected is valid
    return _combinedDateTime!.isAfter(DateTime.now().toUtc().toLocal());
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if both date and time are selected
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a due date'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a due time'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    // Check if the selected datetime is not in the past
    if (!_isDateTimeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selected date and time cannot be in the past'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing && widget.existingTodo != null) {
        // Update existing todo
        final result = await _todoService.updateTodo(
          widget.existingTodo!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _combinedDateTime,
        );

        if (result != null) {
          Navigator.of(context).pop(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todo updated successfully!')),
          );
        } else {
          throw Exception('Failed to update todo');
        }
      } else {
        // Create new todo
        final result = await _todoService.createTodo(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _combinedDateTime,
        );

        if (result != null) {
          Navigator.of(context).pop(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todo created successfully!')),
          );
        } else {
          throw Exception('Failed to create todo');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.isEditing ? 'Edit Todo' : 'Add Todo',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Todo Details Section
                        Container(
                          width: double.infinity,
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
                              Text(
                                'Todo Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Title Field
                              Text(
                                'Title',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Enter todo title',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: isDark 
                                    ? const Color(0xFF475569) 
                                    : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  fontSize: 16,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Date and Time Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: isDark ? Colors.white70 : Colors.grey[700],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Date',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.white70 : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _selectDate,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark 
                                                ? const Color(0xFF475569) 
                                                : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _formatDate(_selectedDate).isEmpty 
                                                ? 'Select date'
                                                : _formatDate(_selectedDate),
                                              style: TextStyle(
                                                color: _selectedDate == null
                                                  ? (isDark ? Colors.white38 : Colors.grey[400])
                                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: isDark ? Colors.white70 : Colors.grey[700],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Time',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.white70 : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _selectTime,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark 
                                                ? const Color(0xFF475569) 
                                                : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _formatTime(_selectedTime).isEmpty 
                                                ? 'Select time'
                                                : _formatTime(_selectedTime),
                                              style: TextStyle(
                                                color: _selectedTime == null
                                                  ? (isDark ? Colors.white38 : Colors.grey[400])
                                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Description Field
                              Text(
                                'Description (Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Add description...',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: isDark 
                                    ? const Color(0xFF475569) 
                                    : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Preview Section (for editing)
                        if (widget.isEditing && _combinedDateTime != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? const Color(0xFF334155).withOpacity(0.6)
                                : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _titleController.text.isNotEmpty 
                                    ? _titleController.text 
                                    : 'Todo title',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Due: ${_formatDate(_selectedDate)} at ${_formatTime(_selectedTime)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isDark ? Colors.white30 : Colors.grey[300]!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveTodo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4D8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.isEditing ? 'Update' : 'Create',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
