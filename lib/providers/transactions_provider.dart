import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:master_pocket/database/app_db.dart';
import 'package:master_pocket/data/tx_repository.dart';
import 'package:master_pocket/models/transactions.dart';

final appDbProvider = Provider<AppDb>((ref) => AppDb());

final txRepoProvider = Provider<TxRepository>((ref) {
  return TxRepository(ref.watch(appDbProvider));
});

class TransactionsNotifier extends AsyncNotifier<List<Tx>> {
  @override
  Future<List<Tx>> build() async {
    return ref.watch(txRepoProvider).fetchAll();
  }

  Future<void> addTx(Tx tx) async {
    final repo = ref.read(txRepoProvider);
    await repo.add(tx);
    state = AsyncData(await repo.fetchAll());
  }

  Future<void> deleteTx(String id) async {
    final repo = ref.read(txRepoProvider);
    await repo.remove(id);
    state = AsyncData(await repo.fetchAll());
  }
}

final transactionsProvider =
AsyncNotifierProvider<TransactionsNotifier, List<Tx>>(TransactionsNotifier.new);

final monthlyExpenseTotalProvider = Provider<double>((ref) {
  final asyncTxs = ref.watch(transactionsProvider);

  return asyncTxs.when(
    data: (txs) {
      final now = DateTime.now();
      return txs
          .where((t) =>
      t.type == TxType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month)
          .fold(0.0, (sum, t) => sum + t.amount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});