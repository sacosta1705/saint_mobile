import 'package:flutter/foundation.dart';
import 'package:saint_mobile/services/api_service.dart';

class MenuViewmodel extends ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _errorMessage;

  MenuViewmodel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUserLoggedIn => _apiService.isLoggedIn();

  void logout() {
    _apiService.token = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
