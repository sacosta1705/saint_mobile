import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';

class SettingsViewmodel extends ChangeNotifier {
  final ApiService _apiService;
  final SettingsHelper _settingsHelper;

  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String? _companyName;
  String? _errorMessage;
  List<String> _logs = [];

  List<String> get logs => _logs;
  bool get isLoadingLogs => _isLoadingLogs;

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
  String? _terminal;

  String? _defaultCustomerCode;
  String? _defaultSellerCode;
  String? _defaultWarehouseCode;

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
  String? get terminal => _terminal;

  String? get defaultCustomerCode => _defaultCustomerCode;
  String? get defaultSellerCode => _defaultSellerCode;
  String? get defaultWarehouseCode => _defaultWarehouseCode;

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

  void setDefaultCustomer(String customer, {String? code}) {
    _defaultCustomer = customer;
    if (code != null) {
      _defaultCustomerCode = code;
    }
    notifyListeners();
  }

  void setDefaultSeller(String seller, {String? code}) {
    _defaultSeller = seller;
    if (code != null) {
      _defaultSellerCode = code;
    }
    notifyListeners();
  }

  void setDefaultWarehouse(String warehouse, {String? code}) {
    _defaultWarehouse = warehouse;
    if (code != null) {
      _defaultWarehouseCode = code;
    }
    notifyListeners();
  }

  void setTerminalName(String terminal) {
    _terminal = terminal;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    _setLoading(true);

    // Load server URL
    _serverUrl = await _settingsHelper.getSetting('server_url');
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      _apiService.setBaseUrl(_serverUrl!);
    }

    _terminal = await _settingsHelper.getSetting('terminal');
    if (_terminal != null && _terminal!.isNotEmpty) {
      _apiService.setTerminalName(_terminal!);
    }

    // Load default values
    _defaultCustomer = await _settingsHelper.getSetting('default_customer');
    _defaultSeller = await _settingsHelper.getSetting('default_seller');
    _defaultWarehouse = await _settingsHelper.getSetting('default_warehouse');

    // Load default codes
    _defaultCustomerCode =
        await _settingsHelper.getSetting('default_customer_code');
    _defaultSellerCode =
        await _settingsHelper.getSetting('default_seller_code');
    _defaultWarehouseCode =
        await _settingsHelper.getSetting('default_warehouse_code');

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

  Future<List<Map<String, dynamic>>> fetchData(String type) async {
    final endpoint = {
      'Cliente': 'customers?activo=1',
      'Vendedor': 'sellers?activo=1',
      'Depósito': 'warehouses?activo=1',
    }[type];

    if (endpoint == null) return [];

    try {
      final response = await _apiService.get(endpoint);
      return List<Map<String, dynamic>>.from(
        response.map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    } catch (e) {
      debugPrint("Error fetching $type: $e");
      return [];
    }
  }

  Future<bool> saveSettings() async {
    _setLoading(true);

    try {
      // Save server URL
      if (_serverUrl != null) {
        await _settingsHelper.setSetting('server_url', _serverUrl!);
      }

      if (_terminal != null) {
        await _settingsHelper.setSetting('terminal', _terminal!);
        _apiService.setTerminalName(_terminal!);
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

      // Save default codes
      if (_defaultCustomerCode != null) {
        await _settingsHelper.setSetting(
            'default_customer_code', _defaultCustomerCode!);
      }

      if (_defaultSellerCode != null) {
        await _settingsHelper.setSetting(
            'default_seller_code', _defaultSellerCode!);
      }

      if (_defaultWarehouseCode != null) {
        await _settingsHelper.setSetting(
            'default_warehouse_code', _defaultWarehouseCode!);
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

  Future<void> fetchLogs({String? action, String? date}) async {
    _isLoadingLogs = true;
    notifyListeners();

    try {
      _logs = await _settingsHelper.getLogs(action: action, date: date);
    } catch (e) {
      debugPrint("Error al leer auditoria: ${e.toString()}");
    }

    _isLoadingLogs = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
