import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { pie, bar }

/// Easy-to-use reusable chart widget for MoneyMap
/// Supports: PieChart (category breakdown), BarChart (trends)
class ChartWidget extends StatelessWidget {
  final ChartType chartType;
  final List<dynamic> data; // Expense breakdown, trends, etc.
  final List<Color>? colors;
  final String? title;
  final List<String>? categoriesOrLabels; // For bar or pie
  final double? height;

  const ChartWidget({
    Key? key,
    required this.chartType,
    required this.data,
    this.colors,
    this.title,
    this.categoriesOrLabels,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _height = height ?? 220;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: _height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: chartType == ChartType.pie
                    ? _buildPieChart(context)
                    : _buildBarChart(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pie Chart: e.g. {categoryName: 35.2, ...}
  Widget _buildPieChart(BuildContext context) {
    if (data.isEmpty || categoriesOrLabels == null) {
      return const Center(child: Text("No data for chart."));
    }
    final double total = data.fold(0.0, (sum, x) => sum + (x as double));
    if (total == 0) {
      return const Center(child: Text("No positive values to chart."));
    }

    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final value = data[i] as double;
          final percent = (value / total * 100).toStringAsFixed(1);
          final color = colors != null && i < colors!.length
              ? colors![i]
              : Colors.primaries[i % Colors.primaries.length];

          return PieChartSectionData(
            value: value,
            color: color,
            title: '$percent%',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            radius: 50,
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  /// Bar Chart: e.g. [double1, double2, ...], categoriesOrLabels = [label1, label2, ...]
  Widget _buildBarChart(BuildContext context) {
    if (data.isEmpty || categoriesOrLabels == null) {
      return const Center(child: Text("No data for chart."));
    }
    final maxVal = data.fold<double>(0, (max, v) => v > max ? v : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.25,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) =>
                  categoriesOrLabels!.length > v.toInt()
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        categoriesOrLabels![v.toInt()],
                        style: const TextStyle(fontSize: 10),
                      ),
                    )
                  : const SizedBox.shrink(),
              interval: 1,
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final color = colors != null && i < colors!.length
              ? colors![i]
              : Colors.blue;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i] as double,
                color: color,
                width: 14,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
