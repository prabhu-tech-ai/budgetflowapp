import 'package:flutter/material.dart';

import '../core/currency.dart';
import '../database/budget_database.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.database,
    required this.onAccountChanged,
    this.currencyCode = 'INR',
    this.selectedAccountId,
  });

  final BudgetDatabase database;
  final ValueChanged<int?> onAccountChanged;
  final String currencyCode;
  final int? selectedAccountId;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedCategoryId;
  bool _newestFirst = true;

  Future<void> _openAddTransaction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          database: widget.database,
          selectedAccountId: widget.selectedAccountId,
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Future<void> _pickCategory() async {
    final categories = await widget.database.watchCategories().first;
    if (!mounted) return;
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Filter by Category',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('All Categories'),
              trailing: _selectedCategoryId == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(sheetContext),
            ),
            for (final category in categories)
              ListTile(
                leading: Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                ),
                title: Text(category.name),
                trailing: category.id == _selectedCategoryId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, category.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _selectedCategoryId = selected);
  }

  Future<void> _pickSortOrder() async {
    final selected = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Sort Transactions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Newest Date'),
              trailing: _newestFirst ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(sheetContext, true),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Oldest Date'),
              trailing: !_newestFirst ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _newestFirst = selected);
  }

  Future<void> _pickAccount() async {
    final accounts = await widget.database.watchAccountsWithIcons().first;
    if (!mounted) return;
    final selected = await showModalBottomSheet<Object?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Filter by Account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('All Accounts'),
              trailing: widget.selectedAccountId == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(sheetContext, _allAccounts),
            ),
            for (final account in accounts)
              ListTile(
                leading: Icon(
                  IconData(account.iconCodePoint, fontFamily: 'MaterialIcons'),
                ),
                title: Text(account.name),
                trailing: account.id == widget.selectedAccountId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, account.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    widget.onAccountChanged(selected == _allAccounts ? null : selected as int);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWithDetails>>(
      stream: widget.database.watchTransactions(),
      builder: (context, snapshot) {
        final allTransactions = snapshot.data ?? <TransactionWithDetails>[];
        final transactions =
            allTransactions.where((item) {
              final date = item.transaction.transactionDate;
              final matchesAccount =
                  widget.selectedAccountId == null ||
                  item.transaction.accountId == widget.selectedAccountId;
              final matchesCategory =
                  _selectedCategoryId == null ||
                  item.transaction.categoryId == _selectedCategoryId;
              return matchesAccount &&
                  matchesCategory &&
                  date.year == _selectedMonth.year &&
                  date.month == _selectedMonth.month;
            }).toList()
          ..sort(
            (a, b) => _newestFirst
                ? b.transaction.transactionDate.compareTo(
                    a.transaction.transactionDate,
                  )
                : a.transaction.transactionDate.compareTo(
                    b.transaction.transactionDate,
                  ),
          );

        final categoryLabel = _selectedCategoryId == null
            ? 'All Categories'
            : allTransactions
                    .map((item) => item.category)
                    .whereType<Category>()
                    .where((category) => category.id == _selectedCategoryId)
                    .map((category) => category.name)
                    .firstOrNull ??
                'Category';

        final income = transactions
            .where((item) => item.transaction.amountCents > 0)
            .fold<int>(0, (sum, item) => sum + item.transaction.amountCents);
        final expenses = transactions
            .where((item) => item.transaction.amountCents < 0)
            .fold<int>(
              0,
              (sum, item) => sum + item.transaction.amountCents.abs(),
            );
        return Column(
          children: [
            _MonthHeader(
              selectedMonth: _selectedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onAdd: _openAddTransaction,
              onAccount: _pickAccount,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCategory,
                          icon: const Icon(Icons.filter_alt_outlined),
                          label: Text(categoryLabel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickSortOrder,
                          icon: const Icon(Icons.sort),
                          label: Text(
                            _newestFirst ? 'Newest Date' : 'Oldest Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatCurrencyAmount(income / 100, widget.currencyCode),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        formatCurrencyAmount(expenses / 100, widget.currencyCode),
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = transactions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: Icon(
                      item.category == null
                          ? Icons.category_outlined
                          : IconData(
                            item.category!.iconCodePoint,
                            fontFamily: 'MaterialIcons',
                          ),
                      size: 28,
                    ),
                    title: Text(
                      item.transaction.note ?? item.category?.name ?? 'General',
                    ),
                    subtitle: Text(
                      _formatDate(item.transaction.transactionDate),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrencyAmount(
                            item.transaction.amountCents.abs() / 100,
                            widget.currencyCode,
                          ),
                          style: TextStyle(
                            color:
                                item.transaction.amountCents >= 0
                                    ? Colors.green
                                    : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => EditTransactionScreen(
                            database: widget.database,
                            transaction: item.transaction,
                            category: item.category,
                            account: item.account,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-${_months[date.month - 1]}-${date.year}';

  static const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
  ];
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
    required this.onAccount,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAdd;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onAccount,
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Text(
                _months[selectedMonth.month - 1],
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

const _allAccounts = Object();
