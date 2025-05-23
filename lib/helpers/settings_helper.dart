import 'package:flutter/widgets.dart';
import 'package:saint_mobile/models/company_settings.dart';
import 'package:saint_mobile/services/database_service.dart';
import 'package:sqflite/sql.dart';

class SettingsHelper {
  final DatabaseService _db = DatabaseService();
  static const String _companyConfigTable = "company_config";

  Future<bool> isInitialSetupDone() async {
    var results = await _db.query(
      DatabaseService.settingsTable,
      where: 'key = ?',
      whereArgs: ['admin_password'],
    );
    return results.isNotEmpty;
  }

  Future<void> setInitialPassword(String password) async {
    await _db.insert(
      DatabaseService.settingsTable,
      {
        'key': 'admin_password',
        'value': password,
      },
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _db.update(
      DatabaseService.settingsTable,
      {'value': newPassword},
      where: 'key = ?',
      whereArgs: ['admin_password'],
    );
  }

  Future<String?> getSetting(String key) async {
    var results = await _db.query(
      DatabaseService.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  Future<void> setSetting(String key, String value) async {
    // Check if setting already exists
    var results = await _db.query(
      DatabaseService.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) {
      // Insert new setting
      await _db.insert(
        DatabaseService.settingsTable,
        {
          'key': key,
          'value': value,
        },
      );
    } else {
      // Update existing setting
      await _db.update(
        DatabaseService.settingsTable,
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  Future<void> deleteSetting(String key) async {
    await _db.delete(
      DatabaseService.settingsTable,
      'key = ?',
      [key],
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    var results = await _db.query(DatabaseService.settingsTable);

    Map<String, String> settings = {};
    for (var row in results) {
      settings[row['key'] as String] = row['value'] as String;
    }

    return settings;
  }

  Future<List<String>> getLogs({String? action, String? date}) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (action != null) {
      whereClause += 'action = ?';
      whereArgs.add(action);
    }

    if (date != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';

      whereClause += 'timestamp LIKE ?';
      whereArgs.add('$date%');
    }

    List<Map<String, dynamic>> logData = await _db.query(
      'logs',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return logData.map((log) {
      return "${log['action']} - ${log['table_name']} at ${log['timestamp']}";
    }).toList();
  }

  Future<void> saveCompanySettings(CompanySettings settings) async {
    debugPrint(
        "[SettingsHelper] Guardando CompanySettings en la base de datos...");

    final db = await _db.database;
    await db.insert(
      _companyConfigTable,
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint(
        "[SettingsHelper] CompanySettings guardados: ${settings.toMap()}");
  }

  Future<CompanySettings?> getCompanySettings() async {
    debugPrint("[SettingsHelper] Leyendo datos de CompanySettings...");

    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _companyConfigTable,
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      debugPrint("[SettingsHelper] CompanySettings encontrados: ${maps.first}");
      return CompanySettings.fromMap(maps.first);
    }
    debugPrint("[SettingsHelper] No se encontro data.");
    return null;
  }
}
