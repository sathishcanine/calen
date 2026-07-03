import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Bundled Chennai 2026 SQLite (365 daily + 12 monthly rows) — copied on first launch.
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const _assetPath = 'assets/data/calendar.db';
  static const _dbFileName = 'calendar.db';

  Database? _db;

  Future<void> ensureInitialized() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, _dbFileName);
    final file = File(dbPath);

    if (!await file.exists()) {
      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }

    _db = await openDatabase(dbPath, readOnly: true);
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('LocalDatabase not initialized — call ensureInitialized() first');
    }
    return database;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
