import 'package:flutter/foundation.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/models/user.dart';
import 'package:saint_mobile/services/api_service.dart';

class LoginViewmodel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  String? _errorMessage;
  User? _user;

  LoginViewmodel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final settingsHelper = SettingsHelper();
      final terminal = await settingsHelper.getSetting('terminal');

      if (terminal != null && terminal.isNotEmpty) {
        _apiService.setTerminalName(terminal);
      }

      final response = await _apiService.login(username, password);
      final token = _apiService.token;

      if (token != null) {
        _user = User.fromJson(response, token);
        _setLoading(false);
        return true;
      } else {
        _errorMessage =
            "Error al iniciar sesión. Verifique 'usuario' y 'clave'";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _apiService.token = null;
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
