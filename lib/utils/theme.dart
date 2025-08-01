import 'package:flutter/material.dart';

// Primary MoneyMap color palette
const Color kPrimaryColor = Colors.green;
const Color kAccentColor = Colors.teal;
const Color kExpenseColor = Colors.redAccent;
const Color kIncomeColor = Colors.green;
const Color kSavingsColor = Colors.blue;

// Light theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  primaryColor: kPrimaryColor,
  // accentColor: kAccentColor, // Removed as it's deprecated in ThemeData
  scaffoldBackgroundColor: const Color(0xFFF7F8FA),
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    elevation: 2,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87, fontSize: 16),
    bodySmall: TextStyle(color: Colors.black54, fontSize: 14),
    headlineSmall: TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Colors.green,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
  ),
);

// Dark theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.green,
  primaryColor: kPrimaryColor,
  scaffoldBackgroundColor: const Color(0xFF22242A),
  cardColor: const Color(0xFF272B34),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    elevation: 2,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
    bodySmall: TextStyle(color: Colors.white70, fontSize: 14),
    headlineSmall: TextStyle(
      color: Colors.greenAccent,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Colors.green,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    fillColor: const Color(0xFF252B34),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
  ),
);

// Helper for theme switching
ThemeData getAppTheme(Brightness brightness) {
  return brightness == Brightness.dark ? darkTheme : lightTheme;
}
