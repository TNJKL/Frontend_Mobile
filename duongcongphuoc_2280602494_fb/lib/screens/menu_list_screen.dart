import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/event.dart';
import '../Models/budget.dart';
import '../Models/expense.dart';
import '../Models/global_menu_item.dart';
import '../services/menu_api_service.dart';
import '../services/budget_api_service.dart';
import '../utils/user_helper.dart';

class MenuListScreen extends StatefulWidget {
  final Event event;
  const MenuListScreen({super.key, required this.event});
  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  bool _loading = false;
  List<GlobalMenuItem> _globalItems = [];
  Set<int> _selectedItemIds = {};
  int _tableCount = 0;
  
  final BudgetApiService _budgetService = BudgetApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _tableCount = prefs.getInt('table_count_${widget.event.id}') ?? 0;
      
      // Load selected items from prefs
      final savedIds = prefs.getStringList('menu_selection_${widget.event.id}') ?? [];
      _selectedItemIds = savedIds.map((e) => int.parse(e)).toSet();

      // Load items (Admin/Staff/Global distinction removed for simplicity as per request to just 'fix it')
      // Assuming we are using Global Menu Items for standard selection
      final global = await MenuApiService.getGlobalItems();
      
      setState(() {
        _globalItems = global;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleItem(int id) async {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
    
    // Save to Prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('menu_selection_${widget.event.id}', _selectedItemIds.map((e) => e.toString()).toList());
  }

  double _calculateTablePrice() {
    double total = 0;
    for (var item in _globalItems) {
      if (_selectedItemIds.contains(item.id)) {
        total += item.unitPrice ?? 0;
      }
    }
    return total;
  }

  Future<void> _syncToBudget() async {
    final tablePrice = _calculateTablePrice();
    final totalCost = tablePrice * _tableCount;

    if (totalCost == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn món trước!')));
      return;
    }
    if (_tableCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có số lượng bàn! Vui lòng sang Sơ đồ bàn để xếp bàn.')));
      return;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đồng bộ Ngân sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giá 1 mâm: ${NumberFormat('#,###').format(tablePrice)} đ'),
            Text('Số bàn: $_tableCount'),
            const Divider(),
            Text('Tổng cộng: ${NumberFormat('#,###').format(totalCost)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            const SizedBox(height: 10),
            const Text('Hệ thống sẽ tạo/cập nhật mục "Tiệc Cưới" trong Ngân sách với số tiền này.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          )
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        // 1. Check if Budget "Tiệc Cưới" exists
        final budgets = await _budgetService.getBudgetsByEventId(widget.event.id!);
        Budget? weddingBudget;
        try {
           weddingBudget = budgets.firstWhere((b) => b.category == 'Tiệc Cưới');
        } catch (_) {}

        // 2. Create or Update Budget Limit
        if (weddingBudget != null) {
          // Update existing budget limit
          final updatedBudget = Budget(
             id: weddingBudget.id,
             eventId: weddingBudget.eventId,
             category: weddingBudget.category,
             budgetedAmount: totalCost,
             actualAmount: weddingBudget.actualAmount, 
             notes: weddingBudget.notes,
             createdAt: weddingBudget.createdAt
          );
          await _budgetService.updateBudget(updatedBudget);
          // Refetch to ensure we have latest state if needed, but we mainly need ID
        } else {
          // Create new budget
          final newBudget = Budget(
            id: 0,
            eventId: widget.event.id!,
            category: 'Tiệc Cưới',
            budgetedAmount: totalCost,
            actualAmount: 0,
            notes: 'Tự động tính từ Thực đơn ($_tableCount bàn)',
            createdAt: DateTime.now()
          );
          await _budgetService.createBudget(newBudget);
          
          // Fetch back to get the ID
          final freshBudgets = await _budgetService.getBudgetsByEventId(widget.event.id!);
          weddingBudget = freshBudgets.firstWhere((b) => b.category == 'Tiệc Cưới');
        }

        // 3. Auto-Create/Update "Feast Cost" Expense
        // Goal: Ensure the "Actual" amount also reflects this cost
        if (weddingBudget != null) {
           final expenses = await _budgetService.getExpensesByEventId(widget.event.id!);
           
           // Look for the auto-generated expense
           Expense? feastExpense;
           try {
             feastExpense = expenses.firstWhere((e) => e.budgetId == weddingBudget!.id && e.notes?.contains('[Auto-Menu]') == true);
           } catch (_) {}

           if (feastExpense != null) {
             // Update existing expense
             final updatedExpense = Expense(
               id: feastExpense.id,
               eventId: feastExpense.eventId,
               budgetId: feastExpense.budgetId,
               vendorId: feastExpense.vendorId,
               description: 'Chi phí đặt cỗ (Tự động)',
               amount: totalCost, // Sync amount
               expenseDate: feastExpense.expenseDate,
               paymentMethod: feastExpense.paymentMethod,
               notes: feastExpense.notes,
             );
             await _budgetService.updateExpense(updatedExpense);
           } else {
             // Create new expense
             final newExpense = Expense(
               id: 0,
               eventId: widget.event.id!,
               budgetId: weddingBudget.id,
               description: 'Chi phí đặt cỗ (Tự động)',
               amount: totalCost,
               expenseDate: DateTime.now(),
               paymentMethod: 'Chưa thanh toán',
               notes: 'Tự động tạo từ Thực đơn ($_tableCount bàn) [Auto-Menu]',
             );
             await _budgetService.createExpense(newExpense);
           }
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật Ngân sách & Chi phí thành công!')));

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đồng bộ: $e')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'vi_VN');
    final tablePrice = _calculateTablePrice();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thực Đơn Cỗ Cưới'),
        backgroundColor: Colors.pink[100],
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              '$_tableCount bàn',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.pink[50],
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.pink),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Chọn các món cho 1 mâm cỗ. Giá trị sẽ được nhân với $_tableCount bàn.', style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _globalItems.length,
                    itemBuilder: (context, index) {
                      final item = _globalItems[index];
                      final isSelected = _selectedItemIds.contains(item.id);
                      
                      return GestureDetector(
                        onTap: () => _toggleItem(item.id!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.transparent,
                              width: 3
                            ),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.restaurant, size: 40, color: Colors.grey))
                                      : const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${currencyFormat.format(item.unitPrice)} đ', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  color: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Giá 1 mâm:', style: TextStyle(color: Colors.grey)),
                          Text('${currencyFormat.format(tablePrice)} đ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng (dự kiến):', style: TextStyle(fontSize: 16)),
                          Text('${currencyFormat.format(tablePrice * _tableCount)} đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                          icon: const Icon(Icons.savings, color: Colors.white),
                          label: const Text('Lưu vào Ngân sách', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: _syncToBudget,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
