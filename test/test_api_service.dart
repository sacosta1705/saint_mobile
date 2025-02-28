import 'package:flutter/foundation.dart';
import 'package:saint_mobile/services/api_service.dart';

void main() async {
  final apiService = ApiService();

  if (!apiService.isLoggedIn()) await apiService.login('001', '12345');

  try {
    List<Map<String, dynamic>> data =
        await apiService.get('warehouses?activo=1');

    for (var item in data) {
      debugPrint("Descripcion: ${item['descrip']}\n");
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
