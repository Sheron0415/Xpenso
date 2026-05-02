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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        category TEXT,
        amount REAL,
        type TEXT,
        date TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        limitAmount REAL,
        userId INTEGER,
        UNIQUE(category, userId),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password TEXT)');
      await db.execute('ALTER TABLE transactions ADD COLUMN userId INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT,
          limitAmount REAL,
          userId INTEGER,
          UNIQUE(category, userId),
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
    }
  }

  // User methods
  Future<int> register(String username, String password) async {
    final db = await database;
    try {
      return await db.insert('users', {'username': username, 'password': password});
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await database;
    final res = await db.query('users',
        where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update('users', {'password': newPassword},
        where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> updateUsername(int userId, String newUsername) async {
    final db = await database;
    try {
      return await db.update('users', {'username': newUsername},
          where: 'id = ?', whereArgs: [userId]);
    } catch (e) {
      return -1;
    }
  }

  Future<int> resetPassword(String username, String newPassword) async {
    final db = await database;
    final res = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (res.isEmpty) return 0;
    return await db.update('users', {'password': newPassword},
        where: 'username = ?', whereArgs: [username]);
  }

  // Budget methods
  Future<int> setBudget(int userId, String category, double limit) async {
    final db = await database;
    return await db.insert(
      'budgets',
      {'userId': userId, 'category': category, 'limitAmount': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBudgets(int userId) async {
    final db = await database;
    return await db.query('budgets', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> deleteBudget(int budgetId) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [budgetId]);
  }

  // Transaction methods
  Future<int> insertTransaction(TransactionModel t, int userId) async {
    final db = await database;
    var map = t.toMap();
    map['userId'] = userId;
    return await db.insert('transactions', map);
  }

  Future<List<TransactionModel>> getTransactions(int userId) async {
    final db = await database;
    final maps = await db.query('transactions',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'date DESC');
    return maps.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    return await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
