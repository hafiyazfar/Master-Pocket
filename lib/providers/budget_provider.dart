import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_pocket/providers/transactions_provider.dart'; // for appDbProvider

class BudgetNotifier extends AsyncNotifier<double> {
  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  Future<double> build() async {
    final db = ref.watch(appDbProvider);
    return db.getMonthlyBudget(month: _currentMonth);
  }

  Future<void> set(double value) async {
    final db = ref.read(appDbProvider);
    await db.setMonthlyBudget(value, month: _currentMonth);
    state = AsyncData(value);
  }
}

final monthlyBudgetProvider = AsyncNotifierProvider<BudgetNotifier, double>(
  BudgetNotifier.new,
);
