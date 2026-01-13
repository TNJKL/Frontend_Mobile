import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await _paymentService.getHistory();
    setState(() {
      _transactions = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    final amount = txn['amount'] ?? 0;
                    final status = txn['status'] ?? 'Unknown';
                    final dateStr = txn['createdDate'];
                    DateTime? date;
                    if (dateStr != null) {
                       date = DateTime.tryParse(dateStr);
                    }

                    Color statusColor = Colors.grey;
                    String statusText = status;
                    IconData statusIcon = Icons.help_outline;

                    if (status == 'Success') {
                      statusColor = Colors.green;
                      statusText = 'Thành công';
                      statusIcon = Icons.check_circle;
                    } else if (status == 'Failed') {
                      statusColor = Colors.red;
                      statusText = 'Thất bại';
                      statusIcon = Icons.error;
                    } else if (status == 'Pending') {
                      statusColor = Colors.orange;
                      statusText = 'Đang chờ';
                      statusIcon = Icons.hourglass_empty;
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        title: Text(
                          '${currencyFormat.format(amount)} VNĐ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(date != null ? dateFormat.format(date) : 'Unknown Date', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => _showTransactionDetail(txn),
                      ),
                    );
                  },
                ),
    );
  }

  void _showTransactionDetail(dynamic txn) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    final amount = txn['amount'] ?? 0;
    final status = txn['status'] ?? 'Unknown';
    final txnRef = txn['txnRef'] ?? 'Unknown';
    final orderInfo = txn['orderInfo'] ?? '';
    final dateStr = txn['createdDate'];
    DateTime? date;
    if (dateStr != null) {
        date = DateTime.tryParse(dateStr);
    }

    Color statusColor = Colors.grey;
    String statusText = status;
    IconData statusIcon = Icons.help_outline;

    if (status == 'Success') {
      statusColor = Colors.green;
      statusText = 'Thành công';
      statusIcon = Icons.check_circle;
    } else if (status == 'Failed') {
      statusColor = Colors.red;
      statusText = 'Thất bại';
      statusIcon = Icons.error;
    } else if (status == 'Pending') {
      statusColor = Colors.orange;
      statusText = 'Đang chờ';
      statusIcon = Icons.hourglass_empty;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, size: 48, color: statusColor),
              ),
              const SizedBox(height: 16),
              Text(
                '${currencyFormat.format(amount)} VNĐ',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 16, color: statusColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Mã giao dịch', txnRef),
              _buildDetailRow('Thời gian', date != null ? dateFormat.format(date) : 'Unknown'),
              _buildDetailRow('Nội dung', orderInfo),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
            child: Text(
              value, 
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), 
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
