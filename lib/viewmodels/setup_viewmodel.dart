import 'package:flutter/foundation.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/models/settings.dart';

class SetupViewmodel extends ChangeNotifier {
  final SettingsHelper _settingsHelper;
  bool _isLoading = false;
  String? _errorMessage;
  AppSettings _settings = AppSettings();

  SetupViewmodel({required SettingsHelper settingsHelper})
      : _settingsHelper = settingsHelper {
    _loadSettings();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSetupComplete => _settings.isSetupComplete;

  Future<void> _loadSettings() async {
    _setLoading(true);

    try {
      final isSetupDone = await _settingsHelper.isInitialSetupDone();
      final adminPassword = await _settingsHelper.getSetting('admin_password');

      // Debug: Print database values
      debugPrint('isSetupDone: $isSetupDone');
      debugPrint('adminPassword: $adminPassword');

      _settings = AppSettings(
        isSetupComplete: isSetupDone,
        adminPassword: adminPassword,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> setInitialPassword(String password) async {
    debugPrint('Setting initial password...');
    _setLoading(true);
    _errorMessage = null;

    try {
      await _settingsHelper.setInitialPassword(password);
      debugPrint('Password inserted into database.');

      _settings = _settings.copyWith(
        adminPassword: password,
        isSetupComplete: true,
      );

      await _loadSettings();
      debugPrint('Settings reloaded from database.');

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> validateAdminPassword(String password) async {
    _setLoading(true);

    try {
      final storedPassword = await _settingsHelper.getSetting('admin_password');
      final isValid = storedPassword == password;
      _setLoading(false);
      return isValid;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
