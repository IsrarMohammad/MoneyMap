import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Add to pubspec.yaml for charts!
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/income_viewmodel.dart';
import '../viewmodels/report_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../models/category.dart';
import '../models/expense.dart';

// DASHBOARD PAGE FOR MONEYMAP
class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load all ViewModels needed for dashboard analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().fetchReportData();
      context.read<ExpenseViewModel>().fetchExpenses();
      context.read<IncomeViewModel>().fetchIncomes();
      context.read<BudgetViewModel>().fetchBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportVM = context.watch<ReportViewModel>();
    final expenseVM = context.watch<ExpenseViewModel>();
    final incomeVM = context.watch<IncomeViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();

    // Responsive layout
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyMap Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              reportVM.fetchReportData();
              expenseVM.fetchExpenses();
              incomeVM.fetchIncomes();
              budgetVM.fetchBudgets();
            },
          ),
        ],
      ),
      body: (false)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // OVERVIEW SUMMARY
                  _buildSummarySection(reportVM),
                  const SizedBox(height: 20),
                  // PIE CHART BY CATEGORY, CURRENT MONTH
                  _buildCategoryPieChart(reportVM, context),
                  const SizedBox(height: 20),
                  // INCOME/EXPENSE TREND CHART
                  _buildTrendsChart(reportVM),
                  const SizedBox(height: 20),
                  // RECENT TRANSACTIONS
                  _buildRecentTransactions(expenseVM.expenses, context),
                ],
              ),
            ),
    );
  }

  // SUMMARY: BALANCE, INCOME, EXPENSES
  Widget _buildSummarySection(ReportViewModel reportVM) {
    final summary = reportVM.reportSummary();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard(
          'Expenses',
          Icons.arrow_upward,
          Colors.redAccent,
          '-\$${summary.totalExpenses.toStringAsFixed(2)}',
        ),
        _summaryCard(
          'Income',
          Icons.arrow_downward,
          Colors.green,
          '+\$${summary.totalIncome.toStringAsFixed(2)}',
        ),
        _summaryCard(
          'Savings',
          Icons.account_balance_wallet,
          summary.netSavings >= 0 ? Colors.blue : Colors.red,
          '\$${summary.netSavings.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _summaryCard(String label, IconData icon, Color color, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.1),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // PIE CHART: SPENDING BY CATEGORY
  Widget _buildCategoryPieChart(
    ReportViewModel reportVM,
    BuildContext context,
  ) {
    final totals = reportVM.expenseTotalsByCategory();
    final categories = reportVM.categories;
    if (totals.isEmpty || categories.isEmpty) {
      return const Text('No category data for this period.');
    }

    final totalAmount = totals.values.fold(0.0, (sum, x) => sum + x);
    final List<PieChartSectionData> sections = [];
    totals.forEach((catId, val) {
      final cat = categories.firstWhere(
        (c) => c.id == catId,
        orElse: () => Category(
          id: 0,
          name: 'Other',
          iconCodePoint: 0,
          colorValue: 0xFFBDBDBD,
        ),
      );
      final percent = totalAmount == 0 ? 0 : (val / totalAmount * 100);
      sections.add(
        PieChartSectionData(
          value: val,
          color: Color(cat.colorValue),
          title: '${percent.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Spending by Category (Pie Chart)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LINE CHART: TRENDS OVER TIME
  Widget _buildTrendsChart(ReportViewModel reportVM) {
    final monthExpenseData = reportVM.expenseTotalsByMonth();
    if (monthExpenseData.isEmpty) {
      return const Text('No historical trend data.');
    }
    final months = monthExpenseData.keys.toList()..sort();
    final values = months.map((m) => monthExpenseData[m] ?? 0.0).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Trends (Bar Chart)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: values.isEmpty
                      ? 100
                      : values.reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 100),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= months.length)
                            return Container();
                          final month = months[value.toInt()];
                          return Text(
                            '${month.month}/${month.year % 100}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(months.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          color: Colors.blueAccent,
                          width: 14,
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
    );
  }

  // RECENT TRANSACTIONS LIST
  Widget _buildRecentTransactions(
    List<Expense> expenses,
    BuildContext context,
  ) {
    if (expenses.isEmpty) {
      return const Text('No recent transactions.');
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Expenses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              itemCount: expenses.length > 5 ? 5 : expenses.length,
              itemBuilder: (context, idx) {
                final exp = expenses[idx];
                return ListTile(
                  leading: const Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                  ),
                  title: Text('\$${exp.amount.toStringAsFixed(2)}'),
                  subtitle: Text(
                    '${exp.note ?? "No note"}\n${exp.date.toLocal().toString().split(' ')[0]}',
                  ),
                  isThreeLine: true,
                  dense: true,
                );
              },
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
    );
  }
}
