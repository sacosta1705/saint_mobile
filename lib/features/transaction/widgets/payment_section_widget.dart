import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saint_mobile/features/transaction/transaction_view_model.dart';
import 'package:saint_mobile/features/transaction/widgets/search_field_widget.dart';
import 'package:saint_mobile/models/search_result_item.dart';

class PaymentSectionWidget extends StatefulWidget {
  final TransactionViewModel viewModel;
  const PaymentSectionWidget({super.key, required this.viewModel});

  @override
  State<PaymentSectionWidget> createState() => _PaymentSectionWidgetState();
}

class _PaymentSectionWidgetState extends State<PaymentSectionWidget> {
  final TextEditingController _paymentAmountController =
      TextEditingController();
  SearchResultItem? _selectedPaymentInstrument;

  void _showPaymentInstrumentSearchDialog(BuildContext context) async {
    // Reutilizar el diálogo de búsqueda genérico de SearchFieldWidget
    final parentScreenStateSearchField = SearchFieldWidget(
      // Instancia temporal para acceder al método
      label: "",
      controller: TextEditingController(),
      onSearchTriggered: () =>
          widget.viewModel.fetchDataForSearch('InstrumentoPago'),
      onItemSelected: (item) {},
    );
    parentScreenStateSearchField.showItemSearchDialog(
        context,
        "Instrumento de Pago",
        () => widget.viewModel.fetchDataForSearch('InstrumentoPago'), (item) {
      setState(() {
        _selectedPaymentInstrument = item;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20, thickness: 1),
          Text('Formas de Pago (${widget.viewModel.paymentItems.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: TextEditingController(
                      text: _selectedPaymentInstrument != null
                          ? "${_selectedPaymentInstrument!.id} - ${_selectedPaymentInstrument!.description}"
                          : ""),
                  decoration: InputDecoration(
                    labelText: 'Instrumento',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          _showPaymentInstrumentSearchDialog(context),
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
                  decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                      isDense: true),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: IconButton(
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).primaryColor, size: 30),
                  tooltip: 'Añadir Pago',
                  onPressed: widget.viewModel.isLoading
                      ? null
                      : () {
                          if (_selectedPaymentInstrument != null) {
                            final amount =
                                double.tryParse(_paymentAmountController.text);
                            if (amount != null && amount > 0) {
                              widget.viewModel.addPayment(
                                  _selectedPaymentInstrument!, amount);
                              setState(() {
                                _selectedPaymentInstrument = null;
                              });
                              _paymentAmountController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Monto inválido para el pago.'),
                                    backgroundColor: Colors.orangeAccent),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Seleccione un instrumento de pago primero.'),
                                  backgroundColor: Colors.orangeAccent),
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
                    subtitle:
                        Text('Monto: ${payment.amount.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: widget.viewModel.isLoading
                          ? null
                          : () => widget.viewModel.removePayment(index),
                    ),
                  ),
                );
              },
            ),
          if (widget.viewModel.paymentItems.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text("No hay pagos registrados."))),
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
