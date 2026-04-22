import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'transaction_model.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        category TEXT,
        amount REAL,
        type TEXT,
        date TEXT
      )
    ''');
  }

  // ================= ADD =================

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    return await db.insert(
      'transactions',
      t.toMap(),
    );
  }

  // ================= READ =================

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;

    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return maps
        .map((e) => TransactionModel.fromMap(e))
        .toList();
  }

  // ================= UPDATE =================

  Future<int> updateTransaction(
      TransactionModel t) async {
    final db = await database;

    return await db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  // ================= DELETE =================

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}