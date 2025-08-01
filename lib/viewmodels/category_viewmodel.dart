import 'package:flutter/material.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// CategoryViewModel: Manages category CRUD and state for UI.
class CategoryViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // Internal list of categories, kept up to date.
  List<Category> _categories = [];
  bool _isLoading = false;

  // Exposed to UI for viewing (immutable)
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;

  /// Fetch all categories.
  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final result = await db.query(
        'categories',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      _categories = result.map((c) => Category.fromMap(c)).toList();
    } catch (e) {
      // Handle error or log as needed
      _categories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new category (with uniqueness check).
  Future<bool> addCategory(Category category) async {
    // Prevent duplicates by name (case-insensitive)
    if (_categories.any(
      (c) => c.name.toLowerCase() == category.name.toLowerCase(),
    )) {
      return false; // Indicates duplicate
    }
    final db = await _dbService.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    await fetchCategories();
    return true;
  }

  /// Update an existing category by id.
  Future<bool> updateCategory(Category category) async {
    if (category.id == null) return false;
    // Prevent duplicate name (ignore self)
    if (_categories.any(
      (c) =>
          c.name.toLowerCase() == category.name.toLowerCase() &&
          c.id != category.id,
    )) {
      return false;
    }
    final db = await _dbService.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    await fetchCategories();
    return true;
  }

  /// Delete a category by id (make sure to handle cascading in DB or UI).
  Future<void> deleteCategory(int id) async {
    final db = await _dbService.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await fetchCategories();
  }

  /// Find a category by id.
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// (Optional) Allow searching/filtering categories.
  List<Category> searchCategories(String query) {
    return _categories
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
