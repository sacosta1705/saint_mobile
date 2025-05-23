// transaction_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saint_mobile/models/payment_item.dart';
import 'package:saint_mobile/models/product_item.dart';
import 'package:saint_mobile/models/search_result_item.dart';
import 'package:saint_mobile/services/api_service.dart'; // TU ApiService REAL

class TransactionViewModel extends ChangeNotifier {
  final ApiService apiService;
  final String transactionTypeApiCode;

  SearchResultItem? selectedClient;
  SearchResultItem? selectedSeller;
  SearchResultItem? selectedWarehouse;
  List<TextEditingController> generalNoteControllers =
      List.generate(10, (_) => TextEditingController());

  List<ProductItem> productItems = [];
  SearchResultItem? currentSelectedProductSearch;

  List<PaymentItem> paymentItems = [];

  bool isLoading = false;
  String? errorMessage;

  final TextEditingController clientController = TextEditingController();
  final TextEditingController sellerController = TextEditingController();
  final TextEditingController warehouseController = TextEditingController();
  final TextEditingController productSearchController = TextEditingController();

  TransactionViewModel(
      {required this.apiService, required this.transactionTypeApiCode});

  void selectClient(SearchResultItem client) {
    selectedClient = client;
    clientController.text = "${client.id} - ${client.description}";
    notifyListeners();
  }

  void selectSeller(SearchResultItem seller) {
    selectedSeller = seller;
    sellerController.text = "${seller.id} - ${seller.description}";
    notifyListeners();
  }

  void selectWarehouse(SearchResultItem warehouse) {
    selectedWarehouse = warehouse;
    warehouseController.text = "${warehouse.id} - ${warehouse.description}";
    notifyListeners();
  }

  void selectProductSearchResult(SearchResultItem product) {
    currentSelectedProductSearch = product;
    // Mostrar precio1 (sin IVA) en la búsqueda. Podrías optar por mostrar precioi1.
    productSearchController.text =
        "${product.id} - ${product.description} (Precio s/IVA: ${product.price1?.toStringAsFixed(2) ?? 'N/A'})";
    notifyListeners();
  }

  void addProductToList() {
    if (currentSelectedProductSearch == null ||
        currentSelectedProductSearch!.price1 == null || // Necesitamos precio1
        currentSelectedProductSearch!.pricei1 == null) {
      // Y precioi1 para calcular impuesto
      // Podrías mostrar un error si falta alguno de estos precios cruciales
      print(
          "Error: El producto seleccionado no tiene precios válidos (precio1 o precioi1).");
      productSearchController.text =
          "Error: precios no válidos para ${currentSelectedProductSearch?.id}";
      currentSelectedProductSearch =
          null; // Limpiar para evitar intentos repetidos
      notifyListeners();
      return;
    }

    int existingIndex = productItems
        .indexWhere((p) => p.coditem == currentSelectedProductSearch!.id);
    if (existingIndex != -1) {
      productItems[existingIndex]
          .updateQuantity(productItems[existingIndex].quantity + 1);
    } else {
      productItems.add(ProductItem(
        coditem: currentSelectedProductSearch!.id,
        description: currentSelectedProductSearch!.description,
        priceNoTax: currentSelectedProductSearch!.price1!,
        priceTax: currentSelectedProductSearch!.pricei1!,
      ));
    }
    currentSelectedProductSearch = null;
    productSearchController.clear();
    notifyListeners();
  }

  void updateProductQuantityInList(int index, double newQuantity) {
    if (index >= 0 && index < productItems.length) {
      productItems[index].updateQuantity(newQuantity);
      notifyListeners();
    }
  }

  void removeProductFromList(int index) {
    if (index >= 0 && index < productItems.length) {
      productItems[index].disposeCommentControllers();
      productItems.removeAt(index);
      notifyListeners();
    }
  }

  void addPayment(SearchResultItem instrument, double amount) {
    if (amount <= 0) return;
    paymentItems.add(PaymentItem(
      codtarj: instrument.id,
      descrip: instrument.description,
      amount: amount,
      fechae: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    ));
    notifyListeners();
  }

  void removePayment(int index) {
    if (index >= 0 && index < paymentItems.length) {
      paymentItems.removeAt(index);
      notifyListeners();
    }
  }

  // --- Getters para el Resumen de Totales (Actualizados) ---
  // 1. Total Renglones (Subtotal sin IVA)
  double get totalRenglones =>
      productItems.fold(0.0, (sum, item) => sum + item.totalNoTax);

  // 2. Total Impuestos (IVA)
  double get totalImpuestos =>
      productItems.fold(0.0, (sum, item) => sum + item.itemTaxAmount);

  // 3. Total Factura (Renglones + IVA)
  double get totalFactura => totalRenglones + totalImpuestos;

  // Para pagos (se mantienen igual, pero dependen de totalFactura)
  double get totalPagado =>
      paymentItems.fold(0.0, (sum, item) => sum + item.amount);
  double get montoRestante => totalFactura - totalPagado;

