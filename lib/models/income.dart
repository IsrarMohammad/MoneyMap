import 'package:flutter/foundation.dart';

/// Model representing an income transaction in MoneyMap.
class Income {
  /// Unique database ID (nullable until saved)
  final int? id;

  /// Income amount (always positive)
  final double amount;

  /// Date and time when income was received
  final DateTime date;

  /// Optional user note or description (e.g. salary, gift, refund)
  final String? note;

  /// Optional: source/type of income (could be future feature)
  final String? source;

  /// Constructor (all fields except [id], [note], [source] are required)
  Income({
    this.id,
    required this.amount,
    required this.date,
    this.note,
    this.source,
  });

  /// Converts this income instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'source': source,
    };
  }

  /// Creates an Income from a Map (e.g. from SQLite DB).
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      source: map['source'] as String?,
    );
  }

  /// JSON support (optional, for future API/cloud sync).
  factory Income.fromJson(Map<String, dynamic> json) => Income.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  /// Creates a copy with updated fields (for edit flows).
  Income copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? note,
    String? source,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }

  /// Value equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Income &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          date == other.date &&
          note == other.note &&
          source == other.source;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      (note?.hashCode ?? 0) ^
      (source?.hashCode ?? 0);

  @override
  String toString() {
    return 'Income{id: $id, amount: $amount, date: $date, note: $note, source: $source}';
  }
}
