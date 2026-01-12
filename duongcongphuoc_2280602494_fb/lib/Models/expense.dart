class Expense {
  final int id;
  final int eventId;
  final int? budgetId;
  final int? vendorId;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String? paymentMethod;
  final String? notes;

  Expense({
    required this.id,
    required this.eventId,
    this.budgetId,
    this.vendorId,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.paymentMethod,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      eventId: json['eventId'],
      budgetId: json['budgetId'],
      vendorId: json['vendorId'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expenseDate']),
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'budgetId': budgetId,
      'vendorId': vendorId,
      'description': description,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}
