import 'package:flutter/material.dart';

import '../database/budget_database.dart';
import 'category_icons.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  IconData? _selectedIcon;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedIcon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            name.isEmpty ? 'Enter a category name' : 'Select a category icon',
          ),
        ),
      );
      return;
    }

    try {
      await widget.database.addCategory(
        name: name,
        iconCodePoint: _selectedIcon!.codePoint,
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
          TextButton(
            onPressed: _nameController.text.trim().isNotEmpty &&
                    _selectedIcon != null
                ? _saveCategory
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Detail',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(height: 32),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _saveCategory(),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Category Icons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  child: Icon(_selectedIcon ?? Icons.grid_view_rounded),
                ),
                const SizedBox(width: 12),
                const Text('Select an icon for this category'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in categoryIconGroups) ...[
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final icon in group.icons)
                            IconButton(
                              tooltip: '${group.name} icon',
                              onPressed: () =>
                                  setState(() => _selectedIcon = icon),
                              color: icon == _selectedIcon
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              icon: Icon(icon),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
