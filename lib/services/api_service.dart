import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import 'package:saint_mobile/services/database_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = "";
  String _terminal = "";

  static const String apiKey = "B5D31933-C996-476C-B116-EF212A41479A";
  static const String apiId = "1093";

  String? token;

  bool isLoggedIn() => token != null;

  String toBase64(String text) {
    final bytes = utf8.encode(text);
    return base64.encode(bytes);
  }

  void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      _baseUrl = url.substring(0, url.length - 1);
    } else {
      _baseUrl = url;
    }
    developer.log('URL del servidor configurada: $_baseUrl');
  }

  void setTerminalName(String terminal) {
    _terminal = terminal;
  }

  // Método para verificar si la URL base está configurada
  bool hasValidBaseUrl() {
    return _baseUrl.isNotEmpty;
  }

  // <Map<String, dynamic>>
  Future<Map<String, dynamic>> login(String username, String password) async {
    // Verificar que la URL base está configurada
    if (!hasValidBaseUrl()) {
      throw Exception(
          "URL del servidor no configurada. Configure el servidor en ajustes.");
    }

    final credentials = '$username:$password';

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/main/login'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'x-api-id': apiId,
              'Authorization': 'Basic ${toBase64(credentials)}'
            },
            body: jsonEncode({'terminal': _terminal}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw HttpException(
            'Error en la respuesta del servidor: ${response.statusCode}');
      }

      token = response.headers['pragma']!;

      if (token == null || token!.isEmpty) {
        throw Exception(
            "El servidor no devolvió el token Pragma en los headers");
      }

      return jsonDecode(response.body);
    } on TimeoutException {
      throw TimeoutException(
          'Tiempo límite de espera superado. Verifique su conexión a internet.');
    } on HttpException catch (e) {
      throw Exception(
          'Error en la conexión con el servidor. Verificar los datos del mismo. ${e.message}');
    } catch (e) {
      developer.log('Error inesperado: $e');
      rethrow;
    }
  }

  Future<void> post(String endpoint, dynamic payload) async {
    // Verificar que la URL base está configurada
    if (!hasValidBaseUrl()) {
      throw Exception(
          "URL del servidor no configurada. Configure el servidor en ajustes.");
    }

    if (token == null || token!.isEmpty) {
      throw Exception(
          "Sesion vencida. Debes iniciar sesión primero."); // Validación estricta
    }

    try {
      developer.log("Enviando POST con token: $token");

      final payloadString = jsonEncode(payload);

      final response = await http
          .post(
            Uri.parse('$_baseUrl/adm/$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Pragma': token!,
            },
            body: payloadString,
          )
          .timeout(const Duration(seconds: 30));

      developer.log("Respuesta POST: ${response.statusCode}"); // Depuración

      if (response.statusCode == 200) {
        await DatabaseService()
            .log(endpoint, 'logs', newData: jsonDecode(payload));

        final dynamic decoded = jsonDecode(response.body);
        return decoded;
      } else {
        throw HttpException("Error ${response.statusCode}: ${response.body}");
      }
    } on HttpException catch (e) {
      developer.log('Error en POST: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> get(String endpoint) async {
    // Verificar que la URL base está configurada
    if (!hasValidBaseUrl()) {
      throw Exception(
          "URL del servidor no configurada. Configure el servidor en ajustes.");
    }

    if (token == null || token!.isEmpty) {
      throw Exception("Sesion vencida. Iniciar sesion.");
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/adm/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Pragma': token!,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        throw const FormatException("Unexpected JSON format");
      } else {
        throw HttpException("Error ${response.statusCode}: ${response.body}");
      }
    } on HttpException catch (e) {
      debugPrint('Error en GET: $e');
      rethrow;
    }
  }
}
