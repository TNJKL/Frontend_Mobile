import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';

class AdminTransactionHistoryScreen extends StatefulWidget {
  const AdminTransactionHistoryScreen({super.key});

  @override
  State<AdminTransactionHistoryScreen> createState() => _AdminTransactionHistoryScreenState();
}

class _AdminTransactionHistoryScreenState extends State<AdminTransactionHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  double _totalRevenue = 0;
  int _successCount = 0;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _paymentService.getHistory();
    
    double revenue = 0;
    int success = 0;
    int fail = 0;

    for (var txn in history) {
      if (txn['status'] == 'Success') {
        revenue += (txn['amount'] ?? 0);
        success++;
      } else if (txn['status'] == 'Failed') {
        fail++;
      }
    }

    setState(() {
      _transactions = history;
      _totalRevenue = revenue;
      _successCount = success;
      _failCount = fail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Quản lý Doanh thu & Giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
         backgroundColor: const Color(0xFFE91E63), // Pink 500 equivalent standard for Admin
         elevation: 0,
         iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REVENUE SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tổng Doanh Thu', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${currencyFormat.format(_totalRevenue)} VNĐ',
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.attach_money, color: Colors.white, size: 32),
                              )
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildMiniStat('Thành công', '$_successCount', Icons.check_circle, Colors.greenAccent),
                              const SizedBox(width: 24),
                              _buildMiniStat('Thất bại', '$_failCount', Icons.cancel, Colors.white70),
                              const SizedBox(width: 24),
                              _buildMiniStat('Tổng GD', '${_transactions.length}', Icons.list_alt, Colors.white),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Lịch sử giao dịch chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    const SizedBox(height: 12),

                    // LIST OF TRANSACTIONS
                    _transactions.isEmpty 
                      ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("Không có dữ liệu")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final txn = _transactions[index];
                            return _buildTransactionCard(txn, currencyFormat);
                          },
                        ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        )
      ],
    );
  }

  Widget _buildTransactionCard(dynamic txn, NumberFormat currencyFormat) {
    final amount = txn['amount'] ?? 0;
    final status = txn['status'] ?? 'Unknown';
    final dateStr = txn['createdDate'];
    final txnRef = txn['txnRef'] ?? 'No Ref';
    final customerName = txn['customerName'] ?? 'Khách vãng lai';
    final description = txn['orderDescription'] ?? 'Thanh toán dịch vụ';

    DateTime? date;
    if (dateStr != null) date = DateTime.tryParse(dateStr);

    Color statusColor = status == 'Success' ? Colors.green : (status == 'Failed' ? Colors.red : Colors.orange);
    String statusText = status == 'Success' ? 'Thành công' : (status == 'Failed' ? 'Thất bại' : 'Đang chờ');

    return GestureDetector(
      onTap: () => _showTransactionDetail(txn),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == 'Success' ? Icons.check : (status == 'Pending' ? Icons.hourglass_empty : Icons.close),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date != null ? DateFormat('dd/MM HH:mm').format(date) : ''} • #$txnRef',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${status == 'Success' ? '+' : ''}${currencyFormat.format(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: status == 'Success' ? Colors.green : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(dynamic txn) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    final amount = txn['amount'] ?? 0;
    final status = txn['status'] ?? 'Unknown';
    final txnRef = txn['txnRef'] ?? 'Unknown';
    final customerName = txn['customerName'] ?? 'N/A';
    final description = txn['orderDescription'] ?? 'N/A';
    final dateStr = txn['createdDate'];
    DateTime? date;
    if (dateStr != null) date = DateTime.tryParse(dateStr);

    Color statusColor = status == 'Success' ? Colors.green : (status == 'Failed' ? Colors.red : Colors.orange);
    String statusText = status == 'Success' ? 'Thành công' : (status == 'Failed' ? 'Thất bại' : 'Đang chờ');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                      status == 'Success' ? Icons.check_circle : Icons.error, 
                      color: statusColor, size: 28
                   ),
                   const SizedBox(width: 8),
                   Text(statusText, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              _buildDetailRow('Số tiền', '${currencyFormat.format(amount)} VNĐ', isBold: true),
              _buildDetailRow('Khách hàng', customerName),
              _buildDetailRow('Nội dung', description),
              _buildDetailRow('Mã GD', txnRef),
              _buildDetailRow('Thời gian', date != null ? dateFormat.format(date) : 'N/A'),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500, 
                fontSize: 15,
                color: Colors.black87
              ), 
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
