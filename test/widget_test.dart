import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:master_pocket/main.dart';
import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/pages/add_transaction_page.dart';
import 'package:master_pocket/providers/budget_provider.dart';
import 'package:master_pocket/providers/transactions_provider.dart';

class _FakeTransactionsNotifier extends TransactionsNotifier {
  @override
  Future<List<Tx>> build() async {
    final now = DateTime.now();

    return [
      Tx(
        id: 'expense-1',
        title: 'Lunch',
        amount: 12.5,
        date: now,
        type: TxType.expense,
        category: 'Food',
      ),
      Tx(
        id: 'income-1',
        title: 'Salary',
        amount: 2500,
        date: now,
        type: TxType.income,
        category: 'Salary',
      ),
    ];
  }
}

class _FakeBudgetNotifier extends BudgetNotifier {
  @override
  Future<double> build() async => 1000;
}

void main() {
  testWidgets('home page renders budget overview without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
          monthlyBudgetProvider.overrideWith(_FakeBudgetNotifier.new),
        ],
        child: const MaterialApp(home: MyHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Master Pocket'), findsOneWidget);
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.text('Available RM 987.50'), findsOneWidget);

    await tester.tap(find.byType(PieChart), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('add transaction form renders primary fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddTransactionPage())),
    );

    expect(find.text('New transaction'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
  });
}
