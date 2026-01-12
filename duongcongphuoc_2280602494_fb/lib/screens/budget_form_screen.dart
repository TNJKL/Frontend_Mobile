import 'package:flutter/material.dart';
import '../Models/budget.dart';
import '../services/budget_api_service.dart';

class BudgetFormScreen extends StatefulWidget {
  final int eventId;
  final Budget? budget;

  const BudgetFormScreen({super.key, required this.eventId, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  final BudgetApiService _apiService = BudgetApiService();

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _categoryController.text = widget.budget!.category;
      _amountController.text = widget.budget!.budgetedAmount.toInt().toString();
      _notesController.text = widget.budget!.notes ?? '';
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final budget = Budget(
        id: widget.budget?.id ?? 0,
        eventId: widget.eventId,
        category: _categoryController.text,
        budgetedAmount: double.parse(_amountController.text),
        actualAmount: widget.budget?.actualAmount ?? 0,
        notes: _notesController.text,
        createdAt: widget.budget?.createdAt ?? DateTime.now(),
      );

      if (widget.budget == null) {
        await _apiService.createBudget(budget);
      } else {
        await _apiService.updateBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.budget == null ? 'Thêm mới thành công' : 'Cập nhật thành công')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Thêm ngân sách' : 'Cập nhật ngân sách'),
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Tên hạng mục (ví dụ: Nhà hàng, Hoa...)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên hạng mục' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dự trù kinh phí (VNĐ)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập số tiền' : null,
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
                  onPressed: _isLoading ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.budget == null ? 'Tạo mới' : 'Cập nhật'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
