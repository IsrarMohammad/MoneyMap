import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/database_service.dart';

/// ExpenseViewModel: Handles fetching, adding, editing, and deleting expenses.
/// Notifies listeners (your UI) on every change.
class ExpenseViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Internal list of expenses, updated on each fetch.
  List<Expense> _expenses = [];
  bool _isLoading = false;

  // Expose immutable data to UI
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;

  /// Fetch all expenses, optionally filter by date range or category.
  Future<void> fetchExpenses({
    DateTime? from,
    DateTime? to,
    int? categoryId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // You can extend DatabaseService to allow filters.
      final db = await _dbService.database;
      String where = '';
      List<Object?> params = [];

      if (from != null && to != null) {
        where = 'date BETWEEN ? AND ?';
        params.addAll([from.toIso8601String(), to.toIso8601String()]);
      }
      if (categoryId != null) {
        if (where.isNotEmpty) where += ' AND ';
        where += 'categoryId = ?';
        params.add(categoryId);
      }

      final result = await db.query(
        'expenses',
        where: where.isNotEmpty ? where : null,
        whereArgs: params.isNotEmpty ? params : null,
        orderBy: 'date DESC',
      );
      _expenses = result.map((e) => Expense.fromMap(e)).toList();
    } catch (e) {
      // handle or log error
      _expenses = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new expense, refresh list & notify.
  Future<void> addExpense(Expense expense) async {
    await _dbService.insertExpense(expense);
    await fetchExpenses();
    // Potential place to check budget and trigger notifications
  }

  /// Edit/update an existing expense (using id), refresh list & notify.
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    final db = await _dbService.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await fetchExpenses();
  }

  /// Delete an expense by id, refresh list & notify.
  Future<void> deleteExpense(int id) async {
    final db = await _dbService.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await fetchExpenses();
  }

  /// Get total expenses for analytics/dashboard.
  double get totalExpenses {
    return _expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// (Optional) Group expenses by category for pie charts, etc.
  Map<int, double> expensesByCategory() {
    final map = <int, double>{};
    for (var e in _expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0.0) + e.amount;
    }
    return map;
  }

  /// (Optional) Get expenses for a specific period (week/month) as needed by UI.
  List<Expense> expensesForPeriod(DateTime from, DateTime to) {
    return _expenses
        .where((e) => e.date.isAfter(from) && e.date.isBefore(to))
        .toList();
  }
}
