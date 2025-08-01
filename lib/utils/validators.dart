/// General-purpose validation utilities for MoneyMap forms.
class Validators {
  /// Validate that a required [String] field is not null or empty.
  static String? requiredField(
    String? value, {
    String fieldName = "This field",
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate that an input string can be parsed as a positive number.
  static String? positiveAmount(String? value, {String fieldName = "Amount"}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final num? d = num.tryParse(value);
    if (d == null || d <= 0) return 'Enter a valid, positive $fieldName';
    return null;
  }

  /// Validate that a category is selected (not null).
  static String? categorySelected(
    dynamic value, {
    String fieldName = "Category",
  }) {
    if (value == null) {
      return 'Please select a $fieldName';
    }
    return null;
  }

  /// Validate that a positive integer (e.g., for budgets) is entered.
  static String? positiveInt(String? value, {String fieldName = "Value"}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final int? i = int.tryParse(value);
    if (i == null || i <= 0) return 'Enter a valid, positive $fieldName';
    return null;
  }

  /// Optionally, validate a date (e.g., not in the future)
  static String? validDate(
    DateTime? date, {
    bool notFuture = false,
    String fieldName = "Date",
  }) {
    if (date == null) return '$fieldName is required';
    if (notFuture && date.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }
    return null;
  }

  /// Validate a category or budget name: not empty, max length.
  static String? validName(
    String? value, {
    int maxLength = 30,
    String fieldName = "Name",
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    if (value.length > maxLength) return '$fieldName must be <$maxLength chars';
    return null;
  }
}
