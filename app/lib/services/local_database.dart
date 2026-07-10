import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Bundled Chennai 2026 SQLite (365 daily + 12 monthly rows).
///
/// Copied from assets on first launch and again whenever [bundledDbVersion]
/// increases (so Play Store / App Store updates ship fresh panchang data).
class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const _assetPath = 'assets/data/calendar.db';
  static const _dbFileName = 'calendar.db';
  static const _prefsKey = 'calendar_db_version';

  /// Bump when assets/data/calendar.db changes (nalla neram, rahu, etc.).
  static const bundledDbVersion = 2;

  Database? _db;

  Future<void> ensureInitialized() async {
    if (_db != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, _dbFileName);
    final file = File(dbPath);
    final prefs = await SharedPreferences.getInstance();
    final installedVersion = prefs.getInt(_prefsKey) ?? 0;

    if (!await file.exists() || installedVersion < bundledDbVersion) {
      await _db?.close();
      _db = null;
      if (await file.exists()) {
        await file.delete();
      }
      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await prefs.setInt(_prefsKey, bundledDbVersion);
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
