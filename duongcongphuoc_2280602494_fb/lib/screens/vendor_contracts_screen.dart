import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event_vendor.dart';
import '../Models/vendor.dart';
import '../services/vendor_api_service.dart';

class VendorContractsScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorContractsScreen({super.key, required this.vendor});

  @override
  State<VendorContractsScreen> createState() => _VendorContractsScreenState();
}

class _VendorContractsScreenState extends State<VendorContractsScreen> {
  final VendorApiService _apiService = VendorApiService();
  List<EventVendor> _contracts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await _apiService.getContractsByVendorId(widget.vendor.id);
      setState(() => _contracts = contracts);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(EventVendor contract, String newStatus) async {
    try {
      final updatedContract = EventVendor(
        id: contract.id,
        eventId: contract.eventId,
        vendorId: contract.vendorId,
        vendor: contract.vendor,
        serviceDescription: contract.serviceDescription,
        contractAmount: contract.contractAmount,
        depositAmount: contract.depositAmount,
        balanceAmount: contract.balanceAmount,
        contractDate: contract.contractDate,
        serviceDate: contract.serviceDate,
        status: newStatus,
        notes: contract.notes,
      );
      
      await _apiService.updateEventVendor(updatedContract);
      _loadContracts(); // Refresh
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: Text('Hợp đồng của ${widget.vendor.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
              ? const Center(child: Text('Chưa có hợp đồng nào.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contracts.length,
                  itemBuilder: (context, index) {
                    final contract = _contracts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sự kiện ID: ${contract.eventId}', // Would be better with Event Name if populated
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: contract.status,
                                  onChanged: (val) {
                                    if (val != null) _updateStatus(contract, val);
                                  },
                                  items: ['Pending', 'Confirmed', 'Completed', 'Cancelled']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(
                                        color: s == 'Confirmed' || s == 'Completed' ? Colors.green 
                                             : s == 'Cancelled' ? Colors.red : Colors.orange
                                      ))))
                                      .toList(),
                                  underline: Container(), // Remove underline
                                  icon: const Icon(Icons.arrow_drop_down),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Dịch vụ: ${contract.serviceDescription ?? "N/A"}'),
                            const SizedBox(height: 8),
                            Row(
                                children: [
                                    Expanded(child: Text('Giá trị: ${currencyFormat.format(contract.contractAmount ?? 0)} đ')),
                                    Expanded(child: Text('Đã cọc: ${currencyFormat.format(contract.depositAmount ?? 0)} đ', style: const TextStyle(color: Colors.green))),
                                ],
                            ),
                            const SizedBox(height: 4),
                             Text('Còn lại: ${currencyFormat.format(contract.balanceAmount ?? 0)} đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
