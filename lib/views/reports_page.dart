import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../viewmodels/report_viewmodel.dart';
import '../models/category.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final reportVM = context.read<ReportViewModel>();
    if (_selectedRange != null) {
      reportVM.fetchReportData(
        from: _selectedRange!.start,
        to: _selectedRange!.end,
      );
    } else {
      reportVM.fetchReportData();
    }
  }

  // Allows user to pick a custom date range
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: _selectedRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportVM = context.watch<ReportViewModel>();
    final summary = reportVM.reportSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Pick Date Range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: false
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Summary of totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryTile(
                        'EXPENSES',
                        '-\$${summary.totalExpenses.toStringAsFixed(2)}',
                        Colors.red,
                      ),
                      _summaryTile(
                        'INCOME',
                        '+\$${summary.totalIncome.toStringAsFixed(2)}',
                        Colors.green,
                      ),
                      _summaryTile(
                        'SAVINGS',
                        '\$${summary.netSavings.toStringAsFixed(2)}',
                        summary.netSavings >= 0 ? Colors.blue : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Pie Chart: Expenses by Category
                  _pieChartByCategory(reportVM),
                  const SizedBox(height: 24),
                  // Bar Chart: Expense Trends
                  _expenseTrendsBarChart(reportVM),
                  const SizedBox(height: 24),
                  // Table/Breakdown
                  _categoryBreakdownTable(reportVM),
                ],
              ),
            ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.07),
      child: SizedBox(
        width: 110,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // Build Pie Chart of expenses by category
  Widget _pieChartByCategory(ReportViewModel reportVM) {
    final totals = reportVM.expenseTotalsByCategory();
    final categories = reportVM.categories;
    final totalAmount = totals.values.fold(0.0, (sum, x) => sum + x);

    if (totals.isEmpty || totalAmount == 0) {
      return const Text('No category spending data for this period.');
    }

    List<PieChartSectionData> sections = [];
    totals.forEach((catId, val) {
      final cat = categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category(
          id: 0,
          name: 'Other',
          iconCodePoint: 0,
          colorValue: 0xFF616161,
        ),
      );
      final percent = (val / totalAmount) * 100;
      sections.add(
        PieChartSectionData(
          value: val,
          color: Color(cat.colorValue),
          radius: 45,
          title: '${percent.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        height: 210,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Spending Breakdown by Category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Bar Chart of expenses over months
  Widget _expenseTrendsBarChart(ReportViewModel reportVM) {
    final trends = reportVM.expenseTotalsByMonth();
    if (trends.isEmpty) {
      return const Text('No expenses found for historical trend chart.');
    }

    final keys = trends.keys.toList()..sort();
    final values = keys.map((k) => trends[k] ?? 0.0).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        height: 195,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Trends by Month',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: values.isEmpty
                        ? 100
                        : (values.reduce((a, b) => a > b ? a : b)) * 1.2,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, interval: 100),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 ||
                                value.toInt() >= keys.length)
                              return Container();
                            final d = keys[value.toInt()];
                            return Text(
                              '${d.month}/${d.year % 100}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                          interval: 1,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(keys.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: values[index],
                            color: Colors.blue,
                            width: 13,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Table view: expense totals by category for the period
  Widget _categoryBreakdownTable(ReportViewModel reportVM) {
    final totals = reportVM.expenseTotalsByCategory();
    final cats = reportVM.categories;
    if (totals.isEmpty) return const SizedBox();

    List<DataRow> rows = totals.entries.map((entry) {
      final cat = cats.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: 0,
          name: 'Other',
          iconCodePoint: 0,
          colorValue: 0xFF616161,
        ),
      );
      return DataRow(
        cells: [
          DataCell(
            Row(
              children: [
                Icon(
                  IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(cat.colorValue),
                ),
                const SizedBox(width: 6),
                Text(cat.name),
              ],
            ),
          ),
          DataCell(Text('\$${entry.value.toStringAsFixed(2)}')),
        ],
      );
    }).toList();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Breakdown (Table)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Total Spent')),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
