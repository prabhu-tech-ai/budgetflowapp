import 'package:flutter/material.dart';

import '../database/budget_database.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category_outlined;

  static const _availableIcons = <IconData>[
    Icons.shopping_bag_outlined,
    Icons.card_giftcard_outlined,
    Icons.flight_outlined,
    Icons.restaurant_outlined,
    Icons.sports_soccer_outlined,
    Icons.movie_outlined,
    Icons.local_fire_department_outlined,
    Icons.child_care_outlined,
    Icons.directions_walk_outlined,
    Icons.shopping_cart_outlined,
    Icons.home_outlined,
    Icons.receipt_long_outlined,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }

    try {
      await widget.database.addCategory(
        name: name,
        iconCodePoint: _selectedIcon.codePoint,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('New Category'),
        actions: [
          TextButton(onPressed: _saveCategory, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        children: [
          Text(
            'Category Detail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Divider(height: 32),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveCategory(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.grid_view_rounded),
              labelText: 'Icon',
              border: OutlineInputBorder(),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _availableIcons)
                  IconButton(
                    tooltip: 'Select icon',
                    onPressed: () => setState(() => _selectedIcon = icon),
                    color:
                        icon == _selectedIcon
                            ? Theme.of(context).colorScheme.primary
                            : null,
                    icon: Icon(icon),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
