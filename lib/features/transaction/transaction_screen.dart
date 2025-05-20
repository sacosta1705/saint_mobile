// transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/features/transaction/transaction_view_model.dart';
import 'package:saint_mobile/models/transaction.dart';
import 'package:saint_mobile/services/api_service.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late TransactionViewModel _viewModel;
  bool _isViewModelInitialized = false;

  String _transactionTypeName = 'Transacción';
  String _transactionTypeApiCode = '';
  Color? _appBarColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isViewModelInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        _transactionTypeName = arguments['title'] as String? ?? 'Transacción';
        _transactionTypeApiCode = arguments['type'] as String? ?? ''; // 'A', 'F', 'C', 'E'
        _appBarColor = arguments['color'] as Color?;
      } else {
        print("ADVERTENCIA: TransactionScreen no recibió argumentos válidos.");
        // Aquí podrías decidir cerrar la pantalla si los argumentos son cruciales
        // Future.microtask(() => Navigator.of(context).pop());
      }

      // Obtener ApiService. Asegúrate de que esté proveído en un ancestro.
      // Si ApiService es un singleton como en tu código, puedes accederlo directamente.
      // final apiService = ApiService(); // Si es un singleton accesible así
      final apiService = Provider.of<ApiService>(context, listen: false); // Si lo provees con Provider

      _viewModel = TransactionViewModel(
        apiService: apiService,
        transactionTypeApiCode: _transactionTypeApiCode,
      );
      _isViewModelInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isViewModelInitialized) {
      return Scaffold(
          appBar: AppBar(title: Text(_transactionTypeName)), // Muestra un título mientras carga
          body: const Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<TransactionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_transactionTypeName),
              backgroundColor: _appBarColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.cleaning_services),
                  tooltip: "Limpiar Formulario",
                  onPressed: vm.isLoading ? null : vm.resetTransaction,
                )
              ],
            ),
            body: Stack(
              children: [
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16,16,16,80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildHeaderSection(vm),
                        _buildNotesSection(vm),
                        _buildProductSection(vm, context),
                        PaymentSectionWidget(viewModel: vm),
                        _buildSummaryAndSubmit(vm, context),
                      ],
                    ),
                  ),
                ),
                if (vm.isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(TransactionViewModel vm) {
    return Column(
      children: [
        SearchFieldWidget(
          label: 'Cliente *',
          controller: vm.clientController,
          onSearchTriggered: () => vm.fetchDataForSearch('Cliente'),
          onItemSelected: (item) => vm.selectClient(item),
        ),
        SearchFieldWidget(
          label: 'Vendedor',
          controller: vm.sellerController,
          onSearchTriggered: () => vm.fetchDataForSearch('Vendedor'),
          onItemSelected: (item) => vm.selectSeller(item),
        ),
        SearchFieldWidget(
          label: 'Depósito',
          controller: vm.warehouseController,
          onSearchTriggered: () => vm.fetchDataForSearch('Depósito'),
          onItemSelected: (item) => vm.selectWarehouse(item),
        ),
      ],
    );
  }

  Widget _buildNotesSection(TransactionViewModel vm) {
    // CORREGIDO: Usa vm.generalNoteControllers
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text("Notas Generales (${vm.generalNoteControllers.where((c) => c.text.trim().isNotEmpty).length}/10)"),
        initiallyExpanded: vm.generalNoteControllers.any((c) => c.text.trim().isNotEmpty),
        children: List.generate(10, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              controller: vm.generalNoteControllers[index], // ASIGNAR EL CONTROLLER
              decoration: InputDecoration(
                labelText: 'Nota General ${index + 1}',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: 100, // O el límite de tu API
              // onChanged no es necesario aquí si solo lees el valor al enviar
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductSection(TransactionViewModel vm, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20, thickness: 1),
          SearchFieldWidget(
            label: 'Buscar Producto *',
            controller: vm.productSearchController,
            onSearchTriggered: () => vm.fetchDataForSearch('Producto'),
            onItemSelected: (item) => vm.selectProductSearchResult(item),
            trailingAction: IconButton(
              icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColorDark, size: 30),
              tooltip: 'Añadir Producto',
              onPressed: vm.currentSelectedProductSearch != null && !vm.isLoading
                  ? vm.addProductToList
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text('Productos (${vm.productItems.length})', style: Theme.of(context).textTheme.titleMedium),
          if (vm.productItems.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('No hay productos añadidos.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.productItems.length,
              itemBuilder: (context, index) => ProductCard(
                // key: ValueKey(vm.productItems[index].coditem + index.toString()), // Para ayudar a Flutter a identificar los items
                product: vm.productItems[index],
                onQuantityChanged: (qty) => vm.updateProductQuantityInList(index, qty),
                onDelete: () => vm.removeProductFromList(index),
                // onCommentChanged ya no es necesario, el ProductCard usa los controllers del ProductItem
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndSubmit(TransactionViewModel vm, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          const Divider(height: 20, thickness: 1),
          TotalsSummaryCard(viewModel: vm),
          const SizedBox(height: 20),
          if (vm.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom:10),
              decoration: BoxDecoration(
                color: Colors.red,
                border: Border.all(color: Colors.red.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 14))),
                  IconButton(icon: Icon(Icons.close, size: 20, color: Colors.red.shade700), onPressed: vm.clearError)
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text('Registrar $_transactionTypeName'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _appBarColor ?? Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: vm.isLoading ? null : () async {
                bool success = await vm.submitTransaction();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$_transactionTypeName registrada con éxito!'), backgroundColor: Colors.green),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // El ViewModel se encarga de sus propios controllers
    _viewModel.dispose();
    super.dispose();
  }
}

// --- Widgets Componentes (pueden ir en archivos separados para mayor orden) ---

class SearchFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Future<List<SearchResultItem>> Function() onSearchTriggered;
  final Function(SearchResultItem) onItemSelected;
  final Widget? trailingAction;

  const SearchFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.onSearchTriggered,
    required this.onItemSelected,
    this.trailingAction,
  });

  void _showItemSearchDialog(BuildContext context, String dialogTitle, Future<List<SearchResultItem>> Function() fetchItems, Function(SearchResultItem) onSelect) async {
    // Mostrar un loader mientras se cargan los datos
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
    );

    final items = await fetchItems();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Cerrar el loader

    if (items.isEmpty && context.mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
            title: Text("Sin Resultados"),
            content: Text("No se encontraron datos para '$dialogTitle'."),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("OK"))],
        ));
        return;
    }


    final searchDialogController = TextEditingController();
    List<SearchResultItem> filteredItems = List.from(items);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (stfContext, setStateDialog) {
          return AlertDialog(
            title: Text('Buscar $dialogTitle (${filteredItems.length})'),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: searchDialogController,
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: 'Escriba para filtrar...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                      ),
                      onChanged: (query) {
                        setStateDialog(() {
                          if (query.isEmpty) {
                            filteredItems = List.from(items);
                          } else {
                            filteredItems = items
                              .where((item) =>
                                  item.description.toLowerCase().contains(query.toLowerCase()) ||
                                  item.id.toLowerCase().contains(query.toLowerCase()) ||
                                  (item.secondaryId?.toLowerCase().contains(query.toLowerCase()) ?? false))
                              .toList();
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                    ? const Center(child: Text("No se encontraron resultados para el filtro."))
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (ctx, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          title: Text("${item.id} - ${item.description}"),
                          subtitle: item.secondaryId != null ? Text("ID Sec: ${item.secondaryId!}") : null,
                          onTap: () {
                            onSelect(item);
                            Navigator.of(dialogContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [ TextButton( onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')) ],
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea el botón con el textfield
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showItemSearchDialog(context, label.replaceAll(' *',''), onSearchTriggered, onItemSelected),
                ),
              ),
              readOnly: true,
            ),
          ),
          if (trailingAction != null) ...[
            const SizedBox(width: 8),
            Padding( // Para alinear verticalmente el IconButton si el TextFormField es más alto
              padding: const EdgeInsets.only(top: 0), // Ajustar según sea necesario
              child: trailingAction!,
            )
          ]
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductItem product;
  final Function(double) onQuantityChanged;
  final VoidCallback onDelete;
  // final Function(int commentIndex, String text) onCommentChanged; // Ya no se necesita

  const ProductCard({
    super.key,
    required this.product,
    required this.onQuantityChanged,
    required this.onDelete,
    // required this.onCommentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Text('${product.coditem} - ${product.description}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: onDelete
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: product.quantity.toString(),
                    decoration: const InputDecoration(
                        labelText: 'Cantidad', border: OutlineInputBorder(), isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    onChanged: (val) {
                      final qty = double.tryParse(val);
                      if (qty != null) onQuantityChanged(qty);
                    },
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Precio: ${product.priceNoTax.toStringAsFixed(2)}', textAlign: TextAlign.end)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Total: ${product.totalNoTax.toStringAsFixed(2)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ExpansionTile(
                title: Text("Comentarios del Producto (${product.commentControllers.where((c)=>c.text.trim().isNotEmpty).length}/10)", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                tilePadding: const EdgeInsets.symmetric(horizontal:0),
                childrenPadding: const EdgeInsets.only(top: 4),
                initiallyExpanded: product.commentControllers.any((c) => c.text.trim().isNotEmpty),
                children: List.generate(10, (commentIndex) { 
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: TextFormField(
                      controller: product.commentControllers[commentIndex], // Usa el controller del ProductItem
                      decoration: InputDecoration(
                        labelText: 'Comentario Item ${commentIndex + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      maxLength: 80,
                      // onChanged no es necesario aquí, el controller guarda el estado
                    ),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PaymentSectionWidget extends StatefulWidget {
  final TransactionViewModel viewModel;
  const PaymentSectionWidget({super.key, required this.viewModel});

  @override
  State<PaymentSectionWidget> createState() => _PaymentSectionWidgetState();
}

class _PaymentSectionWidgetState extends State<PaymentSectionWidget> {
  final TextEditingController _paymentAmountController = TextEditingController();
  SearchResultItem? _selectedPaymentInstrument;

  void _showPaymentInstrumentSearchDialog(BuildContext context) async {
    // Reutilizar el diálogo de búsqueda genérico de SearchFieldWidget
    final parentScreenStateSearchField = SearchFieldWidget( // Instancia temporal para acceder al método
        label: "", 
        controller: TextEditingController(), 
        onSearchTriggered: () => widget.viewModel.fetchDataForSearch('InstrumentoPago'), 
        onItemSelected: (item){},
    );
    parentScreenStateSearchField._showItemSearchDialog(context, "Instrumento de Pago", 
        () => widget.viewModel.fetchDataForSearch('InstrumentoPago'), 
        (item) {
            setState(() { _selectedPaymentInstrument = item; });
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20, thickness: 1),
          Text('Formas de Pago (${widget.viewModel.paymentItems.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: TextEditingController(text: _selectedPaymentInstrument != null ? "${_selectedPaymentInstrument!.id} - ${_selectedPaymentInstrument!.description}" : ""),
                  decoration: InputDecoration(
                    labelText: 'Instrumento',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _showPaymentInstrumentSearchDialog(context),
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _paymentAmountController,
                  decoration: const InputDecoration(labelText: 'Monto', border: OutlineInputBorder(), isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top:0),
                child: IconButton(
                  icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 30),
                  tooltip: 'Añadir Pago',
                  onPressed: widget.viewModel.isLoading ? null : () {
                    if (_selectedPaymentInstrument != null) {
                      final amount = double.tryParse(_paymentAmountController.text);
                      if (amount != null && amount > 0) {
                        widget.viewModel.addPayment(_selectedPaymentInstrument!, amount);
                        setState(() { _selectedPaymentInstrument = null; });
                        _paymentAmountController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Monto inválido para el pago.'), backgroundColor: Colors.orangeAccent),
                        );
                      }
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Seleccione un instrumento de pago primero.'), backgroundColor: Colors.orangeAccent),
                       );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.viewModel.paymentItems.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.viewModel.paymentItems.length,
              itemBuilder: (context, index) {
                final payment = widget.viewModel.paymentItems[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${payment.codtarj} - ${payment.descrip}'),
                    subtitle: Text('Monto: ${payment.amount.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: widget.viewModel.isLoading ? null : () => widget.viewModel.removePayment(index),
                    ),
                  ),
                );
              },
            ),
          if (widget.viewModel.paymentItems.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 10.0),child: Text("No hay pagos registrados."))),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }
}

class TotalsSummaryCard extends StatelessWidget {
  final TransactionViewModel viewModel;
  const TotalsSummaryCard({super.key, required this.viewModel});

  Widget _totalRow(BuildContext context, String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: isBold ? fontSize + 1 : fontSize,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resumen de la Transacción", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)
            ),
            const SizedBox(height: 12),
            _totalRow(context, "Total Renglones (s/IVA):", viewModel.totalRenglones.toStringAsFixed(2)),
            _totalRow(context, "Nº Total Artículos:", viewModel.numeroTotalArticulos.toStringAsFixed(0)), 
            const Divider(height: 16, thickness: 0.5),
            _totalRow(context, "Total Impuestos (IVA):", viewModel.totalImpuestos.toStringAsFixed(2)),
            _totalRow(
              context, 
              "TOTAL A PAGAR (c/IVA):", 
              viewModel.totalFactura.toStringAsFixed(2), 
              isBold: true, 
              color: Theme.of(context).primaryColorDark, 
              fontSize: 16
            ),
            const SizedBox(height: 12),
            const Divider(height: 16, thickness: 0.5),
            _totalRow(
              context, 
              "Total Pagado:", 
              viewModel.totalPagado.toStringAsFixed(2), 
              color: Colors.green[700], 
              fontSize: 15
            ),
            _totalRow(
              context, 
              "Monto Restante:", 
              viewModel.montoRestante.toStringAsFixed(2), 
              isBold: true, 
              color: viewModel.montoRestante.abs() > 0.01 ? Colors.red[700] : Colors.green[700], 
              fontSize: 15
            ),
          ],
        ),
      ),
    );
  }
}