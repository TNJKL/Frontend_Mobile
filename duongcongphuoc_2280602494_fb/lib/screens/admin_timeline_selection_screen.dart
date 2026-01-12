import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../services/event_api_service.dart';
import 'timeline_screen.dart';

class AdminTimelineSelectionScreen extends StatefulWidget {
  const AdminTimelineSelectionScreen({super.key});

  @override
  State<AdminTimelineSelectionScreen> createState() => _AdminTimelineSelectionScreenState();
}

class _AdminTimelineSelectionScreenState extends State<AdminTimelineSelectionScreen> {
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await EventApiService.getEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải sự kiện: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Sự Kiện Để Duyệt Kịch Bản'),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('Không có sự kiện nào.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.pink[100],
                          radius: 24,
                          child: Icon(Icons.event, color: Colors.pink[700]),
                        ),
                        title: Text(
                          event.title ?? 'Sự kiện không tên',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Ngày: ${DateFormat('dd/MM/yyyy').format(event.startTime)}'),
                            Text('Địa điểm: ${event.location ?? "Chưa có"}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimelineScreen(event: event),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
