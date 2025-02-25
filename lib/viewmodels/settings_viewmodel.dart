import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';

class SettingsViewmodel extends ChangeNotifier {
  final ApiService _apiService;
  final SettingsHelper _settingsHelper;

  bool _isLoading = false;
  String? _companyName;
  String? _errorMessage;

  final Map<String, bool> _moduleAccess = {
    'billing': false,
    'budget': false,
    'delivery_note': false,
    'orders': false
  };

  String? _defaultCustomer;
  String? _defaultSeller;
  String? _defaultWarehouse;
  String? _serverUrl;

  SettingsViewmodel({
    required ApiService apiService,
    required SettingsHelper settingsHelper,
  })  : _apiService = apiService,
        _settingsHelper = settingsHelper {
    _loadSettings();
  }

  bool get isLoading => _isLoading;
  String? get companyName => _companyName;
  String? get errorMessage => _errorMessage;
  String? get serverUrl => _serverUrl;
  String? get defaultClient => _defaultCustomer;
  String? get defaultSeller => _defaultSeller;
  String? get defaultWarehouse => _defaultWarehouse;

  bool getModuleAccess(String module) {
    return _moduleAccess[module] ?? false;
  }

  void setModuleAccess(String module, bool value) {
    _moduleAccess[module] = value;
    notifyListeners();
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  void setDefaultCustomer(String customer) {
    _defaultCustomer = customer;
    notifyListeners();
  }

  void setDefaultSeller(String seller) {
    _defaultSeller = seller;
    notifyListeners();
  }

  void setDefaultWarehouse(String warehouse) {
    _defaultWarehouse = warehouse;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    _setLoading(true);

    // Load server URL
    _serverUrl = await _settingsHelper.getSetting('server_url');
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      _apiService.setBaseUrl(_serverUrl!);
    }

    // Load default values
    _defaultCustomer = await _settingsHelper.getSetting('default_customer');
    _defaultSeller = await _settingsHelper.getSetting('default_seller');
    _defaultWarehouse = await _settingsHelper.getSetting('default_warehouse');

    // Load module access settings
    for (var module in _moduleAccess.keys) {
      final value = await _settingsHelper.getSetting('module_$module');
      if (value != null) {
        _moduleAccess[module] = value == 'true';
      }
    }

    // Get company name from stored settings if available
    _companyName = await _settingsHelper.getSetting('company_name');

    _setLoading(false);
  }

  Future<bool> testUrlConnection(
      String url, String username, String password) async {
    if (url.isEmpty) {
      _errorMessage = "Por favor, ingrese el URL del servidor web.";
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      // Actualizar el servicio API con la nueva URL
      _apiService.setBaseUrl(url);

      // Intentar autenticarse con las credenciales proporcionadas
      final response = await _apiService.login(username, password);
      _companyName = response['enterprise'];
      _serverUrl = url;

      // Guardar la URL y el nombre de la empresa en la configuración
      await _settingsHelper.setSetting('server_url', url);
      await _settingsHelper.setSetting('company_name', _companyName!);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Error de conexión: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> saveSettings() async {
    _setLoading(true);

    try {
      // Save server URL
      if (_serverUrl != null) {
        await _settingsHelper.setSetting('server_url', _serverUrl!);
      }

      // Save company name if available
      if (_companyName != null) {
        await _settingsHelper.setSetting('company_name', _companyName!);
      }

      // Save default values
      if (_defaultCustomer != null) {
        await _settingsHelper.setSetting('default_customer', _defaultCustomer!);
      }

      if (_defaultSeller != null) {
        await _settingsHelper.setSetting('default_seller', _defaultSeller!);
      }

      if (_defaultWarehouse != null) {
        await _settingsHelper.setSetting(
            'default_warehouse', _defaultWarehouse!);
      }

      // Save module access settings
      for (var entry in _moduleAccess.entries) {
        await _settingsHelper.setSetting(
            'module_${entry.key}', entry.value.toString());
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Error al guardar: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
