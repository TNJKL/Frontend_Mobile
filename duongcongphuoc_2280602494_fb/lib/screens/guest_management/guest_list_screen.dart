import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Models/event.dart';
import '../../Models/guest.dart';
import '../../services/guest_api_service.dart';
import 'seating_chart_screen.dart';
import 'guest_qr_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // For calls
import '../../Models/event.dart';
import '../../Models/guest.dart';
import '../../services/guest_api_service.dart';
import 'seating_chart_screen.dart';

class GuestListScreen extends StatefulWidget {
  final Event event;

  const GuestListScreen({super.key, required this.event});

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> with SingleTickerProviderStateMixin {
  final GuestApiService _apiService = GuestApiService();
  List<Guest> _guests = [];
  bool _isLoading = true;
  late TabController _tabController;
  String _filterStatus = 'Tất cả'; // Status filter state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadGuests();
  }

  Future<void> _loadGuests() async {
    try {
      final guests = await _apiService.getGuests(widget.event.id!);
      setState(() {
        _guests = guests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải danh sách: $e')));
      }
    }
  }

  Future<void> _importExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        File file = File(result.files.single.path!);
        await _apiService.importGuests(widget.event.id!, file);
        await _loadGuests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import thành công!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi Import: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGuest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc muốn xoá khách này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteGuest(id);
      _loadGuests();
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Sanitize phone number: remove spaces and non-digit characters (keep + if present)
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể thực hiện cuộc gọi')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  List<Guest> _getFilteredGuests(int tabIndex) {
    // 1. Filter by Type (Tab)
    List<Guest> filteredList = _guests;
    if (tabIndex == 1) filteredList = _guests.where((g) => g.guestType == 'Nhà Trai').toList();
    else if (tabIndex == 2) filteredList = _guests.where((g) => g.guestType == 'Nhà Gái').toList();
    else if (tabIndex == 3) filteredList = _guests.where((g) => g.guestType == 'Bạn Bè').toList();
    else if (tabIndex == 4) filteredList = _guests.where((g) => g.guestType == 'Đồng Nghiệp').toList();
    else if (tabIndex == 5) filteredList = _guests.where((g) => g.guestType == 'Khác').toList();

    // 2. Filter by Status (Chip)
    if (_filterStatus == 'Đã đến') {
      filteredList = filteredList.where((g) => g.rsvpStatus == 'Attended').toList();
    } else if (_filterStatus == 'Chưa đến') {
      filteredList = filteredList.where((g) => g.rsvpStatus != 'Attended').toList();
    }

    return filteredList;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Nhà Trai': return Colors.blue;
      case 'Nhà Gái': return Colors.pink;
      case 'Bạn Bè': return Colors.orange;
      case 'Đồng Nghiệp': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Khách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Excel',
            onPressed: _importExcel,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Sơ đồ bàn tiệc',
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => SeatingChartScreen(event: widget.event)));
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
             height: 50,
             margin: const EdgeInsets.only(bottom: 10),
             child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              splashBorderRadius: BorderRadius.circular(25),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.pink[400],
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Tất cả'))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Nhà Trai'))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Nhà Gái'))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Bạn Bè'))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Đồng Nghiệp'))),
                Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Khác'))),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
           gradient: LinearGradient(
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
             colors: [Colors.pink[400]!, Colors.pink[50]!, Colors.white]
           )
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Dashboard Stats
              if (!_isLoading)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[200]!)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Tổng khách", "${_guests.length}", Colors.blue),
                      Container(width: 1, height: 40, color: Colors.blue[200]),
                      _buildStatItem("Đã đến", "${_guests.where((g) => g.rsvpStatus == 'Attended').length}", Colors.green),
                      Container(width: 1, height: 40, color: Colors.blue[200]),
                      _buildStatItem("Chưa đến", "${_guests.length - _guests.where((g) => g.rsvpStatus == 'Attended').length}", Colors.orange),
                    ],
                  ),
                ),
                
              // Filter Chips
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Tất cả"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Đã đến"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Chưa đến"),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(6, (index) {
                        final list = _getFilteredGuests(index);
                        if (list.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('Chưa có khách nào trong nhóm này', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          );
                        }
                        
                        return RefreshIndicator(
                      onRefresh: _loadGuests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final guest = list[i];
                          final typeColor = _getTypeColor(guest.guestType);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                              border: Border.all(color: Colors.grey[100]!)
                            ),
                            child: InkWell(
                              onTap: () {}, // Can add detail view later
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: typeColor.withOpacity(0.1),
                                      child: Text(
                                        guest.fullName.isNotEmpty ? guest.fullName[0].toUpperCase() : '?',
                                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guest.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(guest.guestType, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold)),
                                    ),
                                    if (guest.tableNumber != null) 
                                      Text('• Bàn ${guest.tableNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 13))
                                    else
                                      Text('• Chưa xếp bàn', style: TextStyle(color: Colors.grey[400], fontSize: 13, fontStyle: FontStyle.italic)),
                                    if (guest.rsvpStatus == 'Attended')
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)),
                                         child: const Text('Đã tham dự', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                       )
                                  ],
                                ),
                                if (guest.phone != null && guest.phone!.isNotEmpty) ...[
                                   const SizedBox(height: 4),
                                   Row(
                                     children: [
                                       Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                                       const SizedBox(width: 4),
                                       Text(guest.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                     ],
                                   )
                                ]
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (guest.phone != null && guest.phone!.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () => _makePhoneCall(guest.phone!),
                                  visualDensity: VisualDensity.compact,
                                ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_2, color: Colors.blue),
                                onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => GuestQRScreen(guest: guest)));
                                },
                                tooltip: "Xem vé mời",
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                                onPressed: () => _deleteGuest(guest.id),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    ),
  ],
),
),
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuestDialog,
        backgroundColor: Colors.pink[400],
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm khách', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddGuestDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'Khác';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.person_add, color: Colors.pink[400]), SizedBox(width: 8), Text('Thêm Khách Mới')]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và Tên (*)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Phân loại', border: OutlineInputBorder()),
                items: ['Nhà Trai', 'Nhà Gái', 'Bạn Bè', 'Đồng Nghiệp', 'Khác'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => selectedType = v!,
              ),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400], foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên khách')));
                return;
              }
              final newGuest = Guest(id: 0, eventId: widget.event.id!, fullName: nameController.text, email: emailController.text, phone: phoneController.text, guestType: selectedType);
              try {
                await _apiService.createGuest(newGuest);
                Navigator.pop(context);
                _loadGuests();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm khách mới!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = label);
      },
      selectedColor: Colors.pink[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.pink[800] : Colors.black87, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
