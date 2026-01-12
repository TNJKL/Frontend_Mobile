import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../services/event_api_service.dart';
import '../utils/user_helper.dart';
import 'event_form_screen.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<Event> _events = [];
  bool _isLoading = false;
  String _userRole = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadEvents();
  }

  Future<void> _loadUserInfo() async {
    final userId = await UserHelper.getUserId();
    final role = await UserHelper.getUserRole();
    setState(() {
      _currentUserId = userId;
      _userRole = role;
    });
  }
  
  bool get _canAdd => true;
  
  Future<bool> _canEditEvent(Event event) async {
    return await UserHelper.canEditEvent(event.userId);
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await EventApiService.getEvents();
      setState(() {
        _events = events;
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi tải sự kiện: $e';
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Planning': return Colors.blue;
      case 'InProgress': return Colors.orange;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
     switch (status) {
      case 'Planning': return 'Lên kế hoạch';
      case 'InProgress': return 'Đang thực hiện';
      case 'Completed': return 'Hoàn thành';
      case 'Cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Minimalist background
      appBar: AppBar(
        title: const Text('Danh Sách Sự Kiện', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _loadEvents,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventCard(context, event);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventFormScreen()),
          ).then((_) => _loadEvents());
        },
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Chưa có sự kiện nào', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Bắt đầu quản lý đám cưới ngay hôm nay', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
            ).then((_) => _loadEvents());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(event.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(event.status),
                        style: TextStyle(
                          color: _getStatusColor(event.status),
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: _canEditEvent(event),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return _buildPopupMenu(event);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title ?? 'Sự kiện chưa đặt tên',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                 Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy • HH:mm').format(event.startTime),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        event.location!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (event.brideName != null && event.brideName!.isNotEmpty)
                      _buildUserChip(event.brideName!, Colors.pink),
                    if (event.brideName != null && event.groomName != null)
                      const SizedBox(width: 8),
                     if (event.groomName != null && event.groomName!.isNotEmpty)
                      _buildUserChip(event.groomName!, Colors.blue),
                     const Spacer(),
                     if (event.budget != null && event.budget! > 0)
                      Text(
                        '${NumberFormat('#,###').format(event.budget)} đ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14, color: color),
          const SizedBox(width: 4),
          Text(name, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(Event event) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
      onSelected: (value) => _handleMenuAction(value, event),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('Chỉnh sửa'), contentPadding: EdgeInsets.zero, dense: true),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(leading: Icon(Icons.delete, color: Colors.red, size: 20), title: Text('Xóa', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true),
        ),
      ],
    );
  }

  void _handleMenuAction(String value, Event event) async {
    if (value == 'edit') {
       Navigator.push(context, MaterialPageRoute(builder: (context) => EventFormScreen(event: event))).then((_) => _loadEvents());
    } else if (value == 'delete') {
       final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa sự kiện?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('Xóa', style: TextStyle(color: Colors.red))
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        try {
          await EventApiService.deleteEvent(event.id!);
          _loadEvents();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sự kiện')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }
}
