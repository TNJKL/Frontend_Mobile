import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../services/event_api_service.dart';
import '../utils/user_helper.dart';
import 'event_form_screen.dart';
import 'event_list_screen.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Event> _events = [];
  bool _isLoading = false;
  String _userRole = '';

  Map<DateTime, List<Event>> _groupedEvents = {};

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadEvents();
  }

  Future<void> _loadUserRole() async {
    final role = await UserHelper.getUserRole();
    setState(() {
      _userRole = role;
    });
  }
  
  // Tất cả user đều có thể thêm sự kiện
  bool get _canAdd => true;
  
  // Kiểm tra xem có thể sửa/xóa event không
  Future<bool> _canEditEvent(Event event) async {
    return await UserHelper.canEditEvent(event.userId);
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      // Lấy events trong khoảng thời gian 3 tháng trước và sau
      final startDate = _focusedDay.subtract(const Duration(days: 90));
      final endDate = _focusedDay.add(const Duration(days: 90));

      final events = await EventApiService.getEvents(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _events = events;
        _groupEventsByDate();
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
      setState(() => _isLoading = false);
    }
  }

  void _groupEventsByDate() {
    _groupedEvents.clear();
    for (var event in _events) {
      // Chuẩn hóa ngày bắt đầu về 00:00:00
      final startDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      
      // Nếu không có endTime, chỉ thêm vào ngày bắt đầu
      if (event.endTime == null) {
        if (_groupedEvents[startDate] == null) {
          _groupedEvents[startDate] = [];
        }
        _groupedEvents[startDate]!.add(event);
        continue;
      }
      
      // Nếu có endTime, chuẩn hóa về 00:00:00
      final endDate = DateTime(
        event.endTime!.year,
        event.endTime!.month,
        event.endTime!.day,
      );

      // Duyệt từ ngày bắt đầu đến ngày kết thúc
      DateTime currentDate = startDate;
      // Sử dụng compareTo hoặc so sánh <= để bao gồm cả ngày kết thúc
      while (currentDate.compareTo(endDate) <= 0) {
        // Thêm event vào danh sách của ngày hiện tại
        if (_groupedEvents[currentDate] == null) {
          _groupedEvents[currentDate] = [];
        }
        _groupedEvents[currentDate]!.add(event);

        // Tăng thêm 1 ngày
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _groupedEvents[date] ?? [];
  }

  Color? _getEventColor(Event event) {
    // Màu mặc định cho sự kiện cưới - màu hồng
    return Colors.pink;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Lịch Sự Kiện',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.list_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EventListScreen(),
                              ),
                            ).then((_) => _loadEvents());
                          },
                          tooltip: 'Danh sách sự kiện',
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: _loadEvents,
                          tooltip: 'Làm mới',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Calendar với design đẹp
                          Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TableCalendar<Event>(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              calendarFormat: _calendarFormat,
                              eventLoader: _getEventsForDay,
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.orange[400]!, Colors.orange[300]!],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.pink[400]!, Colors.pink[300]!],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: BoxDecoration(
                                  color: Colors.pink[400],
                                  shape: BoxShape.circle,
                                ),
                                outsideDaysVisible: false,
                                weekendTextStyle: TextStyle(color: Colors.pink[400]),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                                formatButtonShowsNext: false,
                                formatButtonDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.pink[100]!, Colors.orange[100]!],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                formatButtonTextStyle: TextStyle(
                                  color: Colors.pink[800],
                                  fontWeight: FontWeight.bold,
                                ),
                                titleTextStyle: const TextStyle(
                                  color: Colors.pink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, events) {
                                  if (events.isNotEmpty) {
                                    return Positioned(
                                      bottom: 2,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.pink[400]!, Colors.orange[400]!],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  }
                                  return null;
                                },
                              ),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                });
                              },
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              onPageChanged: (focusedDay) {
                                _focusedDay = focusedDay;
                                _loadEvents();
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Danh sách sự kiện trong ngày
                          Expanded(child: _buildEventsList()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventFormScreen(selectedDate: _selectedDay),
            ),
          ).then((_) => _loadEvents());
        },
        backgroundColor: Colors.pink[400],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm Sự Kiện',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final dayEvents = _getEventsForDay(_selectedDay);

    return Column(
      children: [
        // Header ngày được chọn
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[400]!, Colors.orange[400]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'vi').format(_selectedDay),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${dayEvents.length} sự kiện',
                  style: TextStyle(
                    color: Colors.pink[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.pink[300],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Không có sự kiện nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy tạo sự kiện cho ngày này!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(event: event),
                              ),
                            ).then((_) => _loadEvents());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.pink[50]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.pink.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.pink[400]!,
                                        Colors.orange[400]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title ?? 'Không có tiêu đề',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.endTime != null
                                                ? '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime!)}'
                                                : DateFormat('HH:mm').format(event.startTime),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (event.location != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                event.location!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                FutureBuilder<bool>(
                                  future: _canEditEvent(event),
                                  builder: (context, snapshot) {
                                    final canEdit = snapshot.data ?? false;
                                    if (!canEdit) return const SizedBox.shrink();
                                    
                                    return PopupMenuButton(
                                      icon: Icon(Icons.more_vert, color: Colors.pink[400]),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Chỉnh sửa'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Xóa', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EventFormScreen(event: event),
                                            ),
                                          ).then((_) => _loadEvents());
                                        } else if (value == 'delete') {
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
                                                  child: const Text(
                                                    'Xóa',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            try {
                                              await EventApiService.deleteEvent(event.id!);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đã xóa sự kiện')),
                                                );
                                                _loadEvents();
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi xóa sự kiện: $e')),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
