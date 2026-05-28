enum TxType { income, expense }

class Tx {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TxType type;
  final String category;

  const Tx({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });
}