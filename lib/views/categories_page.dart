import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:moneymap/models/category.dart';
import 'package:moneymap/viewmodels/category_viewmodel.dart';

/// Page for managing expense/income categories:
/// - Lists existing categories
/// - Allows adding new categories
/// - Allows editing or deleting existing categories
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryViewModel>().fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final categoryVM = context.watch<CategoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: categoryVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryVM.categories.isEmpty
              ? const Center(child: Text('No categories found. Add one!'))
              : ListView.builder(
                  itemCount: categoryVM.categories.length,
                  itemBuilder: (context, index) {
                    final cat = categoryVM.categories[index];
                    return ListTile(
                      leading: Icon(
                        IconData(cat.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: cat.color,
                        size: 28,
                      ),
                      title: Text(cat.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showAddEditDialog(
                              context,
                              categoryVM,
                              category: cat,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(context, categoryVM, cat),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, categoryVM),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows dialog for adding or editing a category.
  Future<void> _showAddEditDialog(
    BuildContext context,
    CategoryViewModel categoryVM, {
    Category? category,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: category?.name ?? '',
    );
    int selectedIconCode = category?.iconCodePoint ?? Icons.category.codePoint;
    Color selectedColor = category != null ? category.color : Colors.blue;

    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name Input
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Icon Picker - simplified with a few icons for demo
                      Wrap(
                        spacing: 8,
                        children: _iconChoices.map((icon) {
                          final isSelected = selectedIconCode == icon.codePoint;
                          return ChoiceChip(
                            label: Icon(icon, size: 24),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedIconCode = icon.codePoint;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Color Picker using flutter_colorpicker package
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pick a Color'),
                          GestureDetector(
                            onTap: () {
                              _pickColor(context, selectedColor, (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: selectedColor,
                              radius: 15,
                            ),
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
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newCategory = Category(
                    id: category?.id,
                    name: nameController.text.trim(),
                    iconCodePoint: selectedIconCode,
                    colorValue: selectedColor.value,
                  );
                  bool success;
                  if (category == null) {
                    success = await categoryVM.addCategory(newCategory);
                  } else {
                    success = await categoryVM.updateCategory(newCategory);
                  }

                  if (!success) {
                    // Show duplicate category error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category name already exists!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                }
              },
              child: Text(category == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  /// Shows color picker dialog
  Future<void> _pickColor(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorSelected,
  ) {
    Color pickerColor = currentColor;
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.pop(ctx);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  /// Confirms deletion of a category with warning about cascading data.
  void _confirmDelete(
    BuildContext context,
    CategoryViewModel categoryVM,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete "${category.name}"? This action cannot be undone and expenses linked to this category may be affected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await categoryVM.deleteCategory(category.id!);
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

/// A simple list of Material icons to allow user selection for categories.
const List<IconData> _iconChoices = [
  Icons.shopping_cart,
  Icons.fastfood,
  Icons.directions_bus,
  Icons.home,
  Icons.health_and_safety,
  Icons.sports_basketball,
  Icons.movie,
  Icons.school,
  Icons.pets,
  Icons.card_giftcard,
  Icons.category,
];
