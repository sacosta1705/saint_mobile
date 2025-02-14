import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';

class BillingScreen extends StatefulWidget {
  final ApiService apiService;
  const BillingScreen({super.key, required this.apiService});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final Map<String, TextEditingController> _controllers = {
    'Cliente': TextEditingController(),
    'Vendedor': TextEditingController(),
    'Depósito': TextEditingController(),
    'Producto': TextEditingController(),
  };

  final List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  void _addProduct() {
    if (_selectedProduct != null) {
      setState(() {
        _products.add({
          'code': _selectedProduct!['codprod'],
          'description': _selectedProduct!['descrip'],
          'quantity': 1,
          'price': _selectedProduct!['precio1'] ?? 0.0,
          'total': _selectedProduct!['precio1'] ?? 0.0,
        });
      });
      _selectedProduct = null;
      _controllers['Producto']?.clear();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAndShowSearchDialog(String type) async {
    try {
      final endpoint = {
        'Cliente': 'customers?activo=1',
        'Vendedor': 'sellers?activo=1',
        'Depósito': 'warehouses?activo=1',
        'Producto': 'products?activo=1',
      }[type];

      if (endpoint == null) return;

      final response = await widget.apiService.get(endpoint);
      final data = List<Map<String, dynamic>>.from(
          response.map((item) => Map<String, dynamic>.from(item)));
      _showSearchDialog(type, data);
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
            onSelect: (value) {
              _controllers[type]?.text = value;
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

    return Scaffold(
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
            ..._controllers.entries.map(
              (e) => SearchField(
                label: e.key,
                controller: e.value,
                onSearch: () => _fetchAndShowSearchDialog(e.key),
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ProductsTable(products: _products),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomActions(),
    );
  }
}

class SearchDialogContent extends StatelessWidget {
  final String type;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> data;
  final Function(String) onSearch;
  final Function(String) onSelect;

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
    return Column(
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
                onTap: () => onSelect(item.values.first.toString()),
              );
            },
          ),
        ),
      ],
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

  const ProductsTable({super.key, required this.products});

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
            rows: products
                .map((p) => DataRow(cells: [
                      DataCell(Text(p['code']?.toString() ?? '')),
                      DataCell(Text(p['description']?.toString() ?? '')),
                      DataCell(Text(p['quantity']?.toString() ?? '')),
                      DataCell(Text(p['price']?.toString() ?? '')),
                      DataCell(Text(p['total']?.toString() ?? '')),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {/* Implement delete */},
                      )),
                    ]))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class BottomActions extends StatelessWidget {
  const BottomActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.payment),
                label: const Text('Instrumentos'),
                style: FilledButton.styleFrom(
                  backgroundColor: SaintColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
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
