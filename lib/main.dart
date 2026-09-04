import 'package:flutter/material.dart';

import 'categories/categories_screen.dart';
import 'database/budget_database.dart';
import 'home/home_screen.dart';
import 'setting/settings_screen.dart';
import 'transaction/transactions_screen.dart';

void main() {
  runApp(MyApp(database: BudgetDatabase()));
}

class MyApp extends StatefulWidget {
  MyApp({super.key, BudgetDatabase? database})
    : database = database ?? _defaultDatabase;

  static final _defaultDatabase = BudgetDatabase();

  final BudgetDatabase database;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _isDarkTheme = false;
  var _currencyCode = 'INR';
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _loadDefaultAccount();
  }

  Future<void> _loadDefaultAccount() async {
    final accountId = await widget.database.defaultAccountId();
    if (!mounted) return;
    setState(() => _selectedAccountId = accountId);
  }

  void _toggleTheme(bool value) {
    setState(() => _isDarkTheme = value);
  }

  void _setCurrency(String code) {
    setState(() => _currencyCode = code);
  }

  void _setSelectedAccount(int? id) {
    setState(() => _selectedAccountId = id);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetFlow',
      theme: ThemeData(
        brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
        ),
      ),
      home: BudgetShell(
        database: widget.database,
        isDarkTheme: _isDarkTheme,
        onToggleTheme: _toggleTheme,
        currencyCode: _currencyCode,
        onCurrencyChanged: _setCurrency,
        selectedAccountId: _selectedAccountId,
        onAccountChanged: _setSelectedAccount,
      ),
    );
  }
}

class BudgetShell extends StatefulWidget {
  const BudgetShell({
    super.key,
    required this.database,
    required this.isDarkTheme,
    required this.onToggleTheme,
    required this.currencyCode,
    required this.onCurrencyChanged,
    required this.selectedAccountId,
    required this.onAccountChanged,
  });

  final BudgetDatabase database;
  final bool isDarkTheme;
  final ValueChanged<bool> onToggleTheme;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final int? selectedAccountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> {
  int _selectedIndex = 0;

  List<_BudgetTabData> get _tabs => <_BudgetTabData>[
    _BudgetTabData(
      HomeScreen(
        database: widget.database,
        currencyCode: widget.currencyCode,
        selectedAccountId: widget.selectedAccountId,
          onAccountChanged: widget.onAccountChanged,
      ),
    ),
    _BudgetTabData(
      TransactionsScreen(
        database: widget.database,
        currencyCode: widget.currencyCode,
        selectedAccountId: widget.selectedAccountId,
      ),
    ),
    _BudgetTabData(CategoriesListScreen(database: widget.database)),
    _BudgetTabData(
      SettingsScreen(
        database: widget.database,
        isDarkTheme: widget.isDarkTheme,
        onToggleTheme: widget.onToggleTheme,
        currencyCode: widget.currencyCode,
        onCurrencyChanged: widget.onCurrencyChanged,
        selectedAccountId: widget.selectedAccountId,
        onAccountChanged: widget.onAccountChanged,
      ),
    ),
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
