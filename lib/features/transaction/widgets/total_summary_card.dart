import 'package:flutter/material.dart';
import 'package:saint_mobile/features/transaction/transaction_view_model.dart';

class TotalsSummaryCard extends StatelessWidget {
  final TransactionViewModel viewModel;
  const TotalsSummaryCard({super.key, required this.viewModel});

  Widget _totalRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: fontSize,
                  color: Colors.grey[700])),
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
            Text("Resumen de la Transacción",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 12),
            _totalRow(context, "Total Renglones (s/IVA):",
                viewModel.totalRenglones.toStringAsFixed(2)),
            _totalRow(context, "Nº Total Artículos:",
                viewModel.numeroTotalArticulos.toStringAsFixed(0)),
            const Divider(height: 16, thickness: 0.5),
            _totalRow(context, "Total Impuestos (IVA):",
                viewModel.totalImpuestos.toStringAsFixed(2)),
            _totalRow(context, "TOTAL A PAGAR (c/IVA):",
                viewModel.totalFactura.toStringAsFixed(2),
                isBold: true,
                color: Theme.of(context).primaryColorDark,
                fontSize: 16),
            const SizedBox(height: 12),
            const Divider(height: 16, thickness: 0.5),
            _totalRow(context, "Total Pagado:",
                viewModel.totalPagado.toStringAsFixed(2),
                color: Colors.green[700], fontSize: 15),
            _totalRow(context, "Monto Restante:",
                viewModel.montoRestante.toStringAsFixed(2),
                isBold: true,
                color: viewModel.montoRestante.abs() > 0.01
                    ? Colors.red[700]
                    : Colors.green[700],
                fontSize: 15),
          ],
        ),
      ),
    );
  }
}
