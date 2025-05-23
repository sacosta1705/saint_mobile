import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saint_mobile/models/company_settings.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';

class SettingsViewmodel extends ChangeNotifier {
  final ApiService _apiService;
  final SettingsHelper _settingsHelper;

  bool _isLoading = false;
  bool _isLoadingLogs = false;
  String? _errorMessage;
  List<String> _logs = [];

  CompanySettings? _companySettings;

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
  // Getter para el nombre de la empresa, obtenido de _companySettings
  String? get companyName => _companySettings?.name;
  CompanySettings? get companySettings => _companySettings;
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
    debugPrint("[SettingsViewModel] Cargando configuraciones iniciales...");
    _setLoading(true);

    _serverUrl = await _settingsHelper.getSetting('server_url');
    if (_serverUrl != null && _serverUrl!.isNotEmpty) {
      _apiService.setBaseUrl(_serverUrl!);
      debugPrint(
          "[SettingsViewModel] URL del servidor cargada desde BD: $_serverUrl");
    } else {
      debugPrint("[SettingsViewModel] URL del servidor no encontrada en BD.");
    }

    _terminal = await _settingsHelper.getSetting('terminal');
    if (_terminal != null && _terminal!.isNotEmpty) {
      _apiService.setTerminalName(_terminal!);
      debugPrint("[SettingsViewModel] Terminal cargado desde BD: $_terminal");
    } else {
      debugPrint("[SettingsViewModel] Terminal no encontrado en BD.");
    }

    _defaultCustomer = await _settingsHelper.getSetting('default_customer');
    _defaultSeller = await _settingsHelper.getSetting('default_seller');
    _defaultWarehouse = await _settingsHelper.getSetting('default_warehouse');
    _defaultCustomerCode =
        await _settingsHelper.getSetting('default_customer_code');
    _defaultSellerCode =
        await _settingsHelper.getSetting('default_seller_code');
    _defaultWarehouseCode =
        await _settingsHelper.getSetting('default_warehouse_code');

    for (var module in _moduleAccess.keys) {
      final value = await _settingsHelper.getSetting('module_$module');
      if (value != null) {
        _moduleAccess[module] = value == 'true';
      }
    }

    // Cargar configuración de la empresa desde SQLite (tabla company_config)
    _companySettings = await _settingsHelper.getCompanySettings();
    if (_companySettings != null) {
      // El getter companyName se encargará de proveer _companySettings.name
      debugPrint(
          "[SettingsViewModel] Configuración de la empresa cargada desde SQLite: ${_companySettings!.name}");
    } else {
      debugPrint(
          "[SettingsViewModel] No se encontró CompanySettings en SQLite.");
    }

    _setLoading(false);
    debugPrint(
        "[SettingsViewModel] Carga de configuraciones iniciales completada.");
  }

  Future<bool> testUrlConnection(
      String url, String username, String password) async {
    debugPrint("[SettingsViewModel] Iniciando prueba de conexión URL: $url");
    if (url.isEmpty) {
      _errorMessage = "Por favor, ingrese el URL del servidor web.";
      notifyListeners();
      debugPrint("[SettingsViewModel] Error: URL vacía.");
      return false;
    }

    _setLoading(true);

    try {
      _apiService.setBaseUrl(url);
      debugPrint(
          "[SettingsViewModel] URL base configurada en ApiService: $url");

      // Login para obtener el token y validar credenciales
      // La respuesta del login incluye 'enterprise' que es el nombre de la empresa.
      await _apiService.login(username, password);
      // String? companyNameFromLogin = loginResponse['enterprise']; // No es necesario almacenarlo aquí si se obtiene de config/1

      _serverUrl = url; // Guardar la URL si el login es exitoso
      await _settingsHelper.setSetting('server_url', url);
      debugPrint(
          "[SettingsViewModel] Login exitoso. Token: ${_apiService.token}. URL del servidor guardada en SQLite.");

      // Después de un login exitoso, obtener la configuración completa de la empresa
      debugPrint(
          "[SettingsViewModel] Obteniendo configuración completa de la empresa desde /adm/config/1...");
      final companyConfigData = await _apiService.fetchCompanyConfig();
      _companySettings = CompanySettings.fromJson(companyConfigData);

      debugPrint(
          "[SettingsViewModel] Configuración de la empresa obtenida de la API: ${_companySettings?.name}");

      if (_companySettings != null) {
        await _settingsHelper.saveCompanySettings(
            _companySettings!); // Esto guarda todo en company_config
        debugPrint(
            "[SettingsViewModel] Configuración completa de la empresa guardada en SQLite (tabla company_config).");
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Error de conexión/configuración: ${e.toString()}";
      debugPrint(
          "[SettingsViewModel] Error en testUrlConnection: $_errorMessage");
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
      debugPrint("[SettingsViewModel] Error fetching $type: $e");
      return [];
    }
  }

  Future<bool> saveSettings() async {
    debugPrint("[SettingsViewModel] Guardando todas las configuraciones...");
    _setLoading(true);

    try {
      if (_serverUrl != null) {
        await _settingsHelper.setSetting('server_url', _serverUrl!);
        debugPrint("[SettingsViewModel] Guardado server_url: $_serverUrl");
      }

      if (_terminal != null) {
        await _settingsHelper.setSetting('terminal', _terminal!);
        _apiService.setTerminalName(
            _terminal!); // Asegúrate de actualizarlo en ApiService también
        debugPrint("[SettingsViewModel] Guardado terminal: $_terminal");
      }

      // La configuración de la empresa (_companySettings) se guarda
      // durante testUrlConnection si la conexión es exitosa.
      // Si se han hecho cambios manuales a _companySettings (si se permitiera en UI),
      // aquí sería el lugar para guardarlo, pero actualmente se carga de la API.
      // Si _companySettings no es nulo (porque se cargó o se obtuvo de la API),
      // y quieres re-guardarlo por si acaso (aunque es redundante si no hay cambios):
      if (_companySettings != null) {
        await _settingsHelper.saveCompanySettings(_companySettings!);
        debugPrint(
            "[SettingsViewModel] Re-guardada configuración de la empresa desde _companySettings (si existía).");
      }

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
      debugPrint("[SettingsViewModel] Guardados valores predeterminados.");

      for (var entry in _moduleAccess.entries) {
        await _settingsHelper.setSetting(
            'module_${entry.key}', entry.value.toString());
      }
      debugPrint(
          "[SettingsViewModel] Guardados accesos a módulos: $_moduleAccess");

      _setLoading(false);
      debugPrint(
          "[SettingsViewModel] Todas las configuraciones guardadas exitosamente.");
      return true;
    } catch (e) {
      _errorMessage = "Error al guardar: ${e.toString()}";
      debugPrint(
          "[SettingsViewModel] Error al guardar configuraciones: $_errorMessage");
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchLogs({String? action, String? date}) async {
    _isLoadingLogs = true;
    notifyListeners();
    debugPrint(
        "[SettingsViewModel] Obteniendo logs... Acción: $action, Fecha: $date");

    try {
      _logs = await _settingsHelper.getLogs(action: action, date: date);
      debugPrint(
          "[SettingsViewModel] Logs obtenidos: ${_logs.length} entradas.");
    } catch (e) {
      debugPrint(
          "[SettingsViewModel] Error al leer auditoria: ${e.toString()}");
      _logs = ["Error al cargar logs: ${e.toString()}"];
    }

    _isLoadingLogs = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
