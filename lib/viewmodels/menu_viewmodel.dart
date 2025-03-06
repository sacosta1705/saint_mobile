import 'package:flutter/foundation.dart';
import 'package:saint_mobile/services/api_service.dart';

class MenuViewmodel extends ChangeNotifier {
  final ApiService _apiService;
  String? _errorMessage;

  MenuViewmodel({required ApiService apiService}) : _apiService = apiService;

  String? get errorMessage => _errorMessage;
  bool get isUserLoggedIn => _apiService.isLoggedIn();

  void logout() {
    _apiService.token = null;
    notifyListeners();
  }
}
