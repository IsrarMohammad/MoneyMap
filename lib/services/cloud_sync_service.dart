import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:moneymap/models/expense.dart';
import 'package:moneymap/models/income.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/models/budget.dart';
import 'package:moneymap/models/user_settings.dart';

/// Singleton CloudSyncService: backs up and restores all MoneyMap user data.
/// Only used if user enables cloud sync in settings.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Sync user data to Firestore under a unique userId (anonymous/device/user's chosen ID).
  Future<void> backupToCloud({
    required String userId,
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<Category> categories,
    required List<Budget> budgets,
    required UserSettings userSettings,
  }) async {
    final userDoc = _db.collection('users').doc(userId);

    // Write all collections atomically (with merge).
    await userDoc.set({
      'lastBackup': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Store or overwrite each collection.
    await _writeCollection(
      userDoc.collection('expenses'),
      expenses.map((e) => e.toJson()).toList(),
    );
    await _writeCollection(
      userDoc.collection('incomes'),
      incomes.map((i) => i.toJson()).toList(),
    );
    await _writeCollection(
      userDoc.collection('categories'),
      categories.map((c) => c.toJson()).toList(),
    );
    await _writeCollection(
      userDoc.collection('budgets'),
      budgets.map((b) => b.toJson()).toList(),
    );
    await userDoc
        .collection('settings')
        .doc('prefs')
        .set(userSettings.toJson());
  }

  /// Restore all user data from cloud. Returns as model lists for local re-import.
  Future<CloudBackupData> restoreFromCloud(String userId) async {
    final userDoc = _db.collection('users').doc(userId);

    QuerySnapshot expenseSnap = await userDoc.collection('expenses').get();
    QuerySnapshot incomeSnap = await userDoc.collection('incomes').get();
    QuerySnapshot categorySnap = await userDoc.collection('categories').get();
    QuerySnapshot budgetSnap = await userDoc.collection('budgets').get();
    DocumentSnapshot settingSnap =
        await userDoc.collection('settings').doc('prefs').get();

    return CloudBackupData(
      expenses: expenseSnap.docs
          .map((d) => Expense.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      incomes: incomeSnap.docs
          .map((d) => Income.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      categories: categorySnap.docs
          .map((d) => Category.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      budgets: budgetSnap.docs
          .map((d) => Budget.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      userSettings: settingSnap.exists
          ? UserSettings.fromJson(settingSnap.data() as Map<String, dynamic>)
          : UserSettings(),
    );
  }

  /// Helper to overwrite a collection (deletes all, adds current; for simplicity/safety).
  Future<void> _writeCollection(
    CollectionReference ref,
    List<Map<String, dynamic>> docs,
  ) async {
    final batch = _db.batch();
    // Remove existing docs
    final snap = await ref.get();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    // Add new docs
    for (final doc in docs) {
      final newRef = ref.doc();
      batch.set(newRef, doc);
    }
    await batch.commit();
  }
}

/// Simple structure to hold all models for cloud backup/restore.
class CloudBackupData {
  final List<Expense> expenses;
  final List<Income> incomes;
  final List<Category> categories;
  final List<Budget> budgets;
  final UserSettings userSettings;

  CloudBackupData({
    required this.expenses,
    required this.incomes,
    required this.categories,
    required this.budgets,
    required this.userSettings,
  });
}
