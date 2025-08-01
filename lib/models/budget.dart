import 'package:flutter/foundation.dart';

/// Enumeration for budget periods
enum BudgetPeriod { monthly, weekly }

/// Model representing a budget limit for a category.
class Budget {
  /// Unique database ID (nullable until saved)
  final int? id;

  /// The category this budget applies to
  final int categoryId;

  /// Budget limit amount
  final double amount;

  /// The time period this budget covers (monthly or weekly)
  final BudgetPeriod period;

  /// (Optional) Total spent in the current period (for real-time status)
  final double spent;

  /// Constructor
  Budget({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.spent = 0.0,
  });

  /// Converts the budget object to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'period': describeEnum(period), // Stores as "monthly" or "weekly"
      'spent': spent,
    };
  }

  /// Creates a budget from a database map
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      amount: (map['amount'] as num).toDouble(),
      period: _parsePeriod(map['period']),
      spent: map['spent'] != null ? (map['spent'] as num).toDouble() : 0.0,
    );
  }

  /// JSON serialization support
  factory Budget.fromJson(Map<String, dynamic> json) => Budget.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  /// Copy with for immutability/editing
  Budget copyWith({
    int? id,
    int? categoryId,
    double? amount,
    BudgetPeriod? period,
    double? spent,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      spent: spent ?? this.spent,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          amount == other.amount &&
          period == other.period &&
          spent == other.spent;

  @override
  int get hashCode =>
      id.hashCode ^
      categoryId.hashCode ^
      amount.hashCode ^
      period.hashCode ^
      spent.hashCode;

  @override
  String toString() {
    return 'Budget{id: $id, categoryId: $categoryId, amount: $amount, period: $period, spent: $spent}';
  }

  /// Helper for period enum serialization/deserialization.
  static BudgetPeriod _parsePeriod(dynamic value) {
    if (value is BudgetPeriod) {
      return value;
    }
    final str = value.toString().toLowerCase();
    switch (str) {
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'weekly':
        return BudgetPeriod.weekly;
      default:
        throw ArgumentError('Unknown period: $value');
    }
  }
}
