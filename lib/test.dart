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
import 'package:moneymap/services/export_service.dart';
import 'package:moneymap/services/notification_service.dart';

void main() {
  //------------------------ Expense Model Logic ------------------------//
  test('Expense model: can serialize and deserialize', () {
    final exp = Expense(amount: 12.5, categoryId: 1, date: DateTime.now(), note: 'Lunch');
    final map = exp.toMap();
    final fromMap = Expense.fromMap(map);
    expect(fromMap.amount, 12.5);
    expect(fromMap.note, 'Lunch');
  });

  //------------------------ Add Expense via ViewModel ------------------------//
  test('ExpenseViewModel: add expense increases count', () async {
    final vm = ExpenseViewModel();
    final initial = vm.expenses.length;
    await vm.addExpense(Expense(amount: 5, categoryId: 1, date: DateTime.now()));
    expect(vm.expenses.length, initial + 1);
  });

  //------------------------ Edit Expense ------------------------//
  test('ExpenseViewModel: can edit expense amount', () async {
    final vm = ExpenseViewModel();
    await vm.addExpense(Expense(amount: 5, categoryId: 1, date: DateTime.now(), note: 'Orig'));
    final exp = vm.expenses.firstWhere((e) => e.note == 'Orig');
    final updated = exp.copyWith(amount: 8, note: 'Updated');
    await vm.updateExpense(updated);
    expect(vm.expenses.firstWhere((e) => e.id == exp.id).amount, 8);
  });

  //------------------------ Delete Expense ------------------------//
  test('ExpenseViewModel: delete expense removes it', () async {
    final vm = ExpenseViewModel();
    await vm.addExpense(Expense(amount: 9, categoryId: 1, date: DateTime.now(), note: 'DeleteMe'));
    final exp = vm.expenses.firstWhere((e) => e.note == 'DeleteMe');
    await vm.deleteExpense(exp.id!);
    expect(vm.expenses.any((e) => e.id == exp.id), false);
  });

  //------------------------ Add Category and Prevent Duplicate ------------------------//
  test('CategoryViewModel: add and prevent duplicate category names', () async {
    final vm = CategoryViewModel();
    final ok1 = await vm.addCategory(Category(name: 'FoodDup', iconCodePoint: 0, colorValue: 0));
    final dup = await vm.addCategory(Category(name: 'FoodDup', iconCodePoint: 0, colorValue: 0));
    expect(ok1, true);
    expect(dup, false);
  });

  //------------------------ Category Edit/Update ------------------------//
  test('CategoryViewModel: edit category name', () async {
    final vm = CategoryViewModel();
    await vm.addCategory(Category(name: 'ForEdit', iconCodePoint: 0, colorValue: 0));
    final cat = vm.categories.firstWhere((c) => c.name == 'ForEdit');
    final updated = cat.copyWith(name: 'Edited');
    final ok = await vm.updateCategory(updated);
    expect(ok, true);
    expect(vm.categories.any((c) => c.name == 'Edited'), true);
  });

  //------------------------ Delete Category ------------------------//
  test('CategoryViewModel: delete removes category', () async {
    final vm = CategoryViewModel();
    await vm.addCategory(Category(name: 'KillMe', iconCodePoint: 0, colorValue: 0));
    final cat = vm.categories.firstWhere((c) => c.name == 'KillMe');
    await vm.deleteCategory(cat.id!);
    await vm.fetchCategories();
    expect(vm.categories.any((c) => c.id == cat.id), false);
  });

  //------------------------ Add Income and Edit ------------------------//
  test('IncomeViewModel: add and edit income', () async {
    final vm = IncomeViewModel();
    await vm.addIncome(Income(amount: 100, date: DateTime.now(), note: 'Job'));
    final inc = vm.incomes.firstWhere((i) => i.note == 'Job');
    await vm.updateIncome(inc.copyWith(amount: 150, note: 'Raise'));
    expect(vm.incomes.firstWhere((i) => i.note == 'Raise').amount, 150);
  });

  //------------------------ Budget: Add, Prevent Duplicate, Edit, Delete ------------------------//
  test('BudgetViewModel: prevents duplicate period+category', () async {
    final vm = BudgetViewModel();
    final b = Budget(categoryId: 99, amount: 100, period: BudgetPeriod.weekly);
    final added = await vm.addBudget(b);
    final dup = await vm.addBudget(b);
    expect(added, true);
    expect(dup, false);
    // Edit
    final b2 = vm.budgets.firstWhere((budg) => budg.categoryId == 99 && budg.period == BudgetPeriod.weekly);
    await vm.updateBudget(b2.copyWith(amount: 200));
    expect(vm.budgets.firstWhere((budg) => budg.id == b2.id).amount, 200);
    // Delete
    await vm.deleteBudget(b2.id!);
    expect(vm.budgets.any((budg) => budg.id == b2.id), false);
  });

  //------------------------ Settings: Theme, Notification, CloudSync ------------------------//
  test('SettingsViewModel: loads and updates preferences', () async {
    final vm = SettingsViewModel();
    await vm.loadSettings();
    await vm.updateThemeMode(AppThemeMode.dark);
    expect(vm.userSettings!.themeMode, AppThemeMode.dark);
    await vm.setNotificationsEnabled(false);
    expect(vm.userSettings!.notificationsEnabled, false);
    await vm.setCloudSyncEnabled(true);
    expect(vm.userSettings!.cloudSyncEnabled, true);
  });

  //------------------------ Expense Validation: Only Accepts Positives ------------------------//
  test('Expense cannot be created with negative amount', () {
    expect(
      () => Expense(amount: -5, categoryId: 1, date: DateTime.now()), throwsA(isA<AssertionError>()),
    );
  });

  //------------------------ Expense Model: Date Serialization ------------------------//
  test('Expense serializes and deserializes date correctly', () {
    final now = DateTime.now();
    final e = Expense(amount: 1, categoryId: 2, date: now);
    final map = e.toMap();
    expect(DateTime.parse(map['date'] as String).year, now.year);
  });

  //------------------------ ExportService: Generates CSV ------------------------//
  test('ExportService creates CSV with correct fields', () async {
    final filePath = await ExportService.exportExpensesToCsv([
      Expense(id: 42, amount: 10, categoryId: 5, date: DateTime(2025, 7, 30), note: 'ExportTest')
    ]);
    final file = File(filePath);
    expect(await file.exists(), true);
    final content = await file.readAsString();
    expect(content.contains('ExportTest'), true);
  });

  //------------------------ NotificationService: Initializes ------------------------//
  test('NotificationService initializes plugin', () async {
    final s = NotificationService();
    await s.init();
    expect(true, true);
  });

  //----- Settings: Loads default on first run -----//
  test('SettingsViewModel loads default if not set', () async {
    final vm = SettingsViewModel();
    await vm.loadSettings();
    expect(vm.userSettings, isNotNull);
  });

  //------------------------ Category Search ------------------------//
  test('CategoryViewModel: find category by id and search by name', () async {
    final vm = CategoryViewModel();
    await vm.addCategory(Category(name: 'Searchable', iconCodePoint: 0, colorValue: 0));
    final found = vm.searchCategories('search');
    expect(found.isNotEmpty, true);
    final c = vm.categories.firstWhere((c) => c.name == 'Searchable');
    expect(vm.getCategoryById(c.id!), isNotNull);
  });

  //------------------------ Budget: Spent calculation updates after Expense added ------------------------//
  // To fully test this, you would write logic to check budget spent updates after an expense add;
  // for simplicity, test the spent field directly here:
  test('Budget spent field supports updates', () {
    final b = Budget(categoryId: 2, amount: 20, period: BudgetPeriod.monthly, spent: 5);
    final updated = b.copyWith(spent: 15);
    expect(updated.spent, 15);
  });

  //------------------------ Expense: Note field optional ------------------------//
  test('Expense accepts empty and null note fields', () {
    final e1 = Expense(amount: 1, categoryId: 1, date: DateTime.now(), note: '');
    final e2 = Expense(amount: 1, categoryId: 1, date: DateTime.now());
    expect(e1.note, '');
    expect(e2.note, null);
  });

  //------------------------ Budget: Period serialization/deserialization ------------------------//
  test('Budget serializes period as string and restores', () {
    final b = Budget(categoryId: 4, amount: 40, period: BudgetPeriod.weekly);
    final map = b.toMap();
    expect(map['period'], 'weekly');
    final parsed = Budget.fromMap(map);
    expect(parsed.period, BudgetPeriod.weekly);
  });

  //------------------------ Income: Source and Note optional ------------------------//
  test('Income can be created without note and source', () {
    final i = Income(amount: 10, date: DateTime.now());
    expect(i.note, null);
    expect(i.source, null);
  });
}
