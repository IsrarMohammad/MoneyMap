import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/income.dart';
import '../../viewmodels/income_viewmodel.dart';

/// Widget to display a list of income entries.
/// Works with Provider<IncomeViewModel>.
class IncomeList extends StatelessWidget {
  final List<Income>? incomes; // (optional) provide subset of incomes
  final bool showSource; // Show source as subtitle
  final bool showDate; // Show date beside amount
  final bool allowDelete; // Show delete icon
  final Function(Income)? onDelete;
  final Function(Income)? onTap;

  const IncomeList({
    Key? key,
    this.incomes,
    this.showSource = true,
    this.showDate = true,
    this.allowDelete = false,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final incomeVM = context.watch<IncomeViewModel>();
    final incList = incomes ?? incomeVM.incomes;

    if (incList.isEmpty) {
      return const Center(child: Text('No income entries found.'));
    }

    return ListView.separated(
      itemCount: incList.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final inc = incList[i];

        return ListTile(
          leading: const Icon(
            Icons.arrow_downward,
            color: Colors.green,
            size: 32,
          ),
          title: Text(
            '\$${inc.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSource && inc.source != null && inc.source!.isNotEmpty)
                Text(
                  'Source: ${inc.source!}',
                  style: const TextStyle(fontSize: 13),
                ),
              if (inc.note != null && inc.note!.isNotEmpty)
                Text(
                  'Note: ${inc.note!}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              if (showDate)
                Text(
                  _formatDate(inc.date),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          trailing: allowDelete
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    if (onDelete != null) {
                      onDelete!(inc);
                    } else {
                      _deleteIncome(context, incomeVM, inc.id!);
                    }
                  },
                )
              : null,
          onTap: onTap != null ? () => onTap!(inc) : null,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month < 10 ? '0${dt.month}' : dt.month.toString();
    final d = dt.day < 10 ? '0${dt.day}' : dt.day.toString();
    return '$y-$m-$d';
  }

  void _deleteIncome(BuildContext context, IncomeViewModel vm, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income?'),
        content: const Text(
          'Are you sure you want to delete this income entry? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await vm.deleteIncome(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Income deleted!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
