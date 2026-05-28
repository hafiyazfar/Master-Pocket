import 'package:master_pocket/database/app_db.dart';
import 'package:master_pocket/models/transactions.dart';

class TxRepository {
  final AppDb db;
  TxRepository(this.db);

  Future<List<Tx>> fetchAll() async {
    final rows = await db.getAllTx();
    return rows.map(_fromRow).toList();
  }

  Future<void> add(Tx tx) async {
    await db.insertTx({
      'id': tx.id,
      'title': tx.title,
      'amount': tx.amount,
      'type': tx.type.name, // "income"/"expense"
      'category': tx.category,
      'date': tx.date.millisecondsSinceEpoch,
    });
  }

  Future<void> remove(String id) => db.deleteTx(id);

  Tx _fromRow(Map<String, Object?> r) {
    return Tx(
      id: r['id'] as String,
      title: r['title'] as String,
      amount: (r['amount'] as num).toDouble(),
      type: TxType.values.byName(r['type'] as String),
      category: r['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
    );
  }
}