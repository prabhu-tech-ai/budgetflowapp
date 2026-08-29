import 'package:flutter/material.dart';

import 'add_category_screen.dart';
import '../database/budget_database.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  Future<void> _openAddCategory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(database: widget.database),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: widget.database.watchCategories(),
      builder:
          (context, snapshot) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (snapshot.hasError)
                Text('Unable to load categories: ${snapshot.error}'),
              FilledButton.tonalIcon(
                onPressed: _openAddCategory,
                icon: const Icon(Icons.add),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add New Category'),
                ),
              ),
              const SizedBox(height: 12),
              for (final category in snapshot.data ?? <Category>[])
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Icon(
                    IconData(
                      category.iconCodePoint,
                      fontFamily: 'MaterialIcons',
                    ),
                  ),
                  title: Text(category.name),
                  shape: const Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
            ],
          ),
    );
  }
}
