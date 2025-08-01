import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:moneymap/models/budget.dart';
import 'package:moneymap/models/category.dart';
import 'package:moneymap/viewmodels/budget_viewmodel.dart';
import 'package:moneymap/viewmodels/category_viewmodel.dart';

/// Page to manage budgets: view list, add new budget, edit existing budgets, delete budgets.
/// Supports selecting category, budget amount, and period (monthly/weekly).
class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  @override
  void initState() {
    super.initState();
    final budgetVM = context.read<BudgetViewModel>();
    budgetVM.fetchBudgets();

    final categoryVM = context.read<CategoryViewModel>();
    if (categoryVM.categories.isEmpty) {
      categoryVM.fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetVM = context.watch<BudgetViewModel>();
    final categoryVM = context.watch<CategoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetVM.isLoading || categoryVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryVM.categories.isEmpty
              ? const Center(
                  child: Text(
                    'No categories available. Please add categories first.',
                  ),
                )
              : budgetVM.budgets.isEmpty
                  ? _buildNoBudgetsUI()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: budgetVM.budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgetVM.budgets[index];
                        final category =
                            categoryVM.getCategoryById(budget.categoryId);
                        if (category == null) {
                          return const SizedBox(); // category possibly deleted, skip
                        }
                        return _buildBudgetCard(budgetVM, budget, category);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddEditBudgetDialog(context, budgetVM, categoryVM),
        child: const Icon(Icons.add),
        tooltip: 'Add Budget',
      ),
    );
  }

  Widget _buildNoBudgetsUI() {
    return const Center(
      child: Text(
        'No budgets set.\nTap the + button to add a budget.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBudgetCard(
    BudgetViewModel budgetVM,
    Budget budget,
    Category category,
  ) {
    // Calculate progress percentage
    final percent = budget.amount == 0
        ? 0.0
        : (budget.spent / budget.amount).clamp(0.0, 1.0);

    Color getProgressColor() {
      if (percent < 0.8) return Colors.green;
      if (percent < 1.0) return Colors.orange;
      return Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
          color: category.color,
          size: 32,
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Budget: \$${budget.amount.toStringAsFixed(2)} / ${_periodToString(budget.period)}',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent,
              color: getProgressColor(),
              backgroundColor: Colors.grey.shade300,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              'Spent: \$${budget.spent.toStringAsFixed(2)} (${(percent * 100).toStringAsFixed(1)}%)',
              style: TextStyle(color: getProgressColor()),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditBudgetDialog(
                context,
                budgetVM,
                context.read<CategoryViewModel>(),
                budget: budget,
              );
            } else if (value == 'delete') {
              _confirmDeleteBudget(context, budgetVM, budget);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  /// Helper to convert the enum BudgetPeriod to readable string
  String _periodToString(BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.weekly:
        return 'Weekly';
    }
  }

  /// Dialog to add or edit a budget
  Future<void> _showAddEditBudgetDialog(
    BuildContext context,
    BudgetViewModel budgetVM,
    CategoryViewModel categoryVM, {
    Budget? budget,
  }) async {
    final _formKey = GlobalKey<FormState>();
    double? amount = budget?.amount;
    BudgetPeriod period = budget?.period ?? BudgetPeriod.monthly;
    Category? selectedCategory =
        budget != null ? categoryVM.getCategoryById(budget.categoryId) : null;

    // For new budgets, preselect first category
    if (selectedCategory == null && categoryVM.categories.isNotEmpty) {
      selectedCategory = categoryVM.categories.first;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(budget == null ? 'Add Budget' : 'Edit Budget'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category Dropdown
                      DropdownButtonFormField<Category>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categoryVM.categories.map((cat) {
                          return DropdownMenuItem<Category>(
                            value: cat,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedCategory = val;
                          });
                        },
                        validator: (val) =>
                            val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),

                      // Budget amount input
                      TextFormField(
                        initialValue: amount?.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Budget Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a budget amount';
                          }
                          final n = double.tryParse(val);
                          if (n == null || n <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                        onSaved: (val) {
                          amount = double.tryParse(val ?? '');
                        },
                      ),
                      const SizedBox(height: 16),

                      // Period radio buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Period'),
                          RadioListTile<BudgetPeriod>(
                            title: const Text('Monthly'),
                            value: BudgetPeriod.monthly,
                            groupValue: period,
                            onChanged: (val) {
                              setState(() {
                                period = val!;
                              });
                            },
                          ),
                          RadioListTile<BudgetPeriod>(
                            title: const Text('Weekly'),
                            value: BudgetPeriod.weekly,
                            groupValue: period,
                            onChanged: (val) {
                              setState(() {
                                period = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: Text(budget == null ? 'Add' : 'Save'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                _formKey.currentState!.save();

                if (selectedCategory == null || amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid input')),
                  );
                  return;
                }

                final newBudget = Budget(
                  id: budget?.id,
                  categoryId: selectedCategory!.id!,
                  amount: amount!,
                  period: period,
                  spent: budget?.spent ?? 0.0,
                );

                bool success;
                if (budget == null) {
                  success = await budgetVM.addBudget(newBudget);
                } else {
                  await budgetVM.updateBudget(newBudget);
                  success = true;
                }

                if (!success) {
                  // Budget for category + period already exists
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Budget for this category and period already exists.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Confirm deletion of a budget
  void _confirmDeleteBudget(
    BuildContext context,
    BudgetViewModel budgetVM,
    Budget budget,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: const Text('Are you sure you want to delete this budget?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                await budgetVM.deleteBudget(budget.id!);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
