
import 'expense.dart';

class Budget {
  final int id;
  final int eventId;
  final String category;
  final double budgetedAmount;
  final double actualAmount;
  final String? notes;
  final DateTime createdAt;
  final List<Expense> expenses;

  Budget({
    required this.id,
    required this.eventId,
    required this.category,
    required this.budgetedAmount,
    this.actualAmount = 0,
    this.notes,
    required this.createdAt,
    this.expenses = const [],
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    var expensesList = <Expense>[];
    if (json['expenses'] != null) {
      expensesList = (json['expenses'] as List)
          .map((e) => Expense.fromJson(e))
          .toList();
    }

    return Budget(
      id: json['id'],
      eventId: json['eventId'],
      category: json['category'],
      budgetedAmount: (json['budgetedAmount'] as num).toDouble(),
      actualAmount: (json['actualAmount'] as num).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      expenses: expensesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'category': category,
      'budgetedAmount': budgetedAmount,
      'actualAmount': actualAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
