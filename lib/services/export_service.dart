import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/category.dart';

class ExportService {
  /// Exports a list of expenses as a CSV file and returns the file path.
  static Future<String> exportExpensesToCsv(List<Expense> expenses) async {
    final csv = StringBuffer();
    csv.writeln('ID,Amount,CategoryID,Date,Note');

    for (final e in expenses) {
      final noteEscaped = (e.note ?? '').replaceAll(',', ';');
      csv.writeln(
        '${e.id ?? ''},${e.amount},${e.categoryId},${e.date.toIso8601String()},$noteEscaped',
      );
    }

    final file = await _writeCsvFile('expenses_export.csv', csv.toString());
    return file.path;
  }

  /// Exports a list of incomes as a CSV file and returns the file path.
  static Future<String> exportIncomesToCsv(List<Income> incomes) async {
    final csv = StringBuffer();
    csv.writeln('ID,Amount,Date,Note,Source');

    for (final i in incomes) {
      final noteEscaped = (i.note ?? '').replaceAll(',', ';');
      final sourceEscaped = (i.source ?? '').replaceAll(',', ';');
      csv.writeln(
        '${i.id ?? ''},${i.amount},${i.date.toIso8601String()},$noteEscaped,$sourceEscaped',
      );
    }

    final file = await _writeCsvFile('incomes_export.csv', csv.toString());
    return file.path;
  }

  /// (Optional) Exports categories as CSV file (for backup/sharing).
  static Future<String> exportCategoriesToCsv(List<Category> categories) async {
    final csv = StringBuffer();
    csv.writeln('ID,Name,IconCodePoint,ColorValue');

    for (final c in categories) {
      csv.writeln(
        '${c.id ?? ''},${c.name.replaceAll(',', ';')},${c.iconCodePoint},${c.colorValue}',
      );
    }

    final file = await _writeCsvFile('categories_export.csv', csv.toString());
    return file.path;
  }

  /// Helper to write CSV data to file in the app's documents directory.
  static Future<File> _writeCsvFile(String filename, String data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return file.writeAsString(data);
  }

  /// Shares the exported file using system share dialog.
  static Future<void> shareExportedFile(String filePath) async {
    await Share.shareFiles([filePath], text: 'Exported data from MoneyMap');
  }
}
