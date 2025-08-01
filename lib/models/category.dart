import 'package:flutter/material.dart';

/// Model representing a user-defined category in MoneyMap.
class Category {
  /// Unique database ID (nullable until created)
  final int? id;

  /// Name of category (e.g. 'Groceries', 'Transport', 'Salary')
  final String name;

  /// Icon name or code point (to allow selection from set; use Icons or custom set)
  final int iconCodePoint;

  /// Category color (as ARGB value)
  final int colorValue;

  /// Constructor
  Category({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });

  /// Converts this category to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  /// Creates a Category from a Map (from the database).
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
    );
  }

  /// JSON serialization support
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  /// Returns the color as a Flutter [Color] object.
  Color get color => Color(colorValue);

  /// Equality and copy support
  Category copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconCodePoint == other.iconCodePoint &&
          colorValue == other.colorValue;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      iconCodePoint.hashCode ^
      colorValue.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, iconCodePoint: $iconCodePoint, colorValue: $colorValue}';
  }
}
