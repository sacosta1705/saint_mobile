import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/viewmodels/settings_viewmodel.dart';
import 'package:saint_mobile/views/widgets/responsive_layout.dart';
import 'package:saint_mobile/views/widgets/saint_appbar.dart';
import 'package:saint_mobile/views/widgets/login_dialog.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _sellerController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<SettingsViewmodel>(context, listen: false);

      if (viewModel.serverUrl != null) {
        _urlController.text = viewModel.serverUrl!;
      }
      if (viewModel.defaultClient != null) {
        _customerController.text = viewModel.defaultClient!;
      }
      if (viewModel.defaultSeller != null) {
        _sellerController.text = viewModel.defaultSeller!;
      }
      if (viewModel.defaultWarehouse != null) {
        _warehouseController.text = viewModel.defaultWarehouse!;
      }

      if (viewModel.terminal != null) {
        _terminalController.text = viewModel.terminal!;
      }
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => LoginDialog(
        onLogin: (username, password) {
          _testUrlConnection(username, password);
        },
      ),
    );
  }

  void _testUrlConnection(String username, String password) async {
    final viewModel = Provider.of<SettingsViewmodel>(context, listen: false);
    final success = await viewModel.testUrlConnection(
      _urlController.text,
      username,
      password,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Error de conexión')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conexión exitosa con ${viewModel.companyName}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveSettings() async {
    final viewModel = Provider.of<SettingsViewmodel>(context, listen: false);

    viewModel.setServerUrl(_urlController.text);
    viewModel.setTerminalName(_terminalController.text);
    viewModel.setDefaultCustomer(_customerController.text);
    viewModel.setDefaultSeller(_sellerController.text);
    viewModel.setDefaultWarehouse(_warehouseController.text);

    final success = await viewModel.saveSettings();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada.'),
        ),
      );
    }
  }

  Future<void> _fetchAndShowSearchDialog(String type) async {
    final viewModel = Provider.of<SettingsViewmodel>(context, listen: false);

    try {
      final data = await viewModel.fetchData(type);
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
    final viewModel = Provider.of<SettingsViewmodel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Buscar $type"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Buscar $type",
                    suffixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (query) => setState(() {
                    filteredData = data
                        .where((item) => item.values.any((v) => v
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase())))
                        .toList();
                  }),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final displayText = type == 'Cliente'
                          ? '${item['id3']} - ${item['descrip']}'
                          : item['descrip'] ?? '';

                      return ListTile(
                        title: Text(displayText),
                        onTap: () {
                          if (type == 'Cliente') {
                            _customerController.text = item['descrip'];
                            viewModel.setDefaultCustomer(
                              item['descrip'],
                              code: item['codclie'] ?? item['id3'],
                            );
                          } else if (type == 'Vendedor') {
                            _sellerController.text = item['descrip'];
                            viewModel.setDefaultSeller(
                              item['descrip'],
                              code: item['codvend'],
                            );
                          } else if (type == 'Depósito') {
                            _warehouseController.text = item['descrip'];
                            viewModel.setDefaultWarehouse(
                              item['descrip'],
                              code: item['codubic'],
                            );
                          }
                          Navigator.pop(context);
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
    final viewModel = Provider.of<SettingsViewmodel>(context);

    return Scaffold(
      appBar: const SaintAppbar(title: "Configuración"),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Server Connection Section
              _buildSectionTitle("Conexión al Servidor"),
              const SizedBox(height: 12),
              TextFormField(
                controller: _terminalController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la estación (terminal)",
                  hintText: "Nombre que identifica el equipo de facturación",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.terminal),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "URL del servidor",
                  hintText: "http://ejemplo.com/api/v1",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.web),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(SaintColors.orange),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                onPressed: viewModel.isLoading ? null : _showLoginDialog,
                icon: viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: SaintColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text("Probar conexión"),
              ),

              // Connection Status
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: viewModel.companyName != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: viewModel.companyName != null
                        ? Colors.green.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      viewModel.companyName != null
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: viewModel.companyName != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: viewModel.companyName != null
                          ? Text("Conectado a: ${viewModel.companyName}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold))
                          : const Text("No conectado"),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Module Access Section
              _buildSectionTitle("Acceso a Módulos"),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildModuleSwitch(
                      viewModel,
                      'billing',
                      'Facturación',
                      Icons.receipt_long,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
                      viewModel,
                      'budget',
                      'Presupuesto',
                      Icons.account_balance_wallet,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
                      viewModel,
                      'delivery_note',
                      'Notas de Entrega',
                      Icons.local_shipping,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
                      viewModel,
                      'orders',
                      'Pedidos',
                      Icons.shopping_cart,
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // Default Values Section
              _buildSectionTitle("Valores Predeterminados"),
              const SizedBox(height: 16),
              _buildDefaultField(
                "Cliente",
                "Cliente por omisión",
                "Seleccione un cliente por defecto",
                Icons.person,
                _customerController,
              ),
              const SizedBox(height: 16),
              _buildDefaultField(
                "Vendedor",
                "Vendedor por omisión",
                "Seleccione un vendedor por defecto",
                Icons.badge,
                _sellerController,
              ),
              const SizedBox(height: 16),
              _buildDefaultField(
                "Depósito",
                "Depósito por omisión",
                "Seleccione un depósito por defecto",
                Icons.warehouse,
                _warehouseController,
              ),

              const SizedBox(height: 32),

              // Save Button
              FilledButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(SaintColors.orange),
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 56),
                  ),
                ),
                onPressed: viewModel.isLoading ? null : _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text(
                  "GUARDAR CONFIGURACIÓN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(SaintColors.orange),
                  minimumSize: WidgetStateProperty.all(
                    const Size(double.infinity, 56),
                  ),
                ),
                onPressed: _showLogsModal,
                icon: const Icon(Icons.list),
                label: const Text(
                  "VER AUDITORIA",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogsModal() async {
    final settingsViewmodel =
        Provider.of<SettingsViewmodel>(context, listen: false);

    await settingsViewmodel.fetchLogs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("REGISTROS DE AUDITORIA"),
        content: settingsViewmodel.isLoadingLogs
            ? const Center(child: CircularProgressIndicator())
            : settingsViewmodel.logs.isEmpty
                ? const Text("No hay registros disponibles")
                : SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: settingsViewmodel.logs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(settingsViewmodel.logs[index]),
                        );
                      },
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CERRAR"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: SaintColors.orange,
        ),
      ),
    );
  }

  Widget _buildModuleSwitch(SettingsViewmodel viewModel, String moduleKey,
      String moduleTitle, IconData icon) {
    return SwitchListTile(
      title: Text(moduleTitle),
      secondary: Icon(icon, color: SaintColors.orange),
      value: viewModel.getModuleAccess(moduleKey),
      activeColor: SaintColors.orange,
      onChanged: (value) {
        viewModel.setModuleAccess(moduleKey, value);
      },
    );
  }

  Widget _buildDefaultField(
    String type,
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(icon, color: SaintColors.orange),
            ),
            readOnly: true,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _fetchAndShowSearchDialog(type),
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: SaintColors.orange,
            foregroundColor: SaintColors.white,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _customerController.dispose();
    _sellerController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }
}
