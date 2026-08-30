import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'budget_database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class BudgetDatabase extends _$BudgetDatabase {
  BudgetDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'budgetflow'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) await _seedDefaults();
      if (from < 5) {
        await m.customStatement(
          'ALTER TABLE accounts ADD COLUMN icon_code_point INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
  );

  Future<void> _seedDefaults() async {
    final existingAccount = await select(accounts).getSingleOrNull();
    final accountId =
        existingAccount?.id ??
        await customInsert(
          "INSERT INTO accounts (name) VALUES ('Default Account')",
          variables: [],
          updates: {accounts},
        );
    for (final category in _defaultCategories) {
      final exists =
          await (select(categories)..where(
            (item) => item.name.equals(category.name),
          )).getSingleOrNull();
      if (exists == null) {
        await customInsert(
          'INSERT INTO categories (name, icon_code_point) VALUES (?, ?)',
          variables: [
            Variable(category.name),
            Variable(category.iconCodePoint),
          ],
          updates: {categories},
        );
      }
    }
  }

  Stream<List<Category>> watchCategories() => select(categories).watch();

  Stream<List<Account>> watchAccounts() => select(accounts).watch();

  Future<List<AccountSummary>> loadAccounts() async {
    final rows = await customSelect(
      'SELECT id, name, currency, opening_balance_cents, COALESCE(icon_code_point, 0) AS icon_code_point FROM accounts ORDER BY id',
      readsFrom: {accounts},
    ).get();
    return rows
        .map(
          (row) => AccountSummary(
            id: row.data['id'] as int,
            name: row.data['name'] as String,
            currency: row.data['currency'] as String? ?? 'INR',
            openingBalanceCents: row.data['opening_balance_cents'] as int? ?? 0,
            iconCodePoint: row.data['icon_code_point'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Stream<List<AccountSummary>> watchAccountsWithIcons() {
    return customSelect(
      'SELECT id, name, currency, opening_balance_cents, COALESCE(icon_code_point, 0) AS icon_code_point FROM accounts ORDER BY id',
      readsFrom: {accounts},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => AccountSummary(
              id: row.data['id'] as int,
              name: row.data['name'] as String,
              currency: row.data['currency'] as String? ?? 'INR',
              openingBalanceCents: row.data['opening_balance_cents'] as int? ?? 0,
              iconCodePoint: row.data['icon_code_point'] as int? ?? 0,
            ),
          )
          .toList(),
    );
  }

  Future<int> defaultAccountId() async =>
      (await select(accounts).getSingle()).id;

  Future<int?> categoryIdForName(String name) async {
    final row =
        await (select(categories)
          ..where((item) => item.name.equals(name))).getSingleOrNull();
    return row?.id;
  }

  Stream<List<TransactionWithDetails>> watchTransactions() {
    final query = select(transactions).join([
      leftOuterJoin(
        categories,
        categories.id.equalsExp(transactions.categoryId),
      ),
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ])..orderBy([OrderingTerm.desc(transactions.transactionDate)]);
    return query.watch().map(
      (rows) =>
          rows
              .map(
                (row) => TransactionWithDetails(
                  transaction: row.readTable(transactions),
                  category: row.readTableOrNull(categories),
                  account: row.readTable(accounts),
                ),
              )
              .toList(),
    );
  }

  Stream<BudgetOverview> watchOverview(DateTime month, {int? accountId}) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final query =
        select(transactions).join([
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
          ])
          ..where(transactions.transactionDate.isBetweenValues(start, end));
    if (accountId != null) {
      query.where(transactions.accountId.equals(accountId));
    }
    query.orderBy([OrderingTerm.desc(transactions.transactionDate)]);
    return query.watch().map((rows) {
      final amounts = rows.map(
        (row) => row.readTable(transactions).amountCents,
      );
      final income = amounts
          .where((amount) => amount > 0)
          .fold(0, (a, b) => a + b);
      final expenses = amounts
          .where((amount) => amount < 0)
          .fold(0, (a, b) => a + b.abs());
      return BudgetOverview(
        month: month,
        income: income / 100,
        expenses: expenses / 100,
        incomeBreakdown: _groupBreakdown(rows, positive: true),
        expenseBreakdown: _groupBreakdown(rows, positive: false),
      );
    });
  }

  Future<BudgetOverview> loadOverview(DateTime month, {int? accountId}) =>
      watchOverview(month, accountId: accountId).first;

  List<BudgetBreakdown> _groupBreakdown(
    List<TypedResult> rows, {
    required bool positive,
  }) {
    final totals = <String, BudgetBreakdown>{};
    for (final row in rows) {
      final item = row.readTable(transactions);
      if (positive != (item.amountCents > 0)) continue;
      final category = row.readTableOrNull(categories);
      final name = category?.name ?? 'General';
      final icon = category?.iconCodePoint ?? 0;
      final current = totals[name];
      totals[name] = BudgetBreakdown(
        name: name,
        amount: (current?.amount ?? 0) + item.amountCents.abs() / 100,
        iconCodePoint: icon,
      );
    }
    return totals.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Future<int> addAccount({
    required String name,
    String currency = 'INR',
    int openingBalanceCents = 0,
    int iconCodePoint = 0xe7fe,
  }) => customInsert(
    'INSERT INTO accounts (name, currency, opening_balance_cents, icon_code_point) VALUES (?, ?, ?, ?)',
    variables: [
      Variable(name),
      Variable(currency),
      Variable(openingBalanceCents),
      Variable(iconCodePoint),
    ],
    updates: {accounts},
  );

  Future<int> addCategory({
    required String name,
    required int iconCodePoint,
  }) async {
    final normalizedName = name.trim();
    final existing =
        await (select(
          categories,
        )..where((item) => item.name.equals(normalizedName))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: normalizedName,
        iconCodePoint: iconCodePoint,
        isDefault: const Value(false),
      ),
    );
  }

  Future<int> addTransaction({
    required int accountId,
    int? categoryId,
    required int amountCents,
    String? note,
    required DateTime date,
    DateTime? repeatUntil,
    int repeatEvery = 1,
    String repeatUnit = 'month',
  }) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final normalizedRepeatEvery = repeatEvery <= 0 ? 1 : repeatEvery;
    final normalizedRepeatUnit = repeatUnit.toLowerCase();
    final endDate =
        repeatUntil == null
            ? startDate
            : DateTime(repeatUntil.year, repeatUntil.month, repeatUntil.day);

    var nextDate = startDate;
    var insertedId = 0;

    while (!nextDate.isAfter(endDate)) {
      insertedId = await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: accountId,
          categoryId: Value(categoryId),
          amountCents: amountCents,
          note: Value(note),
          transactionDate: nextDate,
        ),
      );

      if (repeatUntil == null) break;
      nextDate = _advanceDate(
        nextDate,
        normalizedRepeatEvery,
        normalizedRepeatUnit,
      );
      if (nextDate.isBefore(startDate)) break;
    }

    return insertedId;
  }

  DateTime _advanceDate(DateTime date, int repeatEvery, String repeatUnit) {
    switch (repeatUnit) {
      case 'day':
        return date.add(Duration(days: repeatEvery));
      case 'week':
        return date.add(Duration(days: repeatEvery * 7));
      case 'month':
        return _addMonths(date, repeatEvery);
      default:
        return date.add(Duration(days: repeatEvery));
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    final day = date.day;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final safeDay = day > daysInMonth ? daysInMonth : day;
    return DateTime(year, month, safeDay);
  }
}

