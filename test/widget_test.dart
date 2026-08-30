import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:budgetflow/database/budget_database.dart';

import 'package:budgetflow/main.dart';

void main() {
  testWidgets('bottom navigation switches between budget tabs', (
    WidgetTester tester,
  ) async {
    final database = BudgetDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });
    await tester.pumpWidget(MyApp(database: database));
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    final destinations = <(String, int)>[
      ('Transactions', 1),
      ('Categories', 2),
      ('Settings', 3),
      ('Home', 0),
    ];
    for (final (destination, index) in destinations) {
      await tester.tap(find.text(destination).last);
      await tester.pump();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
    }

    expect(find.byType(NavigationBar), findsOneWidget);
  });

  test('creates repeated monthly transactions until the selected end date', () async {
    final database = BudgetDatabase(NativeDatabase.memory());
    addTearDown(() => database.close());

    final categoryId = await database.addCategory(
      name: 'Bills',
      iconCodePoint: Icons.receipt.codePoint,
    );

    await database.addTransaction(
      accountId: await database.defaultAccountId(),
      categoryId: categoryId,
      amountCents: -2500,
      note: 'Rent',
      date: DateTime(2026, 1, 15),
      repeatUntil: DateTime(2026, 3, 15),
      repeatEvery: 1,
      repeatUnit: 'month',
    );

    final rows = await database.select(database.transactions).get();
    expect(rows.length, 3);
    expect(rows.map((row) => row.transactionDate).toList(), [
      DateTime(2026, 1, 15),
      DateTime(2026, 2, 15),
      DateTime(2026, 3, 15),
    ]);
  });

  testWidgets('changes month and filters transactions by selected month', (
    WidgetTester tester,
  ) async {
    final database = BudgetDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    });

    final accountId = await database.defaultAccountId();
    await database.addTransaction(
      accountId: accountId,
      categoryId: null,
      amountCents: -1500,
      note: 'August expense',
      date: DateTime(2026, 8, 10),
    );
    await database.addTransaction(
      accountId: accountId,
      categoryId: null,
      amountCents: -3000,
      note: 'September expense',
      date: DateTime(2026, 9, 12),
    );

    await tester.pumpWidget(MyApp(database: database));
    await tester.pumpAndSettle();

    expect(find.text('August'), findsOneWidget);
    expect(find.text('August expense'), findsOneWidget);
    expect(find.text('September expense'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Sep'), findsOneWidget);
    expect(find.text('September expense'), findsOneWidget);
    expect(find.text('August expense'), findsNothing);
  });

  test('seeds default income categories for income transactions', () async {
    final database = BudgetDatabase(NativeDatabase.memory());
    addTearDown(() => database.close());

    final categories = await database.watchCategories().first;
    final names = categories.map((category) => category.name).toSet();

    expect(names.contains('Salary'), isTrue);
    expect(names.contains('Income'), isTrue);
  });

  testWidgets('adds a category from the categories list', (
    WidgetTester tester,
  ) async {
    final database = BudgetDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    });
    await tester.pumpWidget(MyApp(database: database));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Categories').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Clothes'), findsOneWidget);

    await tester.tap(find.text('Add New Category'));
    await tester.pump();
    expect(find.text('New Category'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Coffee');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.text('Coffee'),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
  });
}
