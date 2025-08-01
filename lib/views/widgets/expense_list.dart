import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneymap/models/expense.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/viewmodels/expense_viewmodel.dart';
import 'package:moneymap/viewmodels/category_viewmodel.dart';

/// Displays a list of expenses, optionally grouped/sorted.
/// Requires both ExpenseViewModel and CategoryViewModel to be provided (via Provider).
class ExpenseList extends StatelessWidget {
  final List<Expense>? expenses; // Pass null to get from VM
  final bool showCategory; // Show icon/name for categories
  final bool showDate; // Show date as subtitle
  final bool allowDelete;
  final Function(Expense)?
      onDelete; // Optional: callback for custom delete handling
  final Function(Expense)? onTap;

  const ExpenseList({
    Key? key,
    this.expenses,
    this.showCategory = true,
    this.showDate = true,
    this.allowDelete = false,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final categoryVM = context.watch<CategoryViewModel>();
    final expList = expenses ?? expenseVM.expenses;

    if (expList.isEmpty) {
      return const Center(child: Text('No expenses found.'));
    }

    return ListView.separated(
      itemCount: expList.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final exp = expList[i];
        final cat = categoryVM.getCategoryById(exp.categoryId);

        return ListTile(
          leading: showCategory && cat != null
              ? CircleAvatar(
                  backgroundColor: cat.color,
                  child: Icon(
                    IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                  ),
                )
              : null,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expense amount
              Text(
                '\$${exp.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              if (showCategory && cat != null)
                Text(
                  cat.name,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exp.note != null && exp.note!.isNotEmpty) Text(exp.note!),
              if (showDate)
                Text(
                  _formatDate(exp.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: allowDelete
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    if (onDelete != null) {
                      onDelete!(exp);
                    } else {
                      // Default delete handler
                      _deleteExpense(context, expenseVM, exp.id!);
                    }
                  },
                )
              : null,
          onTap: onTap != null ? () => onTap!(exp) : null,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  /// Helper to format date as yyyy-mm-dd.
  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month < 10 ? '0${dt.month}' : dt.month.toString();
    final d = dt.day < 10 ? '0${dt.day}' : dt.day.toString();
    return '$y-$m-$d';
  }

  void _deleteExpense(BuildContext context, ExpenseViewModel vm, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense? This cannot be undone.',
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
      await vm.deleteExpense(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
