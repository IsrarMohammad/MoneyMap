import 'package:flutter/material.dart';
import 'package:moneymap/models/budget.dart';
import 'package:moneymap/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// BudgetViewModel: Manages budgets for expense categories, notifies UI, checks limits.
class BudgetViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Internal list of budgets
  List<Budget> _budgets = [];
  bool _isLoading = false;

  // Expose to UI
  List<Budget> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _isLoading;

  /// Fetch all budgets from database (optionally by category).
  Future<void> fetchBudgets({int? categoryId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      String? where;
      List<Object?>? whereArgs;
      if (categoryId != null) {
        where = 'categoryId = ?';
        whereArgs = [categoryId];
      }
      final result = await db.query(
        'budgets',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'categoryId ASC',
      );
      _budgets = result.map((b) => Budget.fromMap(b)).toList();
    } catch (e) {
      _budgets = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Add a new budget (enforcing only one budget per category/period).
  Future<bool> addBudget(Budget budget) async {
    // Prevent duplicate category+period
    if (_budgets.any((b) =>
        b.categoryId == budget.categoryId && b.period == budget.period)) {
      return false; // Already exists, UI must show error
    }
    final db = await _dbService.database;
    await db.insert('budgets', budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
    await fetchBudgets();
    return true;
  }

  /// Update an existing budget (by id).
  Future<void> updateBudget(Budget budget) async {
    if (budget.id == null) return;
    final db = await _dbService.database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    await fetchBudgets();
  }

  /// Delete a budget by id.
  Future<void> deleteBudget(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchBudgets();
  }

  /// Find a budget for a specific category and period.
  Budget? getBudgetForCategory(int categoryId, BudgetPeriod period) {
    try {
      return _budgets
          .firstWhere((b) => b.categoryId == categoryId && b.period == period);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a new expense would exceed budget; returns alert/percents for warning use.
  /// Optionally, this is where you trigger a notification service!
  BudgetAlertStatus checkBudgetStatus({
    required int categoryId,
    required double upcomingExpense,
    required BudgetPeriod period,
  }) {
    final budget = getBudgetForCategory(categoryId, period);
    if (budget == null) return BudgetAlertStatus.noBudget;
    final total = budget.spent + upcomingExpense;
    final percent = budget.amount == 0 ? 1.0 : (total / budget.amount);
    if (percent < 0.8) return BudgetAlertStatus.ok;
    if (percent < 1.0) return BudgetAlertStatus.nearingLimit;
    return BudgetAlertStatus.exceeded;
  }

  /// Quickly update the spent field for a budget (e.g. after a new expense).
  Future<void> updateBudgetSpent(
      int categoryId, BudgetPeriod period, double newSpent) async {
    final existing = getBudgetForCategory(categoryId, period);
    if (existing == null) return;
    final updated = existing.copyWith(spent: newSpent);
    await updateBudget(updated);
  }
}

/// Enum for visual/warning UI triggers.
enum BudgetAlertStatus { ok, nearingLimit, exceeded, noBudget }
