import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saint_mobile/services/api_service.dart';

class SettingsViewmodel extends ChangeNotifier {
  final ApiService _apiService;

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

  SettingsViewmodel({required ApiService apiService})
      : _apiService = apiService;

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

  Future<bool> testUrlConnection(String url) async {
    if (url.isEmpty) {
      _errorMessage = "Por favor, ingrese el URL del servidor web.";
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      final response = await _apiService.login('001', '12345');
      _companyName = response['enterprise'];
      _serverUrl = url;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Error de conexión: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> saveSettings() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _setLoading(false);
    return true;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
