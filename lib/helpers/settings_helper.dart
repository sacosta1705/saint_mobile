import 'package:saint_mobile/services/database_service.dart';

class SettingsHelper {
  final DatabaseService _db = DatabaseService();

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

  // Delete a setting
  Future<void> deleteSetting(String key) async {
    await _db.delete(
      DatabaseService.settingsTable,
      'key = ?',
      [key],
    );
  }

  // Get all settings
  Future<Map<String, String>> getAllSettings() async {
    var results = await _db.query(DatabaseService.settingsTable);

    Map<String, String> settings = {};
    for (var row in results) {
      settings[row['key'] as String] = row['value'] as String;
    }

    return settings;
  }
}