class AccountSummary {
  const AccountSummary({
    required this.id,
    required this.name,
    required this.currency,
    required this.openingBalanceCents,
    required this.iconCodePoint,
  });

  final int id;
  final String name;
  final String currency;
  final int openingBalanceCents;
  final int iconCodePoint;
}

class TransactionWithDetails {
  const TransactionWithDetails({
    required this.transaction,
    required this.category,
    required this.account,
  });

  final Transaction transaction;
  final Category? category;
  final Account account;
}

class BudgetOverview {
  const BudgetOverview({
    required this.month,
    required this.income,
    required this.expenses,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
  });

  final DateTime month;
  final double income;
  final double expenses;
  final List<BudgetBreakdown> incomeBreakdown;
  final List<BudgetBreakdown> expenseBreakdown;
  double get remainingBalance => income - expenses;
}

class BudgetBreakdown {
  const BudgetBreakdown({
    required this.name,
    required this.amount,
    required this.iconCodePoint,
  });

  final String name;
  final double amount;
  final int iconCodePoint;
}

class _DefaultCategory {
  const _DefaultCategory(this.name, this.iconCodePoint);

  final String name;
  final int iconCodePoint;
}

const _defaultCategories = [
  _DefaultCategory('Clothes', 0xe3b8),
  _DefaultCategory('Gifts', 0xe8f6),
  _DefaultCategory('Holidays', 0xe539),
  _DefaultCategory('Eating Out', 0xe56c),
  _DefaultCategory('Sports', 0xe52f),
  _DefaultCategory('Entertainment', 0xe02c),
  _DefaultCategory('General', 0xe88a),
  _DefaultCategory('Kids', 0xe7fb),
  _DefaultCategory('Travel', 0xe539),
  _DefaultCategory('Shopping', 0xe8cc),
  _DefaultCategory('Salary', 0xe7fe),
  _DefaultCategory('Income', 0xe7fe),
];
