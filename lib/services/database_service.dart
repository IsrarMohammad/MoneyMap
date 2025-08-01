import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/user_settings.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moneymap.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Categories table
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            iconCodePoint INTEGER NOT NULL,
            colorValue INTEGER NOT NULL
          )
        ''');

        // Expenses table
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            categoryId INTEGER NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          )
        ''');

        // Incomes table
        await db.execute('''
          CREATE TABLE incomes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            source TEXT
          )
        ''');

        // Budgets table
        await db.execute('''
          CREATE TABLE budgets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoryId INTEGER NOT NULL,
            amount REAL NOT NULL,
            period TEXT NOT NULL,
            spent REAL DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories (id)
          )
        ''');

        // User settings table (single row!)
        await db.execute('''
          CREATE TABLE user_settings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            themeMode INTEGER DEFAULT 0,
            notificationsEnabled INTEGER DEFAULT 1,
            cloudSyncEnabled INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // -- Expenses CRUD --
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // -- Incomes CRUD --
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('incomes', income.toMap());
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await database;
    final result = await db.query('incomes', orderBy: 'date DESC');
    return result.map((i) => Income.fromMap(i)).toList();
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  // -- Categories CRUD --
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return result.map((c) => Category.fromMap(c)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Optionally, handle category deletion (e.g. set categoryId to null in expenses)
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // -- Budgets CRUD --
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets', orderBy: 'categoryId');
    return result.map((b) => Budget.fromMap(b)).toList();
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // -- UserSettings (single row) --
  Future<int> insertUserSettings(UserSettings settings) async {
    final db = await database;
    return await db.insert('user_settings', settings.toMap());
  }

  Future<UserSettings?> getUserSettings() async {
    final db = await database;
    final result = await db.query('user_settings', limit: 1);
    if (result.isNotEmpty) {
      return UserSettings.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUserSettings(UserSettings settings) async {
    final db = await database;
    return await db.update(
      'user_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }
}
