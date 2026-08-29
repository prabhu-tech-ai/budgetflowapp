import 'package:flutter/material.dart';

import '../database/budget_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});

  final BudgetDatabase database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _month;
  late Future<BudgetOverview> _overview;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _overview = widget.database.loadOverview(_month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _overview = widget.database.loadOverview(_month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BudgetOverview>(
      future: _overview,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed:
                  () => setState(
                    () => _overview = widget.database.loadOverview(_month),
                  ),
              child: const Text('Retry loading overview'),
            ),
          );
        }
        final overview = snapshot.data;
        if (overview == null) return const SizedBox.shrink();
        return _OverviewContent(
          overview: overview,
          onPreviousMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
        );
      },
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({
    required this.overview,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final BudgetOverview overview;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _OverviewHeader(
            month: overview.month,
            balance: overview.remainingBalance,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _TotalsRow(overview: overview),
              const SizedBox(height: 20),
              _BreakdownCard(
                title: 'Income Overview',
                color: Colors.green,
                items: overview.incomeBreakdown,
                total: overview.income,
              ),
              const SizedBox(height: 16),
              _BreakdownCard(
                title: 'Expense Overview',
                color: Colors.deepOrange,
                items: overview.expenseBreakdown,
                total: overview.expenses,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.month,
    required this.balance,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final double balance;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  _months[month.month - 1],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Remaining Balance',
            style: TextStyle(color: Colors.white, fontSize: 21),
          ),
          const SizedBox(height: 14),
          Text(
            '₹ ${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.expand_more, color: Colors.white),
            label: const Text(
              'All Accounts',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.overview});

  final BudgetOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            title: 'Income',
            amount: overview.income,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TotalCard(
            title: 'Expenses',
            amount: overview.expenses,
            color: Colors.deepOrange,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '₹ ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.title,
    required this.color,
    required this.items,
    required this.total,
  });

  final String title;
  final Color color;
  final List<BudgetBreakdown> items;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final item in items)
              _BreakdownRow(item: item, total: total, color: color),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.item,
    required this.total,
    required this.color,
  });

  final BudgetBreakdown item;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (item.amount / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.name, style: const TextStyle(fontSize: 16)),
              ),
              Text(
                '₹ ${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: Colors.black12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

const _months = [
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
