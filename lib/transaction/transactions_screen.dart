import 'package:flutter/material.dart';

import '../database/budget_database.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  Future<void> _openAddTransaction() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(database: widget.database),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWithDetails>>(
      stream: widget.database.watchTransactions(),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? <TransactionWithDetails>[];
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
            _MonthHeader(onAdd: _openAddTransaction),
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
                          onPressed: () {},
                          icon: const Icon(Icons.filter_alt_outlined),
                          label: const Text('All Categories'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.sort),
                          label: const Text('Newest Date'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹ ${(income / 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹ ${(expenses / 100).toStringAsFixed(0)}',
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
                          '₹ ${(item.transaction.amountCents.abs() / 100).toStringAsFixed(0)}',
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'August',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
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
}
