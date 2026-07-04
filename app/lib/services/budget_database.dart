import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/budget_defaults.dart';
import '../models/budget.dart';

/// Local SQLite store for budget transactions and categories.
class BudgetDatabase {
  BudgetDatabase._();

  static final BudgetDatabase instance = BudgetDatabase._();

  static const _dbFileName = 'budget.db';
  static const _dbVersion = 3;

  Database? _db;

  Future<void> ensureInitialized() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, _dbFileName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _syncDefaultCategories();
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('BudgetDatabase not initialized — call ensureInitialized() first');
    }
    return database;
  }

  Future<void> _onCreate(Database database, int version) async {
    await database.execute('''
      CREATE TABLE budget_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_income INTEGER NOT NULL DEFAULT 0,
        is_custom INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE budget_transactions (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES budget_categories(id)
      )
    ''');

    await database.execute(
      'CREATE INDEX idx_budget_tx_date ON budget_transactions(date)',
    );
    await database.execute(
      'CREATE INDEX idx_budget_tx_category ON budget_transactions(category_id)',
    );
  }

  Future<void> _onUpgrade(Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _syncDefaultCategoriesOnDb(database);
    }
    if (oldVersion < 3) {
      await _syncDefaultCategoriesOnDb(database);
    }
  }

  Future<void> _syncDefaultCategories() => _syncDefaultCategoriesOnDb(db);

  Future<void> _syncDefaultCategoriesOnDb(Database database) async {
    final defaults = BudgetDefaults.allCategories();
    final batch = database.batch();
    for (final category in defaults) {
      batch.insert(
        'budget_categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<BudgetCategory>> getCategories({bool? isIncome}) async {
    final where = isIncome == null ? '' : 'WHERE is_income = ${isIncome ? 1 : 0}';
    final rows = await db.rawQuery(
      'SELECT * FROM budget_categories $where ORDER BY sort_order ASC, name ASC',
    );
    return rows.map(BudgetCategory.fromMap).toList();
  }

  Future<BudgetCategory?> getCategoryById(String id) async {
    final rows = await db.query(
      'budget_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetCategory.fromMap(rows.first);
  }

  Future<void> insertCategory(BudgetCategory category) async {
    await db.insert('budget_categories', category.toMap());
  }

  Future<List<BudgetTransaction>> getTransactionsForMonth(int year, int month) async {
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'budget_transactions',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(BudgetTransaction.fromMap).toList();
  }

  Future<List<BudgetTransaction>> getTransactionsForYear(int year) async {
    final prefix = year.toString();
    final rows = await db.query(
      'budget_transactions',
      where: 'date LIKE ?',
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(BudgetTransaction.fromMap).toList();
  }

  Future<void> insertTransaction(BudgetTransaction transaction) async {
    await db.insert('budget_transactions', transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await db.delete('budget_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> deleteDatabaseFile() async {
    await close();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(join(dir.path, _dbFileName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
