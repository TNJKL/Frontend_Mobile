import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'event_list_screen.dart';
import 'event_category_management_screen.dart';
import 'user_management_screen.dart';
import 'admin_menu_management_screen.dart';
import 'vendor_list_screen.dart';
import 'admin_timeline_selection_screen.dart';
import 'admin_service_package_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _userRole = 'Admin';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'Admin';
      _username = prefs.getString('saved_username') ?? '';
      if (_userRole.isNotEmpty) {
        _userRole = _userRole[0].toUpperCase() + _userRole.substring(1);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    bool isStaff = _userRole.toLowerCase() == 'staff';
    final primaryColor = isStaff ? Colors.orange : const Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Modern light grey background
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isStaff
                        ? [Colors.orange[400]!, Colors.deepOrangeAccent]
                        : [const Color(0xFFE91E63), const Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                       right: -50, top: -50,
                       child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle))
                    ),
                    Positioned(
                       left: 20, bottom: 20,
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text('Xin chào,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                           Text(_userRole.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                         ],
                       )
                    )
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _logout(context), 
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20)
                )
              )
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Summary Cards (Mockup)
                  if (!isStaff)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSummaryCard('Tổng sự kiện', '12', Colors.blue, Icons.event),
                          const SizedBox(width: 12),
                          _buildSummaryCard('Duyệt giá', '3', Colors.orange, Icons.pending_actions),
                          const SizedBox(width: 12),
                          _buildSummaryCard('Doanh thu', '32.5tr', Colors.green, Icons.attach_money),
                        ],
                      ),
                    ),
                  if (!isStaff) const SizedBox(height: 24),

                  const Text('Dịch Vụ & Sự Kiện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildMenuCard(context, 'QL Sự Kiện', 'Danh sách tiệc', Icons.calendar_month, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventListScreen()))),
                      _buildMenuCard(context, 'Duyệt Kịch Bản', 'Timeline tiệc', Icons.view_timeline, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTimelineSelectionScreen()))),
                      _buildMenuCard(context, 'Thực Đơn', 'Món ăn & Menu', Icons.restaurant_menu, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMenuManagementScreen()))),
                      _buildMenuCard(context, 'Đối Tác', 'Nhà cung cấp', Icons.storefront, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorListScreen(isSelecting: false)))),
                    ],
                  ),

                  if (!isStaff) ...[
                    const SizedBox(height: 24),
                    const Text('Hệ Thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 12),
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMenuCard(context, 'Gói Dịch Vụ', 'Combo trọn gói', Icons.inventory_2, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminServicePackageManagementScreen()))),
                         _buildMenuCard(context, 'Danh Mục Event', 'Loại hình tiệc', Icons.category, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCategoryManagementScreen()))),
                        _buildMenuCard(context, 'Người Dùng', 'Tài khoản', Icons.people, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                      ],
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                     color: color.withOpacity(0.1),
                     shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500]), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
