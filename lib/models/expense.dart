import 'package:flutter/foundation.dart';

/// Model representing an expense transaction in MoneyMap.
class Expense {
  /// Unique database ID (nullable until saved)
  final int? id;

  /// Expense amount (always positive)
  final double amount;

  /// ID of the category this expense belongs to
  final int categoryId;

  /// Date and time when expense occurred
  final DateTime date;

  /// Optional user note or description
  final String? note;

  /// Constructor (all fields except [id] are required)
  Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
  });

  /// Converts this expense instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  /// Creates an Expense from a Map (e.g. from SQLite DB).
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }

  /// Creates an Expense from JSON (optional, if adding API/cloud sync in the future).
  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);

  /// Converts this expense to JSON (optional).
  Map<String, dynamic> toJson() => toMap();

  /// Creates a copy with updated fields (immutability/future editing).
  Expense copyWith({
    int? id,
    double? amount,
    int? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  /// Value equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          date == other.date &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      date.hashCode ^
      (note?.hashCode ?? 0);

  @override
  String toString() {
    return 'Expense{id: $id, amount: $amount, categoryId: $categoryId, date: $date, note: $note}';
  }
}
