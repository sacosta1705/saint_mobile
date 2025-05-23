import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saint_mobile/models/product_item.dart';

class ProductCard extends StatelessWidget {
  final ProductItem product;
  final Function(double) onQuantityChanged;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onQuantityChanged,
    required this.onDelete,
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15))),
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: onDelete),
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
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    onChanged: (val) {
                      final qty = double.tryParse(val);
                      if (qty != null) onQuantityChanged(qty);
                    },
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Precio: ${product.priceNoTax.toStringAsFixed(2)}',
                        textAlign: TextAlign.end)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Total: ${product.totalNoTax.toStringAsFixed(2)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ExpansionTile(
                title: Text(
                    "Comentarios del Producto (${product.commentControllers.where((c) => c.text.trim().isNotEmpty).length}/10)",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                childrenPadding: const EdgeInsets.only(top: 4),
                initiallyExpanded: product.commentControllers
                    .any((c) => c.text.trim().isNotEmpty),
                children: List.generate(10, (commentIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: TextFormField(
                      controller: product.commentControllers[
                          commentIndex], // Usa el controller del ProductItem
                      decoration: InputDecoration(
                        labelText: 'Comentario Item ${commentIndex + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
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
