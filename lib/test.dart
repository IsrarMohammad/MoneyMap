
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymap/models/expense.dart';
import 'package:moneymap/models/income.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/models/budget.dart';
import 'package:moneymap/models/user_settings.dart';
import 'package:moneymap/viewmodels/expense_viewmodel.dart';
import 'package:moneymap/viewmodels/income_viewmodel.dart';
import 'package:moneymap/viewmodels/category_viewmodel.dart';
import 'package:moneymap/viewmodels/budget_viewmodel.dart';
import 'package:moneymap/viewmodels/settings_viewmodel.dart';
import 'package:moneymap/viewmodels/report_viewmodel.dart';
import 'package:moneymap/services/export_service.dart';
import 'package:moneymap/services/notification_service.dart';

void main() {
  // ------------ ExpenseViewModel CRUD + Validation
  group('ExpenseViewModel', () {
    late ExpenseViewModel vm;
    setUp(() {
      vm = ExpenseViewModel();
    });

    test('Add/Fetche/Edit/Delete Expense', () async {
      final dt = DateTime.now();
      final e = Expense(amount: 9.9, categoryId: 1, date: dt, note: 'TestE');
      await vm.addExpense(e);
      await vm.fetchExpenses();
      expect(vm.expenses.any((x) => x.note == 'TestE'), true);

      final added = vm.expenses.firstWhere((x) => x.note == 'TestE');
      final updated = added.copyWith(amount: 17.2, note: 'Changed');
      await vm.updateExpense(updated);
      await vm.fetchExpenses();
      expect(vm.expenses.any((x) => x.amount == 17.2 && x.note == 'Changed'), true);

      await vm.deleteExpense(updated.id!);
      await vm.fetchExpenses();
      expect(vm.expenses.any((x) => x.note == 'Changed'), false);
    });

    test('Expenses filtered by period/category', () async {
      final dt = DateTime.now();
      final e1 = Expense(amount: 1, categoryId: 2, date: dt.subtract(Duration(days: 7)));
      final e2 = Expense(amount: 2, categoryId: 3, date: dt);
      await vm.addExpense(e1);
      await vm.addExpense(e2);
      await vm.fetchExpenses(from: dt.subtract(Duration(days: 2)), to: dt.add(Duration(days: 1)));
      expect(vm.expenses.any((x) => x.categoryId == 3), true);
      expect(vm.expenses.any((x) => x.categoryId == 2), false);
    });
  });

  // ------------ IncomeViewModel CRUD + period filter
  group('IncomeViewModel', () {
    late IncomeViewModel vm;
    setUp(() {
      vm = IncomeViewModel();
    });

    test('Add/Fetch/Update/Delete Income', () async {
      final dt = DateTime.now();
      final inc = Income(amount: 25.0, date: dt, source: 'Bonus', note: 'Win');
      await vm.addIncome(inc);
      await vm.fetchIncomes();
      expect(vm.incomes.any((i) => i.source == 'Bonus'), true);

      final fetched = vm.incomes.firstWhere((i) => i.source == 'Bonus');
      final updated = fetched.copyWith(amount: 50.0, note: 'Changed');
      await vm.updateIncome(updated);
      await vm.fetchIncomes();
      expect(vm.incomes.any((i) => i.amount == 50.0 && i.note == 'Changed'), true);

      await vm.deleteIncome(updated.id!);
      await vm.fetchIncomes();
      expect(vm.incomes.any((i) => i.note == 'Changed'), false);
    });

    test('Period filter on incomes', () async {
      final dt = DateTime.now();
      final i1 = Income(amount: 10, date: dt.subtract(Duration(days: 8)));
      final i2 = Income(amount: 11, date: dt);
      await vm.addIncome(i1);
      await vm.addIncome(i2);
      await vm.fetchIncomes(from: dt.subtract(Duration(days: 3)), to: dt.add(Duration(days: 1)));
      expect(vm.incomes.any((i) => i.amount == 11), true);
      expect(vm.incomes.any((i) => i.amount == 10), false);
    });
  });

  // ------------ CategoryViewModel CRUD + dup check
  group('CategoryViewModel', () {
    late CategoryViewModel vm;
    setUp(() async {
      vm = CategoryViewModel();
      await vm.fetchCategories();
    });

    test('Add, Update, Delete, Duplicate', () async {
      final c1 = Category(name: 'FoodTest', iconCodePoint: 0, colorValue: 0);
      bool ok = await vm.addCategory(c1);
      expect(ok, true);

      bool dup = await vm.addCategory(Category(name: 'FoodTest', iconCodePoint: 0, colorValue: 0));
      expect(dup, false);

      final added = vm.categories.firstWhere((c) => c.name == 'FoodTest');
      final updated = added.copyWith(name: 'FoodTestUpdated');
      bool uok = await vm.updateCategory(updated);
      expect(uok, true);

      await vm.deleteCategory(updated.id!);
      await vm.fetchCategories();
      expect(vm.categories.any((c) => c.name == 'FoodTestUpdated'), false);
    });
  });

  // ------------ BudgetViewModel CRUD + duplicate check/period
  group('BudgetViewModel', () {
    late BudgetViewModel vm;
    setUp(() {
      vm = BudgetViewModel();
    });

    test('Add, Fetch, Edit, Delete Budget and Dup Check', () async {
      final b = Budget(categoryId: 100, amount: 55.5, period: BudgetPeriod.monthly);
      bool added = await vm.addBudget(b);
      expect(added, true);

      bool dup = await vm.addBudget(Budget(categoryId: 100, amount: 80, period: BudgetPeriod.monthly));
      expect(dup, false);

      await vm.fetchBudgets();
      expect(vm.budgets.any((b1) => b1.categoryId == 100), true);

      final old = vm.budgets.firstWhere((b1) => b1.categoryId == 100);
      final up = old.copyWith(amount: 10.0);
      await vm.updateBudget(up);
      await vm.fetchBudgets();
      expect(vm.budgets.firstWhere((b) => b.id == up.id).amount, 10.0);

      await vm.deleteBudget(up.id!);
      await vm.fetchBudgets();
      expect(vm.budgets.any((b) => b.id == up.id), false);
    });
  });

  // ------------ SettingsViewModel load and updates
  group('SettingsViewModel', () {
    test('Settings CRUD and field updates', () async {
      final vm = SettingsViewModel();
      await vm.loadSettings();
      expect(vm.userSettings, isNotNull);

      await vm.updateThemeMode(AppThemeMode.dark);
      expect(vm.userSettings!.themeMode, AppThemeMode.dark);

      await vm.setCloudSyncEnabled(true);
      expect(vm.userSettings!.cloudSyncEnabled, true);

      await vm.setNotificationsEnabled(false);
      expect(vm.userSettings!.notificationsEnabled, false);
    });
  });

  // ------------ ReportViewModel summaries, breakdowns, and filters
  group('ReportViewModel', () {
    late ReportViewModel vm;
    setUp(() {
      vm = ReportViewModel();
    });

    test('Report data methods run', () async {
      await vm.fetchReportData();
      // Should not throw and should provide summaries—expand with more fixture data
      final summary = vm.reportSummary();
      expect(summary, isA<ReportSummary>());
      vm.expenseTotalsByCategory(); // for pie
      vm.expenseTotalsByMonth(); // for trends
      expect(vm.categories, isList);
      expect(summary.totalExpenses, isA<double>());
      expect(summary.totalIncome, isA<double>());
    });
  });

  // ------------ ExportService
  group('ExportService', () {
    test('Exports expenses to CSV with all columns', () async {
      final now = DateTime.now();
      final expenses = [
        Expense(id: 1, amount: 2.5, categoryId: 30, date: now, note: 'Test CSV'),
        Expense(amount: 90, categoryId: 33, date: now, note: null),
      ];
      String filepath = await ExportService.exportExpensesToCsv(expenses);
      expect(await File(filepath).exists(), true);
      final content = await File(filepath).readAsString();
      expect(content.contains('Test CSV'), true);
      expect(content.contains('Amount'), true);
    });
  });

  // ------------ NotificationService (initialization test only)
  group('NotificationService', () {
    test('Initialize notification plugin', () async {
      final s = NotificationService();
      await s.init();
      expect(true, true); // If no error thrown, passes
    });
  });


}
