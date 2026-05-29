import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static const _dbName = 'pocket.sqlite';
  static const _dbVersion = 2;

  static const txTable = 'transactions';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);

    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $txTable (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  category TEXT NOT NULL,
  date INTEGER NOT NULL
)
''');

        await db.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value REAL NOT NULL
)
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // If upgrading from v1 -> v2, add settings table
        if (oldVersion < 2) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value REAL NOT NULL
)
''');
        }
      },
    );

    _db = db;
    return db;
  }

  // ---- transactions ----
  Future<void> insertTx(Map<String, Object?> row) async {
    final db = await database;
    await db.insert(txTable, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getAllTx() async {
    final db = await database;
    return db.query(txTable, orderBy: 'date DESC');
  }

  Future<void> deleteTx(String id) async {
    final db = await database;
    await db.delete(txTable, where: 'id = ?', whereArgs: [id]);
  }

  // ---- budget (settings) ----
  Future<double> getMonthlyBudget({DateTime? month}) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_monthlyBudgetKey(month ?? DateTime.now())],
      limit: 1,
    );
    if (rows.isEmpty) return 0.0;
    return (rows.first['value'] as num).toDouble();
  }

  Future<void> setMonthlyBudget(double value, {DateTime? month}) async {
    final db = await database;
    await db.insert('settings', {
      'key': _monthlyBudgetKey(month ?? DateTime.now()),
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _monthlyBudgetKey(DateTime month) {
    final monthPart = month.month.toString().padLeft(2, '0');
    return 'monthly_budget_${month.year}_$monthPart';
  }
}
