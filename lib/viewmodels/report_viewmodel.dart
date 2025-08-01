import 'package:flutter/material.dart';
import 'package:moneymap/models/expense.dart';
import 'package:moneymap/models/income.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/services/database_service.dart';

/// ReportViewModel: Calculates summaries, trends, and category-wise analytics for reporting.
class ReportViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Category> _categories = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Public getter: returns a copy to the UI.
  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<Income> get incomes => List.unmodifiable(_incomes);
  List<Category> get categories => List.unmodifiable(_categories);


  /// Call this to refresh all data for reporting.
  Future<void> fetchReportData({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    final db = await _dbService.database;

    // Fetch categories
    final catResult = await db.query('categories');
    _categories = catResult.map((e) => Category.fromMap(e)).toList();

    // Fetch expenses (optionally filter by date)
    String? whereExpenses;
    List<Object?>? expenseArgs;
    if (from != null && to != null) {
      whereExpenses = 'date BETWEEN ? AND ?';
      expenseArgs = [from.toIso8601String(), to.toIso8601String()];
    }
    final expResult = await db.query(
      'expenses',
      where: whereExpenses,
      whereArgs: expenseArgs,
    );
    _expenses = expResult.map((e) => Expense.fromMap(e)).toList();

    // Fetch incomes (optionally filter by date)
    String? whereIncomes;
    List<Object?>? incomeArgs;
    if (from != null && to != null) {
      whereIncomes = 'date BETWEEN ? AND ?';
      incomeArgs = [from.toIso8601String(), to.toIso8601String()];
    }
    final incResult = await db.query(
      'incomes',
      where: whereIncomes,
      whereArgs: incomeArgs,
    );
    _incomes = incResult.map((e) => Income.fromMap(e)).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Get total expenses over currently loaded period
  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Get total incomes over currently loaded period
  double get totalIncome => _incomes.fold(0.0, (sum, i) => sum + i.amount);

  /// Get net savings (income - expense)
  double get netSavings => totalIncome - totalExpenses;

  /// Pie chart data: Map of categoryId to total expenses for that category.
  Map<int, double> expenseTotalsByCategory() {
    final map = <int, double>{};
    for (final e in _expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    return map;
  }

  /// Get a breakdown (e.g., for bar or time charts): total per month in current data.
  Map<DateTime, double> expenseTotalsByMonth() {
    final map = <DateTime, double>{};
    for (final e in _expenses) {
      final key = DateTime(e.date.year, e.date.month, 1); // group by month
      map[key] = (map[key] ?? 0) + e.amount;
    }
    return map;
  }

  /// List of expenses filtered by category.
  List<Expense> expensesForCategory(int categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).toList();
  }

  /// Get a report summary for a period (can be used for dashboards)
  ReportSummary reportSummary() {
    return ReportSummary(
      totalExpenses: totalExpenses,
      totalIncome: totalIncome,
      netSavings: netSavings,
      expenseByCategory: expenseTotalsByCategory(),
    );
  }
}

/// Small data holder for summary display/cards.
class ReportSummary {
  final double totalExpenses;
  final double totalIncome;
  final double netSavings;
  final Map<int, double> expenseByCategory;

  ReportSummary({
    required this.totalExpenses,
    required this.totalIncome,
    required this.netSavings,
    required this.expenseByCategory,
  });
}
