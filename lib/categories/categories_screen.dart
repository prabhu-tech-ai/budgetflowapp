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
  late Future<List<Category>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = _loadCategories();
  }

  Future<List<Category>> _loadCategories() =>
      widget.database.select(widget.database.categories).get();

  Future<void> _openAddCategory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddCategoryScreen(database: widget.database),
      ),
    );
    if (!mounted) return;
    setState(() => _categories = _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Categories'),
      ),
      body: FutureBuilder<List<Category>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load categories: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              FilledButton.tonalIcon(
                onPressed: _openAddCategory,
                icon: const Icon(Icons.add),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add New Category'),
                ),
              ),
              const SizedBox(height: 12),
              for (final category in snapshot.data!)
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
          );
        },
      ),
    );
  }
}
