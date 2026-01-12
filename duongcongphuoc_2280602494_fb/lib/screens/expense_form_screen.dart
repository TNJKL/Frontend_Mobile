
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/expense.dart';
import '../Models/budget.dart';
import '../services/budget_api_service.dart';

class ExpenseFormScreen extends StatefulWidget {
  final int eventId;
  final int? budgetId;
  final Expense? expense;
  final String? initialDescription;

  const ExpenseFormScreen({super.key, required this.eventId, this.budgetId, this.expense, this.initialDescription});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;
  final BudgetApiService _apiService = BudgetApiService();
  List<Budget> _budgets = [];
  int? _selectedBudgetId;

  @override
  void initState() {
    super.initState();
    _selectedBudgetId = widget.budgetId ?? widget.expense?.budgetId;
    _loadBudgets();

    if (widget.expense != null) {
      _descriptionController.text = widget.expense!.description;
      _amountController.text = widget.expense!.amount.toInt().toString();
      _paymentMethodController.text = widget.expense!.paymentMethod ?? '';
      _notesController.text = widget.expense!.notes ?? '';
      _expenseDate = widget.expense!.expenseDate;
    } else if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await _apiService.getBudgetsByEventId(widget.eventId);
      setState(() {
        _budgets = budgets;
        // If only one budget exists and none selected, select it by default
        if (_budgets.length == 1 && _selectedBudgetId == null) {
          _selectedBudgetId = _budgets.first.id;
        }
      });
    } catch (e) {
      print('Error loading budgets: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expense = Expense(
        id: widget.expense?.id ?? 0,
        eventId: widget.eventId,
        budgetId: _selectedBudgetId, // Use the selected budget ID
        vendorId: widget.expense?.vendorId, // Vendor selection can be added later
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        expenseDate: _expenseDate,
        paymentMethod: _paymentMethodController.text,
        notes: _notesController.text,
      );

      if (widget.expense == null) {
        await _apiService.createExpense(expense);
      } else {
        await _apiService.updateExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.expense == null ? 'Thêm khoản chi thành công' : 'Cập nhật thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteExpense() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa khoản chi này?'),
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

     if (confirm == true && widget.expense != null) {
       setState(() => _isLoading = true);
       try {
         await _apiService.deleteExpense(widget.expense!.id);
         if (mounted) {
            Navigator.pop(context, true); // Return true to reload
         }
       } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
            setState(() => _isLoading = false);
         }
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Thêm khoản chi' : 'Chi tiết khoản chi'),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        actions: [
          if (widget.expense != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteExpense,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung chi (ví dụ: Đặt cọc nhà hàng)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 16),
              
              // Budget Category Selector
              DropdownButtonFormField<int>(
                value: _selectedBudgetId,
                decoration: const InputDecoration(
                  labelText: 'Hạng mục ngân sách',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _budgets.map((budget) {
                  return DropdownMenuItem<int>(
                    value: budget.id,
                    child: Text(budget.category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBudgetId = value;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn hạng mục' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số tiền' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày chi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_expenseDate)),
                ),
              ),
              const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                value: ['Tiền mặt', 'Chuyển khoản', 'Thẻ tín dụng'].contains(_paymentMethodController.text) 
                    ? _paymentMethodController.text 
                    : null, // If value is 'Transfer' or other, show nothing selected instead of crash
                decoration: const InputDecoration(
                  labelText: 'Phương thức thanh toán',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                  DropdownMenuItem(value: 'Chuyển khoản', child: Text('Chuyển khoản')),
                  DropdownMenuItem(value: 'Thẻ tín dụng', child: Text('Thẻ tín dụng')),
                ],
                onChanged: (value) {
                  _paymentMethodController.text = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.expense == null ? 'Lưu khoản chi' : 'Cập nhật'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
