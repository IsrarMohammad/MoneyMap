import 'package:flutter/material.dart';

/// Enum to represent app theme preferences.
enum AppThemeMode { system, light, dark }

/// Model representing user-specific app settings/preferences.
class UserSettings {
  /// Unique database ID (nullable if not saved yet)
  final int? id;

  /// Preferred app theme mode (system default, light, dark)
  final AppThemeMode themeMode;

  /// Whether notifications are enabled or not
  final bool notificationsEnabled;

  /// Whether cloud sync is enabled (opt-in)
  //final bool cloudSyncEnabled;

  /// Additional preferences can be added here...

  UserSettings({
    this.id,
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    //this.cloudSyncEnabled = false,
  });

  /// Convert UserSettings object to Map (suitable for SQLite or JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'themeMode': themeMode.index, // store enum as int index
      'notificationsEnabled':
          notificationsEnabled ? 1 : 0, // SQLite bool as int
      //'cloudSyncEnabled': cloudSyncEnabled ? 1 : 0,
    };
  }

  /// Create UserSettings object from Map (from SQLite or JSON)
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as int?,
      themeMode: AppThemeMode.values[map['themeMode'] as int? ?? 0],
      notificationsEnabled: (map['notificationsEnabled'] as int? ?? 1) == 1,
      //cloudSyncEnabled: (map['cloudSyncEnabled'] as int? ?? 0) == 1,
    );
  }

  /// JSON support if needed
  Map<String, dynamic> toJson() => toMap();

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      UserSettings.fromMap(json);

  /// Create a copy with updated fields for immutability and UI updates
  UserSettings copyWith({
    int? id,
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? cloudSyncEnabled,
  }) {
    return UserSettings(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      //cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    );
  }

  @override
  String toString() {
    return 'UserSettings{id: $id, themeMode: $themeMode, notificationsEnabled: $notificationsEnabled}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          themeMode == other.themeMode &&
          notificationsEnabled == other.notificationsEnabled;
  //cloudSyncEnabled == other.cloudSyncEnabled;

  @override
  int get hashCode =>
      id.hashCode ^ themeMode.hashCode ^ notificationsEnabled.hashCode;
  //cloudSyncEnabled.hashCode;
}
