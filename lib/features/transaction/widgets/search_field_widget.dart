import 'package:flutter/material.dart';
import 'package:saint_mobile/models/search_result_item.dart';

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

  void showItemSearchDialog(
      BuildContext context,
      String dialogTitle,
      Future<List<SearchResultItem>> Function() fetchItems,
      Function(SearchResultItem) onSelect) async {
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
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text("Sin Resultados"),
                content: Text("No se encontraron datos para '$dialogTitle'."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text("OK"))
                ],
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      onChanged: (query) {
                        setStateDialog(() {
                          if (query.isEmpty) {
                            filteredItems = List.from(items);
                          } else {
                            filteredItems = items
                                .where((item) =>
                                    item.description
                                        .toLowerCase()
                                        .contains(query.toLowerCase()) ||
                                    item.id
                                        .toLowerCase()
                                        .contains(query.toLowerCase()) ||
                                    (item.secondaryId
                                            ?.toLowerCase()
                                            .contains(query.toLowerCase()) ??
                                        false))
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(
                            child: Text(
                                "No se encontraron resultados para el filtro."))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredItems.length,
                            itemBuilder: (ctx, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                title: Text("${item.id} - ${item.description}"),
                                subtitle: item.secondaryId != null
                                    ? Text("ID Sec: ${item.secondaryId!}")
                                    : null,
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
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'))
            ],
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
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alinea el botón con el textfield
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
                  onPressed: () => showItemSearchDialog(
                      context,
                      label.replaceAll(' *', ''),
                      onSearchTriggered,
                      onItemSelected),
                ),
              ),
              readOnly: true,
            ),
          ),
          if (trailingAction != null) ...[
            const SizedBox(width: 8),
            Padding(
              // Para alinear verticalmente el IconButton si el TextFormField es más alto
              padding:
                  const EdgeInsets.only(top: 0), // Ajustar según sea necesario
              child: trailingAction!,
            )
          ]
        ],
      ),
    );
  }
}
