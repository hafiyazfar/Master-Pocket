import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_pocket/providers/transactions_provider.dart'; // for appDbProvider

class BudgetNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final db = ref.watch(appDbProvider);
    return db.getMonthlyBudget();
  }

  Future<void> set(double value) async {
    final db = ref.read(appDbProvider);
    await db.setMonthlyBudget(value);
    state = AsyncData(value);
  }
}

final monthlyBudgetProvider =
AsyncNotifierProvider<BudgetNotifier, double>(BudgetNotifier.new);