// transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/features/transaction/transaction_view_model.dart';
import 'package:saint_mobile/features/transaction/widgets/payment_section_widget.dart';
import 'package:saint_mobile/features/transaction/widgets/product_card.dart';
import 'package:saint_mobile/features/transaction/widgets/search_field_widget.dart';
import 'package:saint_mobile/features/transaction/widgets/total_summary_card.dart';
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
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        _transactionTypeName = arguments['title'] as String? ?? 'Transacción';
        _transactionTypeApiCode =
            arguments['type'] as String? ?? ''; // 'A', 'F', 'C', 'E'
        _appBarColor = arguments['color'] as Color?;
      } else {
        debugPrint(
            "ADVERTENCIA: TransactionScreen no recibió argumentos válidos.");
      }

      final apiService = Provider.of<ApiService>(context, listen: false);

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
          appBar: AppBar(title: Text(_transactionTypeName)),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
          label: 'Vendedor *',
          controller: vm.sellerController,
          onSearchTriggered: () => vm.fetchDataForSearch('Vendedor'),
          onItemSelected: (item) => vm.selectSeller(item),
        ),
        SearchFieldWidget(
          label: 'Depósito *',
          controller: vm.warehouseController,
          onSearchTriggered: () => vm.fetchDataForSearch('Depósito'),
          onItemSelected: (item) => vm.selectWarehouse(item),
        ),
      ],
    );
  }

  Widget _buildNotesSection(TransactionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(
            "Notas Generales (${vm.generalNoteControllers.where((c) => c.text.trim().isNotEmpty).length}/10)"),
        initiallyExpanded:
            vm.generalNoteControllers.any((c) => c.text.trim().isNotEmpty),
        children: List.generate(10, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              controller: vm.generalNoteControllers[index],
              decoration: InputDecoration(
                labelText: 'Nota General ${index + 1}',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: 100,
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
              icon: Icon(Icons.add_circle,
                  color: Theme.of(context).primaryColorDark, size: 30),
              tooltip: 'Añadir Producto',
              onPressed:
                  vm.currentSelectedProductSearch != null && !vm.isLoading
                      ? vm.addProductToList
                      : null,
            ),
          ),
          const SizedBox(height: 10),
          Text('Productos (${vm.productItems.length})',
              style: Theme.of(context).textTheme.titleMedium),
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
                product: vm.productItems[index],
                onQuantityChanged: (qty) =>
                    vm.updateProductQuantityInList(index, qty),
                onDelete: () => vm.removeProductFromList(index),
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
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.red.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(vm.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 14))),
                  IconButton(
                      icon: Icon(Icons.close,
                          size: 20, color: Colors.red.shade700),
                      onPressed: vm.clearError)
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
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      bool success = await vm.submitTransaction();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '$_transactionTypeName registrada con éxito!'),
                              backgroundColor: Colors.green),
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
    _viewModel.dispose();
    super.dispose();
  }
}
