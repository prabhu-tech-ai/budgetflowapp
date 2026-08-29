import 'package:flutter/material.dart';

import 'categories/categories_screen.dart';
import 'database/budget_database.dart';
import 'home/home_screen.dart';
import 'setting/settings_screen.dart';
import 'transaction/transactions_screen.dart';

void main() {
  runApp(MyApp(database: BudgetDatabase()));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, BudgetDatabase? database})
    : database = database ?? _defaultDatabase;

  static final _defaultDatabase = BudgetDatabase();

  final BudgetDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: BudgetShell(database: database),
    );
  }
}

class BudgetShell extends StatefulWidget {
  const BudgetShell({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> {
  int _selectedIndex = 0;

  late final _tabs = <_BudgetTabData>[
    _BudgetTabData(HomeScreen(database: widget.database)),
    _BudgetTabData(TransactionsScreen(database: widget.database)),
    _BudgetTabData(CategoriesListScreen(database: widget.database)),
    _BudgetTabData(SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedIndex];

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: tab.screen,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _BudgetTabData {
  const _BudgetTabData(this.screen);

  final Widget screen;
}
