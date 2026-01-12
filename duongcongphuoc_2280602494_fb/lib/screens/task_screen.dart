import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../Models/wedding_task.dart';
import '../services/task_api_service.dart';
import 'task_form_screen.dart';
import 'expense_form_screen.dart';

class TaskScreen extends StatefulWidget {
  final Event event;

  const TaskScreen({super.key, required this.event});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  final TaskApiService _taskService = TaskApiService();
  List<WeddingTask> _allTasks = [];
  bool _isLoading = true;
  String? _userRole;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final tasks = await _taskService.getTasksByEventId(widget.event.id!);
      setState(() {
        _allTasks = tasks;
        _userRole = role;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải công việc: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTaskStatus(WeddingTask task) async {
    final newStatus = task.status == 'Completed' ? 'Pending' : 'Completed';
    final completedDate = newStatus == 'Completed' ? DateTime.now() : null;
    
    // Optimistic update
    setState(() {
      task.status = newStatus;
      task.completedDate = completedDate;
    });

    try {
      await _taskService.updateTask(task);
      
      // If task is completed and user is Staff/Admin, ask to create expense
      if (newStatus == 'Completed' && (_userRole == 'Admin' || _userRole == 'Staff')) {
        if (mounted) {
           final createExpense = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Tạo khoản chi?'),
              content: Text('Bạn có muốn tạo khoản chi phí cho công việc "${task.title}" không?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Có, tạo ngay')),
              ],
            ),
          );

          if (createExpense == true && mounted) {
            // Navigate to ExpenseFormScreen
            // Need to import expense_form_screen.dart
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpenseFormScreen(
                  eventId: widget.event.id!,
                  initialDescription: task.title,
                ),
              ),
            );
          }
        }
      }

    } catch (e) {
      // Revert if failed
      setState(() {
        task.status = newStatus == 'Completed' ? 'Pending' : 'Completed';
        task.completedDate = newStatus == 'Completed' ? null : DateTime.now(); // approximate revert
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thất bại')),
        );
      }
    }
  }

  Future<void> _deleteTask(int taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _taskService.deleteTask(taskId);
        _loadTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e')),
          );
        }
      }
    }
  }

  Widget _buildTaskList(List<WeddingTask> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('Chưa có công việc nào.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isCompleted = task.status == 'Completed';
        final isOverdue = !isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Tooltip(
              message: (_userRole == 'Admin' || _userRole == 'Staff') 
                  ? 'Đánh dấu hoàn thành' 
                  : 'Chỉ nhân viên mới có thể xác nhận hoàn thành',
              child: Checkbox(
                value: isCompleted,
                activeColor: Colors.pink,
                onChanged: (_userRole == 'Admin' || _userRole == 'Staff') 
                    ? (val) => _toggleTaskStatus(task) 
                    : null, // Read-only for User
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(task.category, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    ),
                    const SizedBox(width: 8),
                    if (task.dueDate != null)
                      Text(
                        DateFormat('dd/MM').format(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    if (task.priority == 'High')
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.flag, color: Colors.red, size: 16),
                      ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskFormScreen(eventId: widget.event.id!, task: task)),
                  ).then((val) { if (val == true) _loadTasks(); });
                } else if (value == 'delete') {
                  _deleteTask(task.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks
    final pendingTasks = _allTasks.where((t) => t.status != 'Completed' && t.status != 'Cancelled').toList();
    final completedTasks = _allTasks.where((t) => t.status == 'Completed').toList();
    final allSorted = List<WeddingTask>.from(_allTasks)..sort((a,b) {
      // Sort: Pending first, then by date
      if (a.status == 'Pending' && b.status != 'Pending') return -1;
      if (a.status != 'Pending' && b.status == 'Pending') return 1;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Công Việc', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Tạo mẫu công việc',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tạo checklist mẫu?'),
                  content: const Text('Hệ thống sẽ thêm khoảng 20 công việc mẫu vào danh sách của bạn.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Tạo ngay')),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() => _isLoading = true);
                try {
                  await _taskService.generateTemplateTasks(widget.event.id!);
                  await _loadTasks();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tạo danh sách mẫu thành công!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Cần làm (${pendingTasks.length})'),
            Tab(text: 'Đã xong (${completedTasks.length})'),
            const Tab(text: 'Tất cả'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTasks.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_add, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Chưa có công việc nào', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                           setState(() => _isLoading = true);
                           try {
                             await _taskService.generateTemplateTasks(widget.event.id!);
                             await _loadTasks();
                           } catch (e) {
                             // Handle error
                           } finally {
                             if(mounted) setState(() => _isLoading = false);
                           }
                        }, 
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Tạo Checklist Mẫu Ngay'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                         onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskFormScreen(eventId: widget.event.id!),
                              ),
                            );
                            if (result == true) _loadTasks();
                         },
                         child: const Text('Hoặc tự thêm thủ công'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(pendingTasks),
                _buildTaskList(completedTasks),
                _buildTaskList(allSorted),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskFormScreen(eventId: widget.event.id!),
            ),
          );
          if (result == true) _loadTasks();
        },
      ),
    );
  }
}
