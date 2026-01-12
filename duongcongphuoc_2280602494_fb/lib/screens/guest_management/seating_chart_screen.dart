import 'package:flutter/material.dart';
import '../../Models/event.dart';
import '../../Models/guest.dart';
import '../../services/guest_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeatingChartScreen extends StatefulWidget {
  final Event event;

  const SeatingChartScreen({super.key, required this.event});

  @override
  State<SeatingChartScreen> createState() => _SeatingChartScreenState();
}

class _SeatingChartScreenState extends State<SeatingChartScreen> {
  final GuestApiService _apiService = GuestApiService();
  List<Guest> _guests = [];
  bool _isLoading = true;
  int? _selectedGuestId;
  int _totalTables = 20;
  String _selectedFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadTableCount();
    _loadGuests();
  }

  Future<void> _loadTableCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalTables = prefs.getInt('table_count_${widget.event.id}') ?? 20;
    });
  }

  Future<void> _saveTableCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('table_count_${widget.event.id}', count);
  }

  Future<void> _loadGuests() async {
    try {
      final guests = await _apiService.getGuests(widget.event.id!);
      setState(() {
        _guests = guests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignGuestToTable(int guestId, int tableNumber) async {
    final guestIndex = _guests.indexWhere((g) => g.id == guestId);
    if (guestIndex == -1) return;

    final oldGuest = _guests[guestIndex];
    final updatedGuest = Guest(
      id: oldGuest.id,
      eventId: oldGuest.eventId,
      fullName: oldGuest.fullName,
      email: oldGuest.email,
      phone: oldGuest.phone,
      guestType: oldGuest.guestType,
      rsvpStatus: oldGuest.rsvpStatus,
      plusOneCount: oldGuest.plusOneCount,
      tableNumber: tableNumber,
      dietaryRequirements: oldGuest.dietaryRequirements,
      notes: oldGuest.notes,
      giftReceived: oldGuest.giftReceived,
      giftDescription: oldGuest.giftDescription,
    );

    setState(() {
      _guests[guestIndex] = updatedGuest;
      _selectedGuestId = null;
    });

    try {
      await _apiService.updateGuest(updatedGuest);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xếp ${updatedGuest.fullName} vào bàn $tableNumber')));
    } catch (e) {
      setState(() {
        _guests[guestIndex] = oldGuest;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật bàn')));
    }
  }

  Future<void> _unassignGuest(int guestId) async {
    final guestIndex = _guests.indexWhere((g) => g.id == guestId);
    if (guestIndex == -1) return;

    final oldGuest = _guests[guestIndex];
    final updatedGuest = Guest(
      id: oldGuest.id,
      eventId: oldGuest.eventId,
      fullName: oldGuest.fullName,
      email: oldGuest.email,
      phone: oldGuest.phone,
      guestType: oldGuest.guestType,
      rsvpStatus: oldGuest.rsvpStatus,
      plusOneCount: oldGuest.plusOneCount,
      tableNumber: null,
      dietaryRequirements: oldGuest.dietaryRequirements,
      notes: oldGuest.notes,
      giftReceived: oldGuest.giftReceived,
      giftDescription: oldGuest.giftDescription,
    );

    setState(() {
      _guests[guestIndex] = updatedGuest;
    });

    try {
      await _apiService.updateGuest(updatedGuest);
    } catch (e) {
      setState(() {
        _guests[guestIndex] = oldGuest;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _autoAssign() {
    final sortedGuests = List<Guest>.from(_guests.where((g) => g.tableNumber == null));
    // Prioritize older/VIP types if we had logic, here just grouping
    sortedGuests.sort((a, b) => a.guestType.compareTo(b.guestType));

    int currentTable = 1;
    int currentCount = 0;

    for (var guest in sortedGuests) {
      // Find a table that isn't full
      while (currentCount >= 10 && currentTable <= _totalTables) {
        currentTable++;
        currentCount = _guests.where((g) => g.tableNumber == currentTable).length;
      }
      
      if (currentTable > _totalTables) break; // No more tables

      _assignGuestToTable(guest.id, currentTable);
      currentCount++;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tự động xếp bàn!')));
  }

  Future<void> _resetAllSeating() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đặt lại'),
        content: const Text('Bạn có chắc muốn gỡ TOÀN BỘ khách khỏi bàn Tiệc không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gỡ hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final seatedGuests = _guests.where((g) => g.tableNumber != null).toList();
      for (var guest in seatedGuests) {
         await _unassignGuest(guest.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gỡ bỏ toàn bộ!')));
    }
  }

  void _showConfigTablesDialog() {
    final controller = TextEditingController(text: _totalTables.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấu hình số bàn'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số lượng bàn', suffixText: 'bàn', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400], foregroundColor: Colors.white),
            onPressed: () async {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                // If reducing tables, unassign guests in removed tables
                if (val < _totalTables) {
                   final removedGuests = _guests.where((g) => g.tableNumber != null && g.tableNumber! > val).toList();
                   for (var guest in removedGuests) {
                     await _unassignGuest(guest.id);
                   }
                }
                setState(() => _totalTables = val);
                await _saveTableCount(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }

  void _showTableDetails(int tableNum) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final guestsAtTable = _guests.where((g) => g.tableNumber == tableNum).toList();
            return Container(
              padding: const EdgeInsets.all(20),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Bàn số $tableNum', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
                       Text('${guestsAtTable.length}/10 Khách', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                     ],
                   ),
                   const Divider(),
                   Expanded(
                     child: guestsAtTable.isEmpty
                     ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.table_restaurant, size: 48, color: Colors.grey[300]), Text('Bàn trống', style: TextStyle(color: Colors.grey))]))
                     : ListView.builder(
                       itemCount: guestsAtTable.length,
                       itemBuilder: (context, index) {
                         final guest = guestsAtTable[index];
                         return ListTile(
                           leading: CircleAvatar(backgroundColor: Colors.pink[50], child: Text(guest.fullName[0], style: TextStyle(color: Colors.pink[400]))),
                           title: Text(guest.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                           subtitle: Text(guest.guestType),
                           trailing: IconButton(
                             icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                             onPressed: () async {
                               await _unassignGuest(guest.id);
                               setStateSheet(() {}); // Refresh sheet
                             },
                           ),
                         );
                       },
                     ),
                   )
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Guest> _getFilteredUnseatedGuests() {
    final unseated = _guests.where((g) => g.tableNumber == null).toList();
    if (_selectedFilter == 'Tất cả') return unseated;
    return unseated.where((g) => g.guestType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unseatedGuests = _getFilteredUnseatedGuests();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sơ Đồ Bàn Tiệc', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Tự động xếp',
            onPressed: _autoAssign,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'reset') _resetAllSeating();
              if (value == 'config') _showTableDetails; // Should be _showConfigTablesDialog but popup logic needs call
              if (value == 'settings') _showConfigTablesDialog();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Cấu hình số bàn')])),
              const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.refresh, color: Colors.red, size: 20), SizedBox(width: 8), Text('Đặt lại tất cả', style: TextStyle(color: Colors.red))])),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Unseated List Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.pink[400], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Khách chờ xếp bàn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          dropdownColor: Colors.pink[400],
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 18),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          items: ['Tất cả', 'Nhà Trai', 'Nhà Gái', 'Bạn Bè', 'Đồng Nghiệp', 'Khác'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedFilter = v!),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: unseatedGuests.isEmpty
                  ? Center(child: Text("Đã xếp hết khách!", style: TextStyle(color: Colors.white.withOpacity(0.8))))
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: unseatedGuests.length,
                    itemBuilder: (context, index) {
                      final guest = unseatedGuests[index];
                      final isSelected = _selectedGuestId == guest.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGuestId = isSelected ? null : guest.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 100, // Increased width
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: Colors.pink[800]!, width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected ? Colors.pink[100] : Colors.white,
                                child: Text(guest.fullName[0], style: TextStyle(color: isSelected ? Colors.pink : Colors.blueGrey, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  guest.fullName, 
                                  textAlign: TextAlign.center, 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: isSelected ? Colors.black87 : Colors.white, 
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                  )
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: _totalTables,
              itemBuilder: (context, index) {
                final tableNum = index + 1;
                final guestsAtTable = _guests.where((g) => g.tableNumber == tableNum).toList();
                final isFull = guestsAtTable.length >= 10;
                
                return GestureDetector(
                  onTap: () {
                    if (_selectedGuestId != null) {
                      if (!isFull) {
                        _assignGuestToTable(_selectedGuestId!, tableNum);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bàn này đã đầy!')));
                      }
                    } else {
                      _showTableDetails(tableNum);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 4))
                      ],
                      border: Border.all(
                        color: isFull ? Colors.red[300]! : (_selectedGuestId != null ? Colors.green[300]! : Colors.grey[200]!),
                        width: isFull || _selectedGuestId != null ? 3 : 1
                      )
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Chairs (Visual decoration)
                        if (guestsAtTable.isNotEmpty)
                          ...List.generate(guestsAtTable.length, (i) {
                             final angle = (2 * 3.14159 * i) / 10; // Distribute 10 spots
                             return Transform.translate(
                               offset: Offset(55 *  (i % 2 == 0 ? 1 : 0.9) *  -1 *  (i < 5 ? -1 : 1) , 0), // Specific math simplification for visual effect only
                             ); 
                             // Proper chair positioning would need cos/sin math which requires dart:math
                          }),
                        
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.table_bar, size: 32, color: isFull ? Colors.red[300] : Colors.pink[300]),
                            Text('Bàn $tableNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isFull ? Colors.red[50] : Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${guestsAtTable.length}/10', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold,
                                color: isFull ? Colors.red : Colors.green[700]
                              )),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
