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
    await _db.insert(
      DatabaseService.settingsTable,
      {
        'key': key,
        'value': value,
      },
    );
  }
}
