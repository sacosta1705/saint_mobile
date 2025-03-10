import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _dbName = "saint_mobile.db";
  static const String settingsTable = "settings";
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onDowngrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      String schema = await rootBundle.loadString('assets/sql/schema.sql');
      debugPrint("Loaded schema: $schema");
      List<String> queries = schema.split(';');
      for (String query in queries) {
        String trimmedQuery = query.trim();
        if (trimmedQuery.isNotEmpty) {
          debugPrint("Executing query: $trimmedQuery");
          await db.execute(trimmedQuery);
        }
      }

      var tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      debugPrint('Tables created: $tables');
    } catch (e) {
      debugPrint('Error al crear la base de datos.');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {}
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    int id = await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    String formattedData = const JsonEncoder.withIndent('    ').convert(row);
    await log('INSERTAR', table,
        newData: formattedData, recordId: id.toString());
    return id;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    Database db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<int> update(String table, Map<String, dynamic> row,
      {String? where, List<dynamic>? whereArgs}) async {
    Database db = await database;

    List<Map<String, dynamic>> oldRecords =
        await db.query(table, where: where, whereArgs: whereArgs);

    int count = await db.update(table, row, where: where, whereArgs: whereArgs);

    if (oldRecords.isNotEmpty) {
      String oldDataFormatted =
          const JsonEncoder.withIndent('    ').convert(oldRecords);
      String newDataFormatted =
          const JsonEncoder.withIndent('    ').convert(row);

      String recordsId = oldRecords
          .map((record) =>
              record.containsKey('id') ? record['id'].toString() : '')
          .join(', ');

      await log(
        'ACTUALIZACION',
        table,
        oldData: oldDataFormatted,
        newData: newDataFormatted,
        recordId: recordsId,
      );
    }

    return count;
  }

  Future<int> delete(
      String table, String? where, List<dynamic>? whereArgs) async {
    Database db = await database;

    List<Map<String, dynamic>> deletedRecords =
        await db.query(table, where: where, whereArgs: whereArgs);

    int count = await db.delete(table, where: where, whereArgs: whereArgs);

    if (deletedRecords.isNotEmpty) {
      await log("ELIMINADO", table, oldData: deletedRecords.toString());
    }

    return count;
  }

  Future<void> log(String action, String table,
      {String? oldData,
      String? newData,
      String? recordId,
      String? extra}) async {
    final db = await database;
    await db.insert('logs', {
      'action': action,
      'table_name': table,
      'timestamp': DateTime.now().toIso8601String(),
      'old_data': oldData,
      'new_data': newData,
      'record_id': recordId,
      'extra_info': extra,
    });
  }

  Future<List<Map<String, dynamic>>> getLogs(
      {String? action, String? date, String? table}) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    if (action != null) {
      whereClause += 'action = ?';
      whereArgs.add(action);
    }

    if (date != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp LIKE ?';
      whereArgs.add('$date%');
    }

    if (table != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'table_name = ?';
      whereArgs.add(table);
    }

    return await db.query(
      'logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );
  }
}
