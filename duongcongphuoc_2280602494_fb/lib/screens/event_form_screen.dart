import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../services/event_api_service.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final DateTime? selectedDate;

  const EventFormScreen({super.key, this.event, this.selectedDate});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _brideNameController = TextEditingController();
  final _groomNameController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  DateTime _startTime = DateTime.now();
  DateTime? _endTime = DateTime.now().add(const Duration(hours: 1));
  String _selectedStatus = 'Planning';
  final List<String> _statusOptions = ['Planning', 'InProgress', 'Completed', 'Cancelled'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title ?? '';
      _descriptionController.text = widget.event!.description ?? '';
      _locationController.text = widget.event!.location ?? '';
      _brideNameController.text = widget.event!.brideName ?? '';
      _groomNameController.text = widget.event!.groomName ?? '';
      _guestCountController.text = widget.event!.guestCount.toString();
      _budgetController.text = widget.event!.budget?.toString() ?? '';
      _imageUrlController.text = widget.event!.imageUrl ?? '';
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _selectedStatus = widget.event!.status;
    } else if (widget.selectedDate != null) {
      _startTime = widget.selectedDate!;
      _endTime = widget.selectedDate!.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _brideNameController.dispose();
    _groomNameController.dispose();
    _guestCountController.dispose();
    _budgetController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }


  Future<void> _selectStartTime() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (_endTime != null && _endTime!.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (!mounted) return;
    final initialDate = _endTime ?? _startTime.add(const Duration(hours: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startTime,
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        setState(() {
          _endTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endTime != null && (_endTime!.isBefore(_startTime) || _endTime!.isAtSameMomentAs(_startTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = Event(
        id: widget.event?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        eventCategoryId: null, // Không dùng danh mục
        eventCategory: null,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        brideName: _brideNameController.text.trim().isEmpty 
            ? null 
            : _brideNameController.text.trim(),
        groomName: _groomNameController.text.trim().isEmpty 
            ? null 
            : _groomNameController.text.trim(),
        status: _selectedStatus,
        guestCount: int.tryParse(_guestCountController.text.trim()) ?? 0,
        budget: _budgetController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_budgetController.text.trim()),
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
      );

      if (widget.event != null) {
        await EventApiService.updateEvent(event);
      } else {
        await EventApiService.addEvent(event);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.event != null ? 'Đã cập nhật sự kiện' : 'Đã thêm sự kiện')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink[50]!,
              Colors.orange[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header đẹp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink[400]!,
                      Colors.pink[300]!,
                      Colors.orange[300]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.event != null ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện mới',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
        key: _formKey,
        child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Section: Thông tin cơ bản
                      _buildSectionHeader('Thông tin cơ bản', Icons.info_rounded),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Tiêu đề sự kiện *',
                                prefixIcon: const Icon(Icons.event_rounded, color: Colors.pink),
                                filled: true,
                                fillColor: Colors.pink[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
                              decoration: InputDecoration(
                labelText: 'Mô tả',
                                prefixIcon: const Icon(Icons.description_rounded, color: Colors.orange),
                                filled: true,
                                fillColor: Colors.orange[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
              ),
              maxLines: 3,
                              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
                              decoration: InputDecoration(
                labelText: 'Địa điểm',
                                prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.red),
                                filled: true,
                                fillColor: Colors.red[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Thời gian
                      _buildSectionHeader('Thời gian', Icons.access_time_rounded),
            const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTimePicker(
                              'Thời gian bắt đầu *',
                              DateFormat('dd/MM/yyyy HH:mm').format(_startTime),
                              Icons.calendar_today_rounded,
                              Colors.orange,
                              _selectStartTime,
            ),
            const SizedBox(height: 16),
                            _buildTimePicker(
                              'Thời gian kết thúc',
                              _endTime != null 
                                  ? DateFormat('dd/MM/yyyy HH:mm').format(_endTime!)
                                  : 'Chưa đặt',
                              Icons.event_available_rounded,
                              Colors.blue,
                              _selectEndTime,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Thông tin cặp đôi
                      _buildSectionHeader('Thông tin cặp đôi', Icons.favorite_rounded),
                      const SizedBox(height: 16),
                        Container(
                        padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[50]!, Colors.orange[50]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.pink.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _brideNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên cô dâu',
                                prefixIcon: const Icon(Icons.woman_rounded, color: Colors.pink),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _groomNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên chú rể',
                                prefixIcon: const Icon(Icons.man_rounded, color: Colors.blue),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Section: Thông tin sự kiện
                      _buildSectionHeader('Thông tin sự kiện', Icons.event_note_rounded),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Trạng thái',
                                prefixIcon: const Icon(Icons.info_outline_rounded, color: Colors.purple),
                                filled: true,
                                fillColor: Colors.purple[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
              items: _statusOptions.map((status) {
                String label;
                IconData icon;
                switch (status) {
                  case 'Planning':
                    label = 'Đang lên kế hoạch';
                    icon = Icons.assignment;
                    break;
                  case 'InProgress':
                    label = 'Đang chuẩn bị';
                    icon = Icons.work;
                    break;
                  case 'Completed':
                    label = 'Đã hoàn thành';
                    icon = Icons.check_circle;
                    break;
                  case 'Cancelled':
                    label = 'Đã hủy';
                    icon = Icons.cancel;
                    break;
                  default:
                    label = status;
                    icon = Icons.info;
                }
                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _guestCountController,
                              decoration: InputDecoration(
                                labelText: 'Số lượng khách mời',
                                prefixIcon: const Icon(Icons.people_rounded, color: Colors.orange),
                                filled: true,
                                fillColor: Colors.orange[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _budgetController,
                              decoration: InputDecoration(
                                labelText: 'Ngân sách (VNĐ)',
                                prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.green),
                                filled: true,
                                fillColor: Colors.green[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: InputDecoration(
                                labelText: 'URL ảnh sự kiện',
                                prefixIcon: const Icon(Icons.image_rounded, color: Colors.purple),
                                filled: true,
                                fillColor: Colors.purple[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Button lưu
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[400]!, Colors.orange[400]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.event != null ? 'Cập nhật sự kiện' : 'Tạo sự kiện',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[400]!, Colors.orange[400]!],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

