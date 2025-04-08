import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/viewmodels/billing_viewmodel.dart';
import 'package:saint_mobile/views/widgets/responsive_layout.dart';
import 'package:saint_mobile/views/widgets/saint_appbar.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late BillingViewmodel _viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _viewModel = BillingViewmodel(apiService: apiService);
  }

  void _showPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChangeNotifierProvider.value(
        value: _viewModel,
        child: const PaymentBottomSheet(),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(
            '¿Está seguro que desea eliminar ${_viewModel.products[index]['description']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _viewModel.deleteProduct(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndShowSearchDialog(String type) async {
    try {
      final data = await _viewModel.fetchData(type);
      if (mounted) {
        _showSearchDialog(type, data);
      }
    } catch (e) {
      _showDialog("Error", "Error cargando $type");
    }
  }

  void _showSearchDialog(String type, List<Map<String, dynamic>> data) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredData = List.from(data);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Buscar $type"),
          content: SearchDialogContent(
            type: type,
            searchController: searchController,
            data: filteredData,
            onSearch: (query) => setState(() {
              filteredData = data
                  .where((item) => item.values.any((v) =>
                      v.toString().toLowerCase().contains(query.toLowerCase())))
                  .toList();
            }),
            onSelect: (item) {
              if (type == 'Producto') {
                _viewModel.selectedProduct = item;
                _viewModel.controllers[type]?.text =
                    '${item['codprod']} - ${item['descrip']}';
              } else {
                _viewModel.controllers[type]?.text = item['descrip'];
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<BillingViewmodel>(
        builder: (context, viewModel, _) => Scaffold(
          appBar: SaintAppbar(
            title: "Facturación",
            type: arguments?['type'],
            showLogout: true,
            backgroundColor: arguments?['color'],
          ),
          body: ResponsiveLayout(
            maxWidth: 1200,
            child: Column(
              children: [
                ...viewModel.controllers.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            label: e.key,
                            controller: e.value,
                            onSearch: () => _fetchAndShowSearchDialog(e.key),
                          ),
                        ),
                        if (e.key == 'Producto' &&
                            viewModel.selectedProduct != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: viewModel.addProduct,
                            icon: const Icon(Icons.add_circle),
                            style: IconButton.styleFrom(
                              backgroundColor: SaintColors.primary,
                              foregroundColor: SaintColors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ProductsTable(
                      products: viewModel.products,
                      onQuantityChanged: viewModel.updateProductQuantity,
                      onDelete: _confirmDelete,
                    ),
                  ),
                ),
                InvoiceSummary(
                  totalAmount: viewModel.totalAmount,
                  paidAmount: viewModel.paidAmount,
                  remainingAmount: viewModel.remainingAmount,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomActions(
            onPayMethodsPressed: _showPaymentDialog,
            canTotalize: viewModel.remainingAmount <= 0,
            onTotalizePressed: () {
              viewModel.submitInvoice(arguments?['type'] ?? '');
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

class PaymentBottomSheet extends StatelessWidget {
  const PaymentBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return Consumer<BillingViewmodel>(
      builder: (context, viewModel, _) => _PaymentBottomSheetContent(
        apiService: apiService,
      ),
    );
  }
}

class _PaymentBottomSheetContent extends StatefulWidget {
  final ApiService apiService;

  const _PaymentBottomSheetContent({
    required this.apiService,
  });

  @override
  State<_PaymentBottomSheetContent> createState() =>
      _PaymentBottomSheetContentState();
}

class _PaymentBottomSheetContentState
    extends State<_PaymentBottomSheetContent> {
  Map<String, dynamic>? _selectedInstrument;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addPayment() {
    if (_selectedInstrument == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final viewModel = Provider.of<BillingViewmodel>(context, listen: false);
    viewModel.addPayment(
      PaymentEntry(
        instrument: _selectedInstrument!,
        amount: amount,
      ),
    );

    setState(() {
      _selectedInstrument = null;
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<BillingViewmodel>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Instrumentos de Pago',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    label: 'Instrumento',
                    controller: TextEditingController(
                      text: _selectedInstrument?['descrip'] ?? '',
                    ),
                    onSearch: () async {
                      final result = await viewModel.fetchData('Instrumentos');
                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (context) => SearchDialogContent(
                          type: 'Instrumento',
                          searchController: TextEditingController(),
                          data: result,
                          onSearch: (_) {},
                          onSelect: (instrument) {
                            setState(() {
                              _selectedInstrument = instrument;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addPayment,
                  icon: const Icon(Icons.add_circle),
                  style: IconButton.styleFrom(
                    backgroundColor: SaintColors.primary,
                    foregroundColor: SaintColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: viewModel.payments.length,
                itemBuilder: (context, index) {
                  final payment = viewModel.payments[index];
                  return ListTile(
                    title: Text(payment.instrument['descrip']),
                    subtitle: Text(payment.amount.toStringAsFixed(2)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        viewModel.deletePayment(index);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            InvoiceSummary(
              totalAmount: viewModel.totalAmount,
              paidAmount: viewModel.paidAmount,
              remainingAmount: viewModel.remainingAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceSummary extends StatelessWidget {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  const InvoiceSummary({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              label: 'Total',
              amount: totalAmount,
              color: SaintColors.primary,
            ),
            _SummaryItem(
              label: 'Pagado',
              amount: paidAmount,
              color: Colors.green,
            ),
            _SummaryItem(
              label: 'Restante',
              amount: remainingAmount,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class SearchDialogContent extends StatelessWidget {
  final String type;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> data;
  final Function(String) onSearch;
  final Function(Map<String, dynamic>) onSelect;

  const SearchDialogContent({
    super.key,
    required this.type,
    required this.searchController,
    required this.data,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "Buscar $type",
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: onSearch,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final displayText = type == 'Producto'
                    ? '${item['codprod']} - ${item['descrip']}'
                    : type == 'Cliente'
                        ? '${item['id3']} - ${item['descrip']}'
                        : item['descrip'];

                return ListTile(
                  title: Text(displayText),
                  onTap: () => onSelect(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onSearch;

  const SearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: SaintColors.primary,
            foregroundColor: SaintColors.white,
          ),
        ),
      ],
    );
  }
}

class ProductsTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(int, double) onQuantityChanged;
  final Function(int) onDelete;

  const ProductsTable({
    super.key,
    required this.products,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Descripción')),
              DataColumn(label: Text('Cant.')),
              DataColumn(label: Text('Precio')),
              DataColumn(label: Text('Total')),
              DataColumn(label: Text('')),
            ],
            rows: List<DataRow>.generate(
              products.length,
              (index) => DataRow(
                cells: [
                  DataCell(Text(products[index]['code']?.toString() ?? '')),
                  DataCell(
                      Text(products[index]['description']?.toString() ?? '')),
                  DataCell(
                    TextFormField(
                      initialValue: products[index]['quantity'].toString(),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                      ],
                      onChanged: (value) {
                        final quantity = double.tryParse(value);
                        if (quantity != null && quantity > 0) {
                          onQuantityChanged(index, quantity);
                        }
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                    ),
                  ),
                  DataCell(Text(products[index]['price']?.toString() ?? '')),
                  DataCell(Text(products[index]['total']?.toString() ?? '')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDelete(index),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BottomActions extends StatelessWidget {
  const BottomActions({
    super.key,
    required this.onPayMethodsPressed,
    required this.canTotalize,
    required this.onTotalizePressed,
  });

  final VoidCallback onPayMethodsPressed;
  final bool canTotalize;
  final VoidCallback onTotalizePressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPayMethodsPressed,
                icon: const Icon(Icons.payment),
                label: const Text('Inst. de Pago'),
                style: FilledButton.styleFrom(
                  backgroundColor: SaintColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: canTotalize ? onTotalizePressed : null,
                icon: const Icon(Icons.calculate),
                label: const Text('Totalizar'),
                style: FilledButton.styleFrom(
                  backgroundColor: SaintColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
