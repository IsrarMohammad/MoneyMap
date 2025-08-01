import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/database_service.dart';

/// SettingsViewModel: Manages user preferences for theme, notifications, and cloud sync.
/// Notifies the UI about changes.
class SettingsViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  UserSettings? _userSettings;
  bool _isLoading = false;

  /// Exposed user settings - nullable until loaded.
  UserSettings? get userSettings => _userSettings;

  bool get isLoading => _isLoading;

  /// Initialize and load settings from database.
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final result = await db.query('user_settings', limit: 1);
      if (result.isNotEmpty) {
        _userSettings = UserSettings.fromMap(result.first);
      } else {
        // No settings saved - use default
        _userSettings = UserSettings();
        await _saveSettingsToDb(_userSettings!);
      }
    } catch (e) {
      // Handle errors or fallback to defaults
      _userSettings = UserSettings();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Private helper to save settings to DB (insert/update logic).
  Future<void> _saveSettingsToDb(UserSettings settings) async {
    final db = await _dbService.database;
    if (settings.id == null) {
      int id = await db.insert('user_settings', settings.toMap());
      _userSettings = settings.copyWith(id: id);
    } else {
      await db.update(
        'user_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id],
      );
    }
  }

  /// Update app theme (system/light/dark) and persist.
  Future<void> updateThemeMode(AppThemeMode newMode) async {
    if (_userSettings == null) return;
    _userSettings = _userSettings!.copyWith(themeMode: newMode);
    await _saveSettingsToDb(_userSettings!);
    notifyListeners();
  }

  /// Enable or disable notifications, then persist.
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_userSettings == null) return;
    _userSettings = _userSettings!.copyWith(notificationsEnabled: enabled);
    await _saveSettingsToDb(_userSettings!);
    notifyListeners();
  }
}
