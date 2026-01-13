import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../services/event_api_service.dart';
import '../utils/user_helper.dart';
import 'event_form_screen.dart';
import 'menu_list_screen.dart';
import 'budget_screen.dart';
import 'task_screen.dart';

import '../services/task_api_service.dart';
import '../widgets/progress_widget.dart';
import 'vendor_list_screen.dart';
import 'event_vendor_screen.dart';
import 'guest_management/guest_list_screen.dart';
import 'service_package_selection_screen.dart';
import 'transaction_history_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _taskStats;
  final TaskApiService _taskService = TaskApiService();

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUserRole();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _taskService.getTaskStats(widget.event.id!);
      if (mounted) setState(() => _taskStats = stats);
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  String _userRole = 'User';
  bool _isLoading = false;

  Future<void> _loadUserRole() async {
    final role = await UserHelper.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: widget.event),
      ),
    );
    if (result == true && mounted) {
      // Reload event data
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sự kiện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await EventApiService.deleteEvent(widget.event.id!);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa sự kiện')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi xóa sự kiện: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<bool> get _canEdit async {
    return await UserHelper.canEditEvent(widget.event.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[50]!, Colors.orange[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header đẹp
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                    const Expanded(
                      child: Text(
                        'Chi tiết sự kiện',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: _canEdit,
                      builder: (context, snapshot) {
                        final canEdit = snapshot.data ?? false;
                        if (!canEdit) return const SizedBox.shrink();

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Chỉnh sửa',
                              onPressed: _isLoading ? null : _editEvent,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              tooltip: 'Xóa',
                              onPressed: _isLoading ? null : _deleteEvent,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Card với tiêu đề
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pink[400]!,
                                    Colors.orange[400]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.event.title ?? 'Không có tiêu đề',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (widget.event.description != null &&
                                      widget.event.description!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.event.description!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tiến độ công việc
                            if (_taskStats != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: ProgressWidget(
                                  totalTasks: _taskStats!['totalTasks'],
                                  completedTasks: _taskStats!['completedTasks'],
                                  percentage: (_taskStats!['percentage'] as num)
                                      .toDouble(),
                                ),
                              ),

                            // Thông tin cặp đôi - Card đẹp
                            if ((widget.event.brideName != null &&
                                    widget.event.brideName!.isNotEmpty) ||
                                (widget.event.groomName != null &&
                                    widget.event.groomName!.isNotEmpty)) ...[
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.pink[400],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Thông tin cặp đôi',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (widget.event.brideName != null &&
                                        widget.event.brideName!.isNotEmpty)
                                      _buildCoupleInfo(
                                        Icons.woman_rounded,
                                        'Cô dâu',
                                        widget.event.brideName!,
                                        Colors.pink,
                                      ),
                                    if (widget.event.brideName != null &&
                                        widget.event.groomName != null)
                                      const SizedBox(height: 12),
                                    if (widget.event.groomName != null &&
                                        widget.event.groomName!.isNotEmpty)
                                      _buildCoupleInfo(
                                        Icons.man_rounded,
                                        'Chú rể',
                                        widget.event.groomName!,
                                        Colors.blue,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Thông tin chi tiết - Card
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
                                  _buildDetailCard(
                                    Icons.access_time_rounded,
                                    'Thời gian',
                                    widget.event.endTime != null
                                        ? '${DateFormat('dd/MM/yyyy HH:mm').format(widget.event.startTime)} - ${DateFormat('HH:mm').format(widget.event.endTime!)}'
                                        : DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(widget.event.startTime),
                                    Colors.orange,
                                  ),
                                  if (widget.event.location != null &&
                                      widget.event.location!.isNotEmpty) ...[
                                    const Divider(height: 32),
                                    _buildDetailCard(
                                      Icons.location_on_rounded,
                                      'Địa điểm',
                                      widget.event.location!,
                                      Colors.red,
                                    ),
                                  ],
                                  const Divider(height: 32),
                                  _buildDetailCard(
                                    _getStatusIcon(widget.event.status),
                                    'Trạng thái',
                                    _getStatusLabel(widget.event.status),
                                    _getStatusColor(widget.event.status),
                                  ),
                                  if (widget.event.guestCount > 0) ...[
                                    const Divider(height: 32),
                                    _buildDetailCard(
                                      Icons.people_rounded,
                                      'Số lượng khách mời',
                                      '${widget.event.guestCount} người',
                                      Colors.orange,
                                    ),
                                  ],
                                  if (widget.event.budget != null &&
                                      widget.event.budget! > 0) ...[
                                    const Divider(height: 32),
                                    _buildDetailCard(
                                      Icons.attach_money_rounded,
                                      'Ngân sách',
                                      '${NumberFormat('#,###').format(widget.event.budget!.toInt())} VNĐ',
                                      Colors.green,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Ảnh sự kiện
                            if (widget.event.imageUrl != null &&
                                widget.event.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    widget.event.imageUrl!,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 250,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink[100]!,
                                              Colors.orange[100]!,
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            const Text(
                              "Công cụ quản lý",
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.blueGrey
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildModuleShortcut(context, "Ngân sách", Icons.attach_money_rounded, Colors.green, () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetScreen(event: widget.event)));
                                  _loadStats(); // Reload stats if needed
                                }),
                                _buildModuleShortcut(context, "Thực đơn", Icons.restaurant_menu_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MenuListScreen(event: widget.event)))),
                                _buildModuleShortcut(context, "Công việc", Icons.assignment_turned_in_rounded, Colors.blue, () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskScreen(event: widget.event)));
                                  _loadStats();
                                }),
                                _buildModuleShortcut(context, "Khách mời", Icons.people_rounded, Colors.purple, () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => GuestListScreen(event: widget.event)));
                                  _loadStats();
                                }),
                                _buildModuleShortcut(context, "Gói Dịch Vụ", Icons.inventory_2_rounded, Colors.pink, () async {
                                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ServicePackageSelectionScreen(eventId: widget.event.id!)));
                                  if (result == true) {
                                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dữ liệu đã được cập nhật')));
                                  }
                                }),
                                _buildModuleShortcut(context, "Nhà cung cấp", Icons.storefront_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventVendorScreen(event: widget.event)))),
                                _buildModuleShortcut(context, "Lịch sử GD", Icons.history_edu_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()))),
                              ],
                            ),
                          ], // End Column children
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleInfo(
    IconData icon,
    String label,
    String name,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Planning':
        return Icons.assignment;
      case 'InProgress':
        return Icons.work;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Planning':
        return 'Đang lên kế hoạch';
      case 'InProgress':
        return 'Đang chuẩn bị';
      case 'Completed':
        return 'Đã hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }



  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planning':
        return Colors.blue;
      case 'InProgress':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildModuleShortcut(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 24, // Approx 1/3 width
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