  // 4. Número Total de Artículos
  double get numeroTotalArticulos {
    if (productItems.isEmpty) return 0;
    return productItems.fold(0.0, (sum, item) => sum + item.quantity);
  }

  // ... (fetchDataForSearch se mantiene igual, asumiendo que la API devuelve precio1 y precioi1) ...
  Future<List<SearchResultItem>> fetchDataForSearch(String typeForApi) async {
    final endpointMapping = {
      'Cliente': 'customers?activo=1',
      'Vendedor': 'sellers?activo=1',
      'Depósito': 'warehouses?activo=1',
      'Producto':
          'products?activo=1&esimport=0&esempaque=0&deslote=0&descomp=0',
      'InstrumentoPago': 'paymethods?activo=1',
    };
    final endpoint = endpointMapping[typeForApi];
    if (endpoint == null) {
      _setError("Tipo de búsqueda no configurado: $typeForApi");
      return [];
    }

    _setLoading(true);
    try {
      final responseData = await apiService.get(endpoint);
      List<SearchResultItem> results = responseData
          .map((itemJson) => SearchResultItem.fromJson(itemJson, typeForApi))
          .toList();
      _setLoading(false);
      return results;
    } catch (e) {
      _setError("Error cargando $typeForApi: $e");
      return [];
    }
  }

  Future<bool> submitTransaction() async {
    if (selectedClient == null) {
      _setError("Debe seleccionar un cliente.");
      return false;
    }
    if (productItems.isEmpty) {
      _setError("Debe añadir al menos un producto.");
      return false;
    }
    if (montoRestante.abs() > 0.01 && totalFactura > 0) {
      _setError(
          "El monto restante debe ser cero para finalizar. Restante: ${montoRestante.toStringAsFixed(2)}");
      return false;
    }

    _setLoading(true);
    String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String dueDate = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().add(const Duration(days: 1)));

    List<String> notesToSend = generalNoteControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (notesToSend.length > 10) notesToSend = notesToSend.sublist(0, 10);

    Map<String, dynamic> invoiceData = {
      "correlname": "",
      "codclie": selectedClient!.id,
      "codvend": selectedSeller?.id ?? "",
      "codubic": selectedWarehouse?.id ?? "",
      "mtototal": totalFactura, // Total general CON impuesto
      "tgravable":
          totalRenglones, // Base imponible (suma de totales SIN impuesto de items)
      "texento": 0, // Asumir 0 exento por ahora
      "monto":
          totalRenglones, // Monto base (igual a tgravable si todo es gravable)
      "mtotax":
          totalFactura, // Según tu JSON, este es el MONTO TOTAL CON IMPUESTO
      "contado": totalPagado,
      "tipocli": 1,
      "fechae": currentDate,
      "fechav": dueDate,
      "id3": selectedClient!.secondaryId ?? selectedClient!.id,
      "notes": notesToSend,
      "ordenc": "",
      "telef": selectedClient!.originalData['telef'] ?? "",
      "tipofac": transactionTypeApiCode,
    };

    Map<String, dynamic> transactionPayload = {
      "additional": [],
      "invoice": invoiceData,
      "items": productItems
          .map((item) => item.toJson())
          .toList(), // toJson de ProductItem ahora usa itemTaxAmount para "mtotax"
      "payforms": paymentItems.map((item) => item.toJson()).toList(),
      "taxes": [
        // Array de impuestos globales de la factura
        {
          "monto":
              totalImpuestos, // La suma de los impuestos de todos los items
          "codtaxs": "IVA", // Código del impuesto (ej. "IVA")
          "tgravable": 16.0, // Tasa del impuesto (ej. 16.0 para 16%)
        }
      ],
    };

    List<Map<String, dynamic>> finalPayload = [transactionPayload];

    try {
      await apiService.post('invoice', finalPayload);
      _setLoading(false);
      resetTransaction();
      return true;
    } catch (e) {
      _setError("Error al enviar la transacción: $e");
      return false;
    }
  }

  void resetTransaction() {
    selectedClient = null;
    selectedSeller = null;
    selectedWarehouse = null;
    clientController.clear();
    sellerController.clear();
    warehouseController.clear();
    productSearchController.clear();
    for (var controller in generalNoteControllers) {
      controller.clear();
    }
    for (var item in productItems) {
      item.disposeCommentControllers();
    }
    productItems.clear();
    currentSelectedProductSearch = null;
    paymentItems.clear();
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (isLoading == value) return;
    isLoading = value;
    if (value) errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    isLoading = false;
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clientController.dispose();
    sellerController.dispose();
    warehouseController.dispose();
    productSearchController.dispose();
    for (var controller in generalNoteControllers) {
      controller.dispose();
    }
    for (var item in productItems) {
      item.disposeCommentControllers();
    }
    super.dispose();
  }
}
