import 'dart:convert';
import '../Models/budget.dart';
import '../Models/expense.dart';
import 'api_client.dart';

class BudgetApiService {
  final ApiClient _client = ApiClient();

  // Budgets
  Future<List<Budget>> getBudgetsByEventId(int eventId) async {
    final response = await _client.get('/BudgetApi/event/$eventId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Budget.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load budgets: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> createBudget(Budget budget) async {
    final body = budget.toJson()..remove('id');
    final response = await _client.post('/BudgetApi', body: body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create budget: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateBudget(Budget budget) async {
    final response = await _client.put('/BudgetApi/${budget.id}', body: budget.toJson());

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to update budget');
    }
  }



  Future<void> deleteBudget(int id) async {
    final response = await _client.delete('/BudgetApi/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete budget');
    }
  }

  // Expenses
  Future<List<Expense>> getExpensesByEventId(int eventId) async {
    final response = await _client.get('/ExpenseApi/event/$eventId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Expense.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  Future<void> createExpense(Expense expense) async {
    final body = expense.toJson()..remove('id');
    final response = await _client.post('/ExpenseApi', body: body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create expense');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final response = await _client.put('/ExpenseApi/${expense.id}', body: expense.toJson());

    if (response.statusCode != 204) {
      throw Exception('Failed to update expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    final response = await _client.delete('/ExpenseApi/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense');
    }
  }
}
