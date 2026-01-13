import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/budget.dart';
import '../Models/event.dart';
import '../services/budget_api_service.dart';
import 'budget_form_screen.dart';
import 'expense_form_screen.dart';
import '../services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BudgetScreen extends StatefulWidget {
  final Event event;

  const BudgetScreen({super.key, required this.event});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetApiService _budgetService = BudgetApiService();
  List<Budget> _budgets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _budgetService.getBudgetsByEventId(widget.event.id!);
      setState(() {
        _budgets = budgets;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ngân sách: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBudget(int budgetId) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hạng mục này? Tất cả chi tiêu trong hạng mục này cũng sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _budgetService.deleteBudget(budgetId);
        _loadBudgets();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa hạng mục')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa: $e')),
          );
        }
      }
    }
  }

  Future<void> _handlePayment(double amount) async {
    setState(() => _isLoading = true);
    try {
      final paymentService = PaymentService();
      
      // Determine Customer Name
      String customerName = 'Khách hàng';
      if (widget.event.brideName != null && widget.event.brideName!.isNotEmpty) {
        customerName = widget.event.brideName!;
        if (widget.event.groomName != null && widget.event.groomName!.isNotEmpty) {
          customerName += ' & ${widget.event.groomName}';
        }
      } else if (widget.event.groomName != null && widget.event.groomName!.isNotEmpty) {
        customerName = widget.event.groomName!;
      } else if (widget.event.creatorName != null) {
        customerName = widget.event.creatorName!;
      }

      final result = await paymentService.createPaymentUrl(
        amount, 
        customerName: customerName,
        orderDescription: 'Thanh toán ngân sách sự kiện: ${widget.event.title ?? "Không tên"}'
      );
      
      setState(() => _isLoading = false);

      if (result != null && result['url'] != null) {
        final url = result['url'];
        final txnRef = result['txnRef'];
        final uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (txnRef != null) {
            _waitForPaymentResult(txnRef);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở liên kết thanh toán')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tạo liên kết thanh toán')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _waitForPaymentResult(String txnRef) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Đang đợi xác nhận thanh toán...'),
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Đóng (Xử lý sau)'),
            )
          ],
        ),
      ),
    );

    final paymentService = PaymentService();
    // Poll for 2 minutes (approx 40 attempts)
    for (int i = 0; i < 40; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;
      
      final status = await paymentService.checkPaymentStatus(txnRef);
      if (status == 'Success') {
        if (mounted) {
           Navigator.pop(context); // Close loading dialog
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Thanh toán thành công!'), 
               backgroundColor: Colors.green,
               behavior: SnackBarBehavior.floating,
             )
           );
           _loadBudgets(); // Refresh data/UI
        }
        return;
      } else if (status == 'Failed') {
         if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Thanh toán thất bại'), backgroundColor: Colors.red)
           );
         }
         return;
      }
    }
    
    // Timeout
    if (mounted && Navigator.canPop(context)) {
       Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBudget = 0;
    double totalActual = 0;

    for (var b in _budgets) {
      totalBudget += b.budgetedAmount;
      totalActual += b.actualAmount;
    }

    double balance = totalBudget - totalActual;
    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý ngân sách', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink[400],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudgets,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Summary Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[400]!, Colors.orange[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Tổng ngân sách',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${currencyFormat.format(totalBudget)} VNĐ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Đã chi', style: TextStyle(color: Colors.white70)),
                                    Text(
                                      '${currencyFormat.format(totalActual)} VNĐ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(width: 1, height: 40, color: Colors.white30),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Còn lại', style: TextStyle(color: Colors.white70)),
                                    Text(
                                      '${currencyFormat.format(balance)} VNĐ',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Payment Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text('Thanh toán VNPay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                           if (totalActual <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có khoản chi nào để thanh toán')));
                              return;
                           }
                           _handlePayment(totalActual);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // List Categories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hạng mục chi tiêu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.pink),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BudgetFormScreen(eventId: widget.event.id!),
                              ),
                            );
                            if (result == true) _loadBudgets();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_budgets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Chưa có hạng mục nào. Hãy thêm mới!'),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _budgets.length,
                        itemBuilder: (context, index) {
                          final budget = _budgets[index];
                          double percent = budget.budgetedAmount > 0 
                              ? (budget.actualAmount / budget.budgetedAmount) 
                              : 0;
                          if (percent > 1) percent = 1;
                          
                          Color progressColor = Colors.green;
                          if (percent > 0.8) progressColor = Colors.orange;
                          if (budget.actualAmount > budget.budgetedAmount) progressColor = Colors.red;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              title: Text(
                                budget.category,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: Colors.grey[200],
                                    color: progressColor,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${currencyFormat.format(budget.actualAmount)} đ', style: TextStyle(color: progressColor)),
                                      Text('/ ${currencyFormat.format(budget.budgetedAmount)} đ'),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                // List Expenses inside
                                if (budget.expenses.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('Chưa có khoản chi nào trong mục này.', style: TextStyle(color: Colors.grey)),
                                  )
                                else
                                  ...budget.expenses.map((expense) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.money_off, size: 20, color: Colors.red),
                                    title: Text(expense.description),
                                    trailing: Text(
                                      '-${currencyFormat.format(expense.amount)}',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    onTap: () async {
                                       final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExpenseFormScreen(eventId: widget.event.id!, expense: expense),
                                        ),
                                      );
                                      if (result == true) _loadBudgets();
                                    },
                                  )),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Sửa Hạng Mục'),
                                        onPressed: () async {
                                           final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BudgetFormScreen(eventId: widget.event.id!, budget: budget),
                                            ),
                                          );
                                          if (result == true) _loadBudgets();
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                        onPressed: () => _deleteBudget(budget.id),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Thêm Khoản Chi'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pink[50],
                                          foregroundColor: Colors.pink,
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ExpenseFormScreen(eventId: widget.event.id!, budgetId: budget.id),
                                            ),
                                          );
                                          if (result == true) _loadBudgets();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
