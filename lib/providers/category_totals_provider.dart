import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_pocket/models/transactions.dart';
import 'package:master_pocket/providers/transactions_provider.dart';

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final asyncTxs = ref.watch(transactionsProvider);

  return asyncTxs.when(
    data: (txs) {
      final now = DateTime.now();
      final map = <String, double>{};

      for (final t in txs) {
        final isThisMonth = t.date.year == now.year && t.date.month == now.month;
        if (!isThisMonth) continue;
        if (t.type != TxType.expense) continue;

        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }

      return map;
    },
    loading: () => <String, double>{},
    error: (_, __) => <String, double>{},
  );
});