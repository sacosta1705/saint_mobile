import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/viewmodels/settings_viewmodel.dart';

class PaymentEntry {
  final Map<String, dynamic> instrument;
  double amount;

  PaymentEntry({
    required this.instrument,
    required this.amount,
  });
}

class BillingViewmodel extends ChangeNotifier {
  final ApiService apiService;

  // Map para códigos de cliente, vendedor y depósito
  final Map<String, String> codes = {
    'Cliente': '',
    'Vendedor': '',
    'Depósito': '',
  };

  // Controllers for form fields
  final Map<String, TextEditingController> controllers = {
    'Cliente': TextEditingController(),
    'Vendedor': TextEditingController(),
    'Depósito': TextEditingController(),
    'Producto': TextEditingController(),
  };

  // Products and payments lists
  final List<Map<String, dynamic>> products = [];
  final List<PaymentEntry> payments = [];
  Map<String, dynamic>? selectedProduct;
  bool _isInitialized = false;

  BillingViewmodel({required this.apiService});

  // Getters for calculated values
  double get totalAmount => products.fold(
        0.0,
        (sum, product) => sum + (product['total'] ?? 0),
      );

  double get paidAmount => payments.fold(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

  double get remainingAmount => totalAmount - paidAmount;

  // Método para cargar valores predeterminados desde SettingsViewmodel
  void loadDefaultValues(BuildContext context) {
    if (_isInitialized) return;

    final settingsViewModel =
        Provider.of<SettingsViewmodel>(context, listen: false);

    // Cargar cliente predeterminado
    if (settingsViewModel.defaultClient != null &&
        settingsViewModel.defaultClient!.isNotEmpty) {
      controllers['Cliente']?.text = settingsViewModel.defaultClient!;

      // Cargar código de cliente si está disponible
      if (settingsViewModel.defaultCustomerCode != null) {
        codes['Cliente'] = settingsViewModel.defaultCustomerCode!;
      }
    }

    // Cargar vendedor predeterminado
    if (settingsViewModel.defaultSeller != null &&
        settingsViewModel.defaultSeller!.isNotEmpty) {
      controllers['Vendedor']?.text = settingsViewModel.defaultSeller!;

      // Cargar código de vendedor si está disponible
      if (settingsViewModel.defaultSellerCode != null) {
        codes['Vendedor'] = settingsViewModel.defaultSellerCode!;
      }
    }

    // Cargar depósito predeterminado
    if (settingsViewModel.defaultWarehouse != null &&
        settingsViewModel.defaultWarehouse!.isNotEmpty) {
      controllers['Depósito']?.text = settingsViewModel.defaultWarehouse!;

      // Cargar código de depósito si está disponible
      if (settingsViewModel.defaultWarehouseCode != null) {
        codes['Depósito'] = settingsViewModel.defaultWarehouseCode!;
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Methods
  void addPayment(PaymentEntry payment) {
    payments.add(payment);
    notifyListeners();
  }

  void deletePayment(int index) {
    payments.removeAt(index);
    notifyListeners();
  }

  void addProduct() {
    if (selectedProduct != null) {
      // Check if product already exists
      final existingProductIndex =
          products.indexWhere((p) => p['code'] == selectedProduct!['codprod']);

      if (existingProductIndex != -1) {
        // Update existing product quantity
        products[existingProductIndex]['quantity']++;
        products[existingProductIndex]['total'] = products[existingProductIndex]
                ['quantity'] *
            products[existingProductIndex]['price'];
      } else {
        // Add new product
        products.add({
          'code': selectedProduct!['codprod'],
          'description': selectedProduct!['descrip'],
          'quantity': 1,
          'price': selectedProduct!['precio1'] ?? 0.0,
          'total': selectedProduct!['precio1'] ?? 0.0,
        });
      }

      selectedProduct = null;
      controllers['Producto']?.clear();
      notifyListeners();
    }
  }

  void updateProductQuantity(int index, double newQuantity) {
    products[index]['quantity'] = newQuantity;
    products[index]['total'] = newQuantity * products[index]['price'];
    notifyListeners();
  }

  void deleteProduct(int index) {
    products.removeAt(index);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchData(String type) async {
    final endpoint = {
      'Cliente': 'customers?activo=1',
      'Vendedor': 'sellers?activo=1',
      'Depósito': 'warehouses?activo=1',
      'Producto':
          'products?activo=1&esimport=0&esempaque=0&deslote=0&descomp=0',
      'Instrumentos': 'paymethods?activo=1'
    }[type];

    if (endpoint == null) return [];

    try {
      final response = await apiService.get(endpoint);
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

  Map<String, dynamic> generateInvoiceJson(String type) {
    final invoice = {
      "correlname": "",
      "codclie": codes['Cliente'] ?? "",
      "codvend": codes['Vendedor'] ?? "",
      "codubic": codes['Depósito'] ?? "",
      "mtototal": totalAmount,
      "tgravable": totalAmount,
      "texento": 0,
      "monto": totalAmount,
      "mtotax": totalAmount * 0.16, // Ajusta según tu lógica de impuestos
      "contado": paidAmount,
      "tipocli": 1,
      "fechae": DateTime.now().toIso8601String().substring(0, 10),
      "fechav": DateTime.now().toIso8601String().substring(0, 10),
      "id3": codes['Cliente'] ?? "",
      "notes": [],
      "ordenc": "123456",
      "telef": "34556633",
      "tipofac": type
    };

    final items = products.map((product) {
      return {
        "coditem": product['code'] ?? "",
        "comments": [],
        "precio": product['price'] ?? 0.0,
        "cantidad": product['quantity'] ?? 1,
        "mtotax": (product['total'] ?? 0.0) *
            0.16, // Ajusta según tu lógica de impuestos
        "descomp": 1,
        "desseri": 0,
        "deslote": 0,
        "nrounicol": 0,
        "nrolote": "",
        "parts": [],
        "serials": [],
        "additional": []
      };
    }).toList();

    final payforms = payments.map((payment) {
      return {
        "monto": payment.amount,
        "codtarj": payment.instrument["codtarj"],
        "fechae": DateTime.now().toIso8601String().substring(0, 10),
        "descrip": payment.instrument["descrip"],
      };
    }).toList();

    final taxes = [
      {
        "monto": invoice["mtotax"],
        "codtaxs": "IVA",
        "tgravable": 16,
      }
    ];

    return {
      "additional": [],
      "invoice": invoice,
      "items": items,
      "payforms": payforms,
      "taxes": taxes,
    };
  }

  Future<bool> submitInvoice(String type) async {
    try {
      var payload = generateInvoiceJson(type);
      debugPrint(jsonEncode(payload));
      await apiService.post('invoice', payload);
      return true;
    } catch (e) {
      debugPrint("Error submitting invoice: $e");
      return false;
    }
  }

  void setClientCode(String code) {
    codes['Cliente'] = code;
  }

  void setSellerCode(String code) {
    codes['Vendedor'] = code;
  }

  void setWarehouseCode(String code) {
    codes['Depósito'] = code;
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
