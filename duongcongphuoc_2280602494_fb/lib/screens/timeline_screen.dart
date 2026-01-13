import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../Models/event_timeline.dart';
import '../Models/vendor.dart';
import '../services/timeline_api_service.dart';
import '../services/vendor_api_service.dart';

class TimelineScreen extends StatefulWidget {
  final Event event;

  const TimelineScreen({super.key, required this.event});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TimelineApiService _apiService = TimelineApiService();
  final VendorApiService _vendorApiService = VendorApiService();
  List<EventTimeline> _timelines = [];
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');

      final timelines = await _apiService.getTimelinesByEventId(widget.event.id!);
      final eventVendors = await _vendorApiService.getEventVendors(widget.event.id!);
      
      // Deduplicate vendors by ID
      final Map<int, Vendor> uniqueVendorsMap = {};
      for (var ev in eventVendors) {
        if (ev.vendor != null) {
          uniqueVendorsMap[ev.vendor!.id] = ev.vendor!;
        }
      }
      final vendors = uniqueVendorsMap.values.toList();

      setState(() {
        _timelines = timelines;
        _vendors = vendors;
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading timeline data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showTimelineDialog([EventTimeline? timeline]) async {
    final titleController = TextEditingController(text: timeline?.title);
    final locationController = TextEditingController(text: timeline?.location);
    final descriptionController = TextEditingController(text: timeline?.description);
    final personController = TextEditingController(text: timeline?.personInCharge);
    
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay? endTime;

    if (timeline != null) {
      startTime = TimeOfDay.fromDateTime(timeline.startTime);
      if (timeline.endTime != null) {
        endTime = TimeOfDay.fromDateTime(timeline.endTime!);
      }
    }
    int? selectedVendorId = timeline?.vendorId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              timeline == null ? 'Thêm Hoạt Động Mới' : 'Cập Nhật Hoạt Động',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (timeline != null && timeline.status == 'Approved')
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Lưu ý: Chỉnh sửa sẽ làm mất trạng thái "Đã duyệt".', style: TextStyle(color: Colors.orange, fontSize: 12))),
                          ],
                        ),
                      ),
                   _buildTextField(titleController, 'Tên hoạt động', Icons.event_note),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(
                         child: _buildTimePickerButton(
                           context, 
                           'Bắt đầu', 
                           startTime, 
                           (val) => setStateDialog(() => startTime = val)
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: _buildTimePickerButton(
                           context, 
                           'Kết thúc', 
                           endTime, 
                           (val) => setStateDialog(() => endTime = val),
                           isOptional: true
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildTextField(locationController, 'Địa điểm', Icons.location_on_outlined),
                   const SizedBox(height: 16),
                   DropdownButtonFormField<int>(
                    value: selectedVendorId,
                    decoration: InputDecoration(
                       labelText: 'Nhà cung cấp phụ trách',
                       prefixIcon: const Icon(Icons.storefront, color: Colors.pink),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
                    ),
                    items: [
                      const DropdownMenuItem<int>(value: null, child: Text('Không có')),
                      ..._vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                    ],
                    onChanged: (val) => setStateDialog(() => selectedVendorId = val),
                  ),
                   const SizedBox(height: 16),
                   _buildTextField(personController, 'Người phụ trách', Icons.person_outline),
                   const SizedBox(height: 16),
                   _buildTextField(descriptionController, 'Ghi chú chi tiết', Icons.description_outlined, maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Hủy', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  
                  final baseDate = widget.event.startTime; // Use Event Date instead of Now
                  final startDt = DateTime(baseDate.year, baseDate.month, baseDate.day, startTime.hour, startTime.minute);
                  final endDt = endTime != null 
                      ? DateTime(baseDate.year, baseDate.month, baseDate.day, endTime!.hour, endTime!.minute)
                      : null;

                  final newTimeline = EventTimeline(
                    id: timeline?.id ?? 0,
                    eventId: widget.event.id!,
                    title: titleController.text,
                    startTime: startDt,
                    endTime: endDt,
                    location: locationController.text,
                    description: descriptionController.text,
                    vendorId: selectedVendorId,
                    personInCharge: personController.text,
                    status: 'Pending', // Force reset status on edit/create
                  );

                  try {
                    timeline == null 
                      ? await _apiService.createTimeline(newTimeline)
                      : await _apiService.updateTimeline(newTimeline);
                    
                    if (context.mounted) Navigator.pop(context);
                    _loadData();
                  } catch (e) {
                     // Error handling
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('Lưu Thay Đổi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approveTimeline(EventTimeline timeline) async {
    final updatedTimeline = EventTimeline(
      id: timeline.id,
      eventId: timeline.eventId,
      title: timeline.title,
      startTime: timeline.startTime,
      endTime: timeline.endTime,
      location: timeline.location,
      description: timeline.description,
      vendorId: timeline.vendorId,
      personInCharge: timeline.personInCharge,
      displayOrder: timeline.displayOrder,
      status: 'Approved',
      isHidden: timeline.isHidden,
    );

    try {
      await _apiService.updateTimeline(updatedTimeline);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt hoạt động! ✅')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pink[300]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)
      ),
    );
  }

  Widget _buildTimePickerButton(BuildContext context, String label, TimeOfDay? time, Function(TimeOfDay) onTimePicked, {bool isOptional = false}) {
     return InkWell(
       onTap: () async {
         final picked = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
         if (picked != null) onTimePicked(picked);
       },
       child: Container(
         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
         decoration: BoxDecoration(
           border: Border.all(color: Colors.grey[400]!),
           borderRadius: BorderRadius.circular(12),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
             const SizedBox(height: 4),
             Row(
               children: [
                 Icon(Icons.access_time, size: 16, color: Colors.pink[300]),
                 const SizedBox(width: 8),
                 Text(
                   time != null ? time.format(context) : (isOptional ? '--:--' : 'Chọn giờ'),
                   style: TextStyle(fontWeight: FontWeight.bold, color: time != null ? Colors.black87 : Colors.grey),
                 ),
               ],
             )
           ],
         ),
       ),
     );
  }

  Future<void> _deleteTimeline(int id) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hoạt động này?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteTimeline(id);
      _loadData();
    }
  }

  Future<void> _createTemplate(String type) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.createTemplate(widget.event.id!, type);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã áp dụng kịch bản mẫu!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      setState(() => _isLoading = false);
    }
  }
  
  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('trang điểm') || t.contains('makeup')) return Icons.brush;
    if (t.contains('xe') || t.contains('rước') || t.contains('di chuyển')) return Icons.directions_car_filled;
    if (t.contains('lễ') || t.contains('trao') || t.contains('tuyên thệ')) return Icons.favorite;
    if (t.contains('ăn') || t.contains('tiệc') || t.contains('dinner')) return Icons.restaurant;
    if (t.contains('chụp') || t.contains('ảnh')) return Icons.camera_alt;
    if (t.contains('nhạc') || t.contains('nhảy') || t.contains('party')) return Icons.music_note;
    if (t.contains('khách') || t.contains('đón')) return Icons.people_alt;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    _timelines.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kịch Bản Ngày Cưới', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
           IconButton(
             icon: const Icon(Icons.add_circle, color: Colors.pink, size: 28),
             onPressed: () => _showTimelineDialog(),
           ),
           PopupMenuButton<String>(
             onSelected: (value) async {
               if (value == 'clear') {
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: const Text('Xóa toàn bộ kịch bản?'),
                     content: const Text('Bạn có chắc muốn xóa hết để chọn lại mẫu không? Hành động này không thể hoàn tác.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                       TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa Hết', style: TextStyle(color: Colors.red))),
                     ],
                   ),
                 );
                 
                 if (confirm == true) {
                   setState(() => _isLoading = true);
                   try {
                     // Delete all items one by one (Temporary solution until backend supports Bulk Delete)
                     for (var item in _timelines) {
                       await _apiService.deleteTimeline(item.id);
                     }
                     await _loadData();
                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ kịch bản!')));
                   } catch (e) {
                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                     setState(() => _isLoading = false);
                   }
                 }
               }
             },
             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
               const PopupMenuItem<String>(
                 value: 'clear',
                 child: Row(
                   children: [
                     Icon(Icons.delete_forever, color: Colors.red),
                     SizedBox(width: 8),
                     Text('Xóa toàn bộ & Chọn lại', style: TextStyle(color: Colors.red)),
                   ],
                 ),
               ),
             ],
           )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _timelines.isEmpty 
           ? _buildEmptyState()
           : _buildTimelineList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle),
              child: Icon(Icons.access_time_filled, size: 64, color: Colors.pink[300]),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có kịch bản',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
             const SizedBox(height: 8),
            const Text(
              'Bắt đầu bằng cách chọn mẫu kịch bản chuyên nghiệp hoặc tự tạo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildTemplateCard(
              'Lễ Gia Tiên (Truyền Thống)', 
              'Đầy đủ các nghi thức: Rước dâu, Lại quả...', 
              Icons.family_restroom, 
              Colors.orange,
              () => _createTemplate('Traditional')
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              'Tiệc Cưới (Hiện Đại)', 
              'Kịch bản sảnh tiệc: Đón khách, Khai tiệc...', 
              Icons.wine_bar, 
              Colors.purple,
              () => _createTemplate('Modern') 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
               child: Icon(icon, color: color, size: 24),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                   Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                 ],
               ),
             ),
             Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.5))
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      itemCount: _timelines.length,
      itemBuilder: (context, index) {
         final item = _timelines[index];
         final isLast = index == _timelines.length - 1;
         final isApproved = item.status == 'Approved';
         
         return Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             // 1. Time Column
             SizedBox(
               width: 50,
               child: Padding(
                 padding: const EdgeInsets.only(top: 0),
                 child: Column(
                   children: [
                     Text(DateFormat('HH:mm').format(item.startTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                     if (item.endTime != null)
                      Text(DateFormat('HH:mm').format(item.endTime!), style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                   ],
                 ),
               ),
             ),
             
             // 2. Connector Line
             Column(
               children: [
                 Container(
                   margin: const EdgeInsets.symmetric(horizontal: 10),
                   width: 16, height: 16,
                   decoration: BoxDecoration(
                     color: isApproved ? Colors.green : Colors.white,
                     shape: BoxShape.circle,
                     border: Border.all(color: isApproved ? Colors.green : Colors.orange, width: 3),
                     boxShadow: [BoxShadow(color: (isApproved ? Colors.green : Colors.orange).withOpacity(0.3), blurRadius: 4)]
                   ),
                   child: isApproved ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                 ),
                 if (!isLast)
                  Container(
                    width: 2,
                    height: 100, 
                    color: Colors.grey[200],
                  )
               ],
             ),

             // 3. Card Content
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.only(bottom: 24.0),
                 child: GestureDetector(
                   onTap: () => _showTimelineDialog(item),
                   onLongPress: () => _deleteTimeline(item.id),
                   child: Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                       ],
                       border: Border.all(color: isApproved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2))
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             Icon(_getIconForTitle(item.title), color: isApproved ? Colors.green[300] : Colors.orange[300], size: 20),
                             const SizedBox(width: 8),
                             Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                             if ((_userRole == 'Admin' || _userRole == 'Staff') && !isApproved)
                               InkWell(
                                 onTap: () => _approveTimeline(item),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                                   child: const Text('Duyệt', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                 ),
                               )
                           ],
                         ),
                         if (item.location != null && item.location!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(item.location!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            )
                         ],
                         // Status chip
                         const SizedBox(height: 8),
                         Wrap(
                           spacing: 8,
                           children: [
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: isApproved ? Colors.green[50] : Colors.orange[50],
                                 borderRadius: BorderRadius.circular(6)
                               ),
                               child: Text(
                                 isApproved ? 'Đã duyệt' : 'Chờ duyệt',
                                 style: TextStyle(fontSize: 11, color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                               ),
                             ),
                             if (item.personInCharge != null && item.personInCharge!.isNotEmpty)
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                                 child: Text('Phụ trách: ${item.personInCharge}', style: TextStyle(fontSize: 11, color: Colors.blue[800], fontWeight: FontWeight.w600)),
                               ),
                             if (item.vendorId != null)
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(6)),
                                 child: Text(
                                   'DV: ${_vendors.firstWhere((v) => v.id == item.vendorId, orElse: () => Vendor(id: 0, name: 'Unknown', vendorType: '')).name}', 
                                   style: TextStyle(fontSize: 11, color: Colors.purple[800], fontWeight: FontWeight.w600)
                                 ),
                               )
                           ],
                         )
                       ],
                     ),
                   ),
                 ),
               ),
             )
           ],
         );
      },
    );
  }
}
