import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../Models/event_vendor.dart';
import '../Models/vendor.dart';
import '../services/vendor_api_service.dart';
import '../utils/user_helper.dart';
import 'vendor_list_screen.dart'; // Import Vendor List logic
import 'vendor_detail_screen.dart';
import '../services/budget_api_service.dart';
import '../Models/budget.dart';
import '../Models/expense.dart';

class EventVendorScreen extends StatefulWidget {
  final Event event;

  const EventVendorScreen({super.key, required this.event});

  @override
  State<EventVendorScreen> createState() => _EventVendorScreenState();
}

class _EventVendorScreenState extends State<EventVendorScreen> {
  final VendorApiService _apiService = VendorApiService();
  final BudgetApiService _budgetService = BudgetApiService();
  List<EventVendor> _contracts = [];
  List<Budget> _budgets = [];
  bool _isLoading = true;
  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadContracts();
    _loadBudgets();
  }

  Future<void> _loadUserRole() async {
    final role = await UserHelper.getUserRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await _apiService.getEventVendors(widget.event.id!);
      setState(() => _contracts = contracts);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await _budgetService.getBudgetsByEventId(widget.event.id!);
      setState(() => _budgets = budgets);
    } catch (e) {
      // Silent error
    }
  }

  // Helper to get Icon based on Service Type
  IconData _getServiceIcon(String? type) {
    if (type == null) return Icons.star_border;
    final lower = type.toLowerCase();
    if (lower.contains('chụp') || lower.contains('ảnh')) return Icons.camera_alt;
    if (lower.contains('makeup') || lower.contains('trang điểm')) return Icons.brush;
    if (lower.contains('xe') || lower.contains('đón')) return Icons.directions_car;
    if (lower.contains('nhạc') || lower.contains('âm thanh')) return Icons.music_note;
    if (lower.contains('hoa') || lower.contains('trang trí')) return Icons.local_florist;
    if (lower.contains('mc') || lower.contains('dẫn')) return Icons.mic;
    return Icons.star_border;
  }

  Color _getServiceColor(String? type) {
    if (type == null) return Colors.grey;
    final lower = type.toLowerCase();
    if (lower.contains('chụp') || lower.contains('ảnh')) return Colors.blue;
    if (lower.contains('makeup') || lower.contains('trang điểm')) return Colors.pink;
    if (lower.contains('xe') || lower.contains('đón')) return Colors.green;
    if (lower.contains('nhạc') || lower.contains('âm thanh')) return Colors.orange;
    if (lower.contains('hoa') || lower.contains('trang trí')) return Colors.purple;
    return Colors.indigo;
  }

  Future<void> _showContractDialog({EventVendor? contract}) async {
    final isEditing = contract != null;
    Vendor? selectedVendor = contract?.vendor;

    if (!isEditing) {
      final vendor = await Navigator.push<Vendor>(
        context,
        MaterialPageRoute(builder: (context) => const VendorListScreen(isSelecting: true)),
      );

      if (vendor == null) return; 
      selectedVendor = vendor; 
    }

    if (!mounted) return;

    bool isAdminOrStaff = _userRole == 'Admin' || _userRole == 'Staff';

    final serviceController = TextEditingController(text: contract?.serviceDescription);
    final amountController = TextEditingController(text: contract?.contractAmount?.toString() ?? '');
    final depositController = TextEditingController(text: contract?.depositAmount?.toString() ?? '');
    String status = contract?.status ?? 'Pending';

    bool syncToBudget = false;
    int? selectedBudgetId;
    
    // Auto-select budget heuristic
    if (!isEditing && selectedVendor != null && _budgets.isNotEmpty) {
       try {
         final matchingBudget = _budgets.firstWhere((b) => b.category.contains(selectedVendor!.vendorType) || selectedVendor.vendorType.contains(b.category));
         selectedBudgetId = matchingBudget.id;
       } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Cập nhật Dịch vụ' : 'Thêm Dịch vụ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Service / Vendor Info
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: _getServiceColor(selectedVendor?.vendorType).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: _getServiceColor(selectedVendor?.vendorType).withOpacity(0.3)),
                     ),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             shape: BoxShape.circle,
                             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                           ),
                           child: Icon(_getServiceIcon(selectedVendor?.vendorType), color: _getServiceColor(selectedVendor?.vendorType), size: 24),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(selectedVendor?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                               Text(selectedVendor?.vendorType ?? 'Dịch vụ', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: serviceController,
                    decoration: const InputDecoration(labelText: 'Ghi chú dịch vụ', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(labelText: 'Tổng giá trị', border: OutlineInputBorder(), suffixText: 'đ'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: depositController,
                          decoration: const InputDecoration(labelText: 'Đã cọc', border: OutlineInputBorder(), suffixText: 'đ'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (isAdminOrStaff)
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                      items: ['Pending', 'Confirmed', 'Completed', 'Cancelled']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => status = val!),
                    ),

                  // Budget Sync
                  if (_budgets.isNotEmpty) ...[ 
                    const SizedBox(height: 16),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Tạo khoản chi tương ứng?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Đồng bộ vào Ngân sách", style: TextStyle(fontSize: 12)),
                      value: syncToBudget,
                      onChanged: (val) => setStateDialog(() => syncToBudget = val),
                      activeColor: Colors.indigo,
                    ),
                    if (syncToBudget)
                      DropdownButtonFormField<int>(
                        value: selectedBudgetId,
                        decoration: const InputDecoration(labelText: 'Chọn Hạng mục Ngân sách', border: OutlineInputBorder()),
                        items: _budgets.map((b) => DropdownMenuItem(value: b.id, child: Text(b.category))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedBudgetId = val),
                        validator: (val) => syncToBudget && val == null ? 'Vui lòng chọn hạng mục' : null,
                      ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final newContract = EventVendor(
                      id: contract?.id ?? 0,
                      eventId: widget.event.id!,
                      vendorId: selectedVendor!.id,
                      serviceDescription: serviceController.text,
                      contractAmount: double.tryParse(amountController.text),
                      depositAmount: double.tryParse(depositController.text),
                      status: status,
                    ); 
                    
                    if (isEditing) {
                      await _apiService.updateEventVendor(newContract);
                       // Update Sync Logic (Simplified for brevity, similar to before)
                      if (syncToBudget && selectedBudgetId != null && newContract.contractAmount != null) {
                         final expense = Expense(id: 0, eventId: widget.event.id!, budgetId: selectedBudgetId, vendorId: newContract.vendorId, description: 'Dịch vụ: ${selectedVendor!.name} (Update)', amount: newContract.contractAmount!, expenseDate: DateTime.now(), paymentMethod: 'Chuyển khoản', notes: 'Auto-Service Update [ContractID:${newContract.id}]');
                         await _budgetService.createExpense(expense);
                      }
                    } else {
                      final created = await _apiService.createEventVendor(newContract);
                      if (syncToBudget && selectedBudgetId != null && created.contractAmount != null) {
                         final expense = Expense(id: 0, eventId: widget.event.id!, budgetId: selectedBudgetId, vendorId: created.vendorId, description: 'Dịch vụ: ${selectedVendor!.name}', amount: created.contractAmount!, expenseDate: DateTime.now(), paymentMethod: 'Chuyển khoản', notes: 'Auto-Service [ContractID:${created.id}]');
                         await _budgetService.createExpense(expense);
                      }
                    }
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadContracts();
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteContract(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Dịch vụ'),
        content: const Text('Bạn có chắc chắn muốn xóa dịch vụ này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteEventVendor(id);
        _loadContracts();
      } catch (e) {
        // Ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Dịch vụ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.indigo, Colors.indigo[50]!])),
        child: Column(
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                   Expanded(
                     child: _buildStatCard('Tổng Dịch vụ', '${_contracts.length}', Icons.layers, Colors.white.withOpacity(0.2)),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildStatCard('Đã cọc', NumberFormat('#,###').format(_contracts.fold(0.0, (sum, c) => sum + (c.depositAmount ?? 0))), Icons.check_circle_outline, Colors.green.withOpacity(0.8)),
                   ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _contracts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _contracts.length,
                            itemBuilder: (context, index) => _buildServiceCard(_contracts[index]),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContractDialog(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm Dịch vụ', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.room_service_outlined, size: 80, color: Colors.indigo[100]),
          const SizedBox(height: 16),
          Text('Chưa có dịch vụ nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 8),
          Text('Thêm các dịch vụ như Chụp ảnh, Makeup...', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(EventVendor contract) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final vendorName = contract.vendor?.name ?? 'Unknown';
    final type = contract.vendor?.vendorType;
    final color = _getServiceColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showContractDialog(contract: contract),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getServiceIcon(type), color: color, size: 28),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1)),
                          _buildStatusBadge(contract.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(contract.serviceDescription ?? 'Không có ghi chú', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2),
                      const SizedBox(height: 12),
                      // Money
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tổng giá trị', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Text('${currency.format(contract.contractAmount ?? 0)} đ', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đã cọc', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                Text('${currency.format(contract.depositAmount ?? 0)} đ', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch(status) {
      case 'Confirmed': color = Colors.green; break;
      case 'Completed': color = Colors.blue; break;
      case 'Cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
