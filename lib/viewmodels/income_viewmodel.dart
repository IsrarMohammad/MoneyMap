import 'package:flutter/material.dart';
import '../models/income.dart';
import '../services/database_service.dart';

/// IncomeViewModel: Manages all income CRUD and state for the UI.
class IncomeViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Internal list of incomes, updated on each fetch.
  List<Income> _incomes = [];
  bool _isLoading = false;

  // Expose to UI for immutable state
  List<Income> get incomes => List.unmodifiable(_incomes);
  bool get isLoading => _isLoading;

  /// Fetch all incomes, optional date filtering.
  Future<void> fetchIncomes({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      String where = '';
      List<Object?> params = [];

      if (from != null && to != null) {
        where = 'date BETWEEN ? AND ?';
        params.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final result = await db.query(
        'incomes',
        where: where.isNotEmpty ? where : null,
        whereArgs: params.isNotEmpty ? params : null,
        orderBy: 'date DESC',
      );
      _incomes = result.map((e) => Income.fromMap(e)).toList();
    } catch (e) {
      // You could log error or update UI error state here.
      _incomes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new income and refresh the list.
  Future<void> addIncome(Income income) async {
    await _dbService.insertIncome(
      income,
    ); // Implement this in your DatabaseService!
    await fetchIncomes();
  }

  /// Update an existing income by id.
  Future<void> updateIncome(Income income) async {
    if (income.id == null) return;
    final db = await _dbService.database;
    await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
    await fetchIncomes();
  }

  /// Delete an income by id.
  Future<void> deleteIncome(int id) async {
    final db = await _dbService.database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
    await fetchIncomes();
  }

  /// Get the total income for dashboard or analytics.
  double get totalIncome {
    return _incomes.fold(0.0, (sum, inc) => sum + inc.amount);
  }

  /// (Optional) Get incomes for a specific period as needed by the UI.
  List<Income> incomesForPeriod(DateTime from, DateTime to) {
    return _incomes
        .where((i) => i.date.isAfter(from) && i.date.isBefore(to))
        .toList();
  }
}
