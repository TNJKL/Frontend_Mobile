import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/wedding_task.dart';
import '../services/task_api_service.dart';

class TaskFormScreen extends StatefulWidget {
  final int eventId;
  final WeddingTask? task;

  const TaskFormScreen({super.key, required this.eventId, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;
  String _category = 'Chung';
  String _priority = 'Normal';
  DateTime? _dueDate;
  bool _isLoading = false;

  final TaskApiService _taskService = TaskApiService();
  
  final List<String> _categories = [
    'Chung', 'Pháp lý', 'Địa điểm', 'Trang phục', 'Làm đẹp', 
    'Khách mời', 'Thiệp cưới', 'Ăn uống', 'Trang trí', 'Ảnh/Video', 'Giải trí', 'Hậu cần'
  ];

  final Map<String, String> _priorityLabels = {
    'High': 'Cao',
    'Normal': 'Trung bình',
    'Low': 'Thấp',
  };

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _title = widget.task!.title;
      _description = widget.task!.description;
      _category = widget.task!.category;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;

      // Validate Category: If the task's category is not in the list, add it to avoid Dropdown crash
      if (!_categories.contains(_category)) {
        _categories.add(_category);
      }
    } else {
      _title = '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        if (widget.task == null) {
          // Create
          UserHelper userHelper = UserHelper();
          // Note: AssignedToUserId logic can be added later if we fetch list of users
          
          await _taskService.createTask(WeddingTask(
            id: 0,
            eventId: widget.eventId,
            title: _title,
            description: _description,
            category: _category,
            priority: _priority,
            dueDate: _dueDate,
            status: 'Pending',
          ));
        } else {
          // Update
          await _taskService.updateTask(WeddingTask(
            id: widget.task!.id,
            eventId: widget.eventId,
            title: _title,
            description: _description,
            category: _category,
            priority: _priority,
            dueDate: _dueDate,
            status: widget.task!.status, // Keep existing status
            completedDate: widget.task!.completedDate,
          ));
        }
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên công việc' : null,
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                      maxLines: 3,
                      onSaved: (value) => _description = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Độ ưu tiên', border: OutlineInputBorder()),
                      items: _priorityLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (value) => setState(() => _priority = value!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_dueDate == null ? 'Chọn hạn chót (Deadline)' : 'Hạn chót: ${DateFormat('dd/MM/yyyy').format(_dueDate!)}'),
                      trailing: const Icon(Icons.calendar_today, color: Colors.pink),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey[400]!)),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitForm,
                      child: Text(widget.task == null ? 'Tạo công việc' : 'Cập nhật', style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Dummy UserHelper if not exists or different (assuming UserHelper exists from previous context but might need adjustment)
class UserHelper {
  // logic to get user ID if needed, but handled by API usually 
}
