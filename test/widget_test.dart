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
      repeatEveryMonths: 1,
    );

    final rows = await database.select(database.transactions).get();
    expect(rows.length, 3);
    expect(rows.map((row) => row.transactionDate).toList(), [
      DateTime(2026, 1, 15),
      DateTime(2026, 2, 15),
      DateTime(2026, 3, 15),
    ]);
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
