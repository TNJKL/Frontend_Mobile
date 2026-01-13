import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'event_list_screen.dart';
import 'event_form_screen.dart';
import 'event_detail_screen.dart';

// Event Management Screens
import 'budget_screen.dart';
import 'task_screen.dart';
import 'event_vendor_screen.dart';
import 'menu_list_screen.dart';
import 'timeline_screen.dart';
import 'guest_management/guest_list_screen.dart';
import 'transaction_history_screen.dart';

import '../Models/event.dart';
import '../services/event_api_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'admin_conversation_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<List<Event>>? _eventsFuture;
  Event? _activeEvent;
  String _userRole = 'User';
  final ChatService _chatService = ChatService();
  bool _isConnectingChat = false;

  // Sample banner data
  final List<String> imgList = [
    'https://grandpalace.com.vn/multidata/lnom2207.jpg',
    'https://tonywedding.vn/wp-content/uploads/2022/12/135785322_3575164409195855_8293012649545980265_n-1536x1024.jpg',
    'https://www.anhieuwedding.com/wp-content/uploads/2023/06/nha-hang-tiec-cuoi-nhan-tam.jpg',
    'https://hotelnikkosaigon.com.vn/images/upload/230518/1684351567_0045.jpg',
  ];

  late StreamSubscription _messageSubscription;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
    _loadRole();
    _initChatListener();
  }

  void _initChatListener() async {
    await _chatService.initConnection();
    _messageSubscription = _chatService.messageStream.listen((data) {
       if (!_chatService.isInChatScreen) {
          if (mounted) {
            _showNotification(data['content']);
          }
       }
    });
  }

  void _showNotification(String content) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.pink[400]!, Colors.orangeAccent]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1)
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.mark_chat_unread_rounded, color: Colors.pink, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Tin nhắn mới!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0,1))])),
                      const SizedBox(height: 4),
                      Text(content, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                GestureDetector(
                   onTap: () => entry.remove(),
                   child: const Icon(Icons.close, color: Colors.white, size: 20)
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
        if (entry.mounted) entry.remove();
    });
  }

  Future<void> _loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'User';
    });
  }

  Future<void> _openChatWithSupport() async {
    if (_isConnectingChat) return;
    setState(() => _isConnectingChat = true);
    
    final supportInfo = await _chatService.getSupportInfo();
    setState(() => _isConnectingChat = false);

    if (supportInfo != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => 
        ChatScreen(receiverId: supportInfo['supportId']!, receiverName: supportInfo['supportName']!)
      ));
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hiện chưa có nhân viên hỗ trợ nào online.')));
    }
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = EventApiService.getMyEvents();
    });
  }

  Future<void> _logout(BuildContext context) async {
    _messageSubscription.cancel();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
  
  // Helper to handle navigation: If active event exists, go to module, else prompt/list
  void _navigateToModule(Widget Function(Event) pageBuilder) {
    if (_activeEvent != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => pageBuilder(_activeEvent!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn hoặc tạo một sự kiện trước!'),
          action: SnackBarAction(label: 'Chọn', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventListScreen()));
            _refreshEvents();
          }),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.favorite, color: Colors.pink, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Wedding Planner',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (_userRole != 'User') // Staff & Admin see Inbox
            IconButton(
              icon: const Icon(Icons.mark_chat_unread, color: Colors.pinkAccent), 
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminConversationListScreen()))
            ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.black54), onPressed: () => _logout(context)),
        ],
      ),
      floatingActionButton: _userRole == 'User' ? FloatingActionButton.extended(
        onPressed: _openChatWithSupport,
        backgroundColor: Colors.pink[400],
        icon: _isConnectingChat 
           ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
           : const Icon(Icons.support_agent),
        label: const Text("Hỗ trợ"),
      ) : null,
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
           // Handle logic to set active event (e.g. nearest upcoming)
           if (snapshot.hasData && snapshot.data!.isNotEmpty) {
             _activeEvent = snapshot.data!.first; // Simple logic for now
           } else {
             _activeEvent = null;
           }
           
           final events = snapshot.data ?? [];

           return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 1. Carousel Slider
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16/9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    viewportFraction: 0.85,
                  ),
                  items: imgList.map((item) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(16.0),
                            image: DecorationImage(image: NetworkImage(item), fit: BoxFit.cover),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0,4))]
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent]
                              )
                            ),
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.bottomLeft,
                            child: const Text('Kế hoạch hoàn hảo\ncho ngày trọng đại', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 30),
                
                // 2. Categories / Tools
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Công Cụ Lập Kế Hoạch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       if (_activeEvent != null)
                        InkWell(
                          onTap: () async {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: _activeEvent!))); 
                          },
                          child: const Text('Vào sự kiện >', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.w600)),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildCategoryItem('Ngân sách', Icons.attach_money, Colors.green, () => _navigateToModule((e) => BudgetScreen(event: e))),
                      _buildCategoryItem('Khách mời', Icons.people_outline, Colors.blue, () => _navigateToModule((e) => GuestListScreen(event: e))),
                      _buildCategoryItem('Checklist', Icons.check_circle_outline, Colors.orange, () => _navigateToModule((e) => TaskScreen(event: e))),
                      _buildCategoryItem('Dịch vụ', Icons.storefront, Colors.purple, () => _navigateToModule((e) => EventVendorScreen(event: e))),
                      _buildCategoryItem('Thực đơn', Icons.restaurant_menu, Colors.redAccent, () => _navigateToModule((e) => MenuListScreen(event: e))),
                      _buildCategoryItem('Kịch bản', Icons.access_time_filled_rounded, Colors.teal, () => _navigateToModule((e) => TimelineScreen(event: e))),
                       _buildCategoryItem('Lịch sử GD', Icons.history_edu, Colors.blueGrey, () => _navigateToModule((e) => const TransactionHistoryScreen())),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. My Events Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sự Kiện Của Bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () async {
                         final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventFormScreen()));
                         if (result == true) _refreshEvents();
                      }, icon: const Icon(Icons.add_circle, color: Colors.pink, size: 28))
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                SizedBox(
                  height: 180,
                  child: events.isEmpty 
                    ? _buildEmptyEvents(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _buildEventCard(context, event);
                        },
                      ),
                ),
                
                const SizedBox(height: 40),
                
                // 4. Promo / Ideas (Simple banner or list)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purple[50]!, Colors.blue[50]!]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.lightbulb, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cần tìm ý tưởng?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Khám phá xu hướng cưới 2026', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
           );
        },
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87), textAlign: TextAlign.center,)
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
        _refreshEvents();
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          image: event.imageUrl != null 
            ? DecorationImage(image: NetworkImage(event.imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
            : null,
          gradient: event.imageUrl == null ? LinearGradient(colors: [Colors.pink[300]!, Colors.purple[300]!]) : null
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                 child: Text(
                   DateFormat('dd/MM/yyyy').format(event.startTime), 
                   style: const TextStyle(color: Colors.white, fontSize: 12)
                 ),
              ),
              const SizedBox(height: 8),
              Text(
                event.title ?? 'Sự kiện cưới',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location ?? 'Chưa cập nhật',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEvents(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note, color: Colors.grey, size: 30),
            const SizedBox(height: 8),
            const Text('Bạn chưa có sự kiện nào', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () async {
                 final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EventFormScreen()));
                 if (result == true) _refreshEvents();
              },
              child: const Text('Tạo ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
