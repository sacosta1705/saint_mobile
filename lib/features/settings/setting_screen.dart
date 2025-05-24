import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/features/settings/settings_viewmodel.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/login_dialog.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _sellerController = TextEditingController();
  final TextEditingController _warehouseController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();

  TabController?
      _tabController; // Hacerlo nullable para inicialización condicional
  late SettingsViewmodel
      _viewModel; // Almacenar el viewModel para acceder en el listener

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<SettingsViewmodel>(context, listen: false);

    // Inicializar TabController basado en la data actual de companySettings
    _initializeTabController();

    // Escuchar cambios en companySettings para actualizar el TabController dinámicamente
    _viewModel.addListener(_onViewModelChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar datos iniciales en los controladores
      if (_viewModel.serverUrl != null) {
        _urlController.text = _viewModel.serverUrl!;
      }
      if (_viewModel.defaultClient != null) {
        _customerController.text = _viewModel.defaultClient!;
      }
      if (_viewModel.defaultSeller != null) {
        _sellerController.text = _viewModel.defaultSeller!;
      }
      if (_viewModel.defaultWarehouse != null) {
        _warehouseController.text = _viewModel.defaultWarehouse!;
      }
      if (_viewModel.terminal != null) {
        _terminalController.text = _viewModel.terminal!;
      }
      // Cargar logs iniciales (no depende de companySettings para su visibilidad inicial)
      if (_viewModel.companySettings != null) {
        // Solo cargar logs si las pestañas adicionales están visibles
        _viewModel.fetchLogs();
      }
    });
  }

  void _initializeTabController() {
    final bool hasCompanySettings = _viewModel.companySettings != null;
    final int tabLength = hasCompanySettings ? 3 : 1;

    // Si el TabController existe y tiene la misma longitud, no hacer nada.
    if (_tabController != null && _tabController!.length == tabLength) {
      return;
    }

    // Si existe, hacer dispose del anterior antes de crear uno nuevo.
    _tabController?.dispose();

    _tabController = TabController(length: tabLength, vsync: this);
    // Asegurarse de que el índice no esté fuera de rango si las pestañas cambian
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        // Prevenir errores si el índice se vuelve inválido después de que las pestañas cambian
        if (_tabController!.index >= _tabController!.length) {
          _tabController!.animateTo(_tabController!.length - 1);
        }
      }
    });
    if (mounted) {
      setState(
          () {}); // Forzar reconstrucción para actualizar el AppBar con el nuevo TabBar
    }
  }

  void _onViewModelChange() {
    // Re-inicializar el TabController si el estado de companySettings cambia
    // y afecta el número de pestañas.
    final bool hasCompanySettings = _viewModel.companySettings != null;
    final int expectedTabLength = hasCompanySettings ? 3 : 1;
    if (_tabController == null || _tabController!.length != expectedTabLength) {
      _initializeTabController();
    }
    // Si companySettings ahora existe y antes no, cargar logs
    if (hasCompanySettings &&
        _viewModel.logs.isEmpty &&
        !_viewModel.isLoadingLogs) {
      _viewModel.fetchLogs();
    }
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
    // El _viewModel ya está disponible como miembro de la clase
    final success = await _viewModel.testUrlConnection(
      _urlController.text,
      username,
      password,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_viewModel.errorMessage ?? 'Error de conexión'),
            backgroundColor: SaintColors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conexión exitosa con ${_viewModel.companyName ?? "empresa"}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: SaintColors.green,
        ),
      );
      // _onViewModelChange será llamado por el listener si companySettings cambia,
      // actualizando el TabController.
    }
  }

  void _saveSettings() async {
    // El _viewModel ya está disponible
    _viewModel.setServerUrl(_urlController.text);
    _viewModel.setTerminalName(_terminalController.text);

    final success = await _viewModel.saveSettings();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada.'),
          backgroundColor: SaintColors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Error al guardar.'),
          backgroundColor: SaintColors.red,
        ),
      );
    }
  }

  Future<void> _fetchAndShowSearchDialog(String type) async {
    // El _viewModel ya está disponible
    if (!_apiServiceIsConfiguredAndLoggedIn(_viewModel)) {
      _showDialog("Error de Conexión",
          "No hay conexión activa con el servidor. Por favor, pruebe la conexión en la pestaña 'General'.");
      return;
    }

    try {
      final data = await _viewModel.fetchData(type);
      if (!mounted) return;
      if (data.isEmpty) {
        _showDialog("Sin resultados", "No se encontraron datos para '$type'.");
        return;
      }
      _showSearchDialog(type, data);
    } catch (e) {
      if (!mounted) return;
      _showDialog("Error", "Error cargando $type: ${e.toString()}");
    }
  }

  bool _apiServiceIsConfiguredAndLoggedIn(SettingsViewmodel viewModel) {
    return viewModel.serverUrl != null &&
        viewModel.serverUrl!.isNotEmpty &&
        Provider.of<ApiService>(context, listen: false).isLoggedIn();
  }

  void _showSearchDialog(String type, List<Map<String, dynamic>> data) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredData = List.from(data);
    // El _viewModel ya está disponible

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Buscar $type (${filteredData.length})"),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Escriba para filtrar...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (query) => setStateDialog(() {
                      if (query.isEmpty) {
                        filteredData = List.from(data);
                      } else {
                        filteredData = data.where((item) {
                          final description =
                              item['descrip']?.toString().toLowerCase() ?? '';
                          final code = item.entries
                              .firstWhere(
                                  (e) => e.key.toLowerCase().startsWith('cod'),
                                  orElse: () => const MapEntry('', ''))
                              .value
                              .toString()
                              .toLowerCase();
                          final id3 =
                              item['id3']?.toString().toLowerCase() ?? '';
                          return description.contains(query.toLowerCase()) ||
                              code.contains(query.toLowerCase()) ||
                              (type == 'Cliente' &&
                                  id3.contains(query.toLowerCase()));
                        }).toList();
                      }
                    }),
                  ),
                ),
                Expanded(
                  child: filteredData.isEmpty
                      ? const Center(
                          child: Text(
                              "No se encontraron resultados para el filtro."))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final item = filteredData[index];
                            final code = item.entries
                                .firstWhere(
                                    (e) =>
                                        e.key.toLowerCase().startsWith('cod'),
                                    orElse: () => const MapEntry('', ''))
                                .value
                                .toString();
                            final description =
                                item['descrip']?.toString() ?? 'N/A';
                            String displayText = "$code - $description";
                            if (type == 'Cliente' && item['id3'] != null) {
                              displayText =
                                  "${item['id3']} - $description (Cod: $code)";
                            }

                            return ListTile(
                              title: Text(displayText),
                              onTap: () {
                                String itemDescription = item['descrip'] ?? '';
                                String itemCode = '';
                                if (type == 'Cliente') {
                                  itemCode =
                                      item['codclie'] ?? item['id3'] ?? '';
                                  _customerController.text = itemDescription;
                                  _viewModel.setDefaultCustomer(itemDescription,
                                      code: itemCode);
                                } else if (type == 'Vendedor') {
                                  itemCode = item['codvend'] ?? '';
                                  _sellerController.text = itemDescription;
                                  _viewModel.setDefaultSeller(itemDescription,
                                      code: itemCode);
                                } else if (type == 'Depósito') {
                                  itemCode = item['codubic'] ?? '';
                                  _warehouseController.text = itemDescription;
                                  _viewModel.setDefaultWarehouse(
                                      itemDescription,
                                      code: itemCode);
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
    if (!mounted) return;
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
    // El viewModel se obtiene en initState y se escucha con _viewModel.addListener
    // Para el build, podemos usar Consumer o simplemente acceder a _viewModel si el estado del TabController
    // se maneja en setState. Usar Consumer para la visibilidad del TabBar es más limpio.
    return Consumer<SettingsViewmodel>(builder: (context, viewModel, child) {
      // Asegurarnos de que el TabController se reconstruya si es necesario
      // Esto puede ser redundante si _onViewModelChange ya lo hace, pero es seguro.
      final bool hasCompanySettings = viewModel.companySettings != null;
      final int expectedTabLength = hasCompanySettings ? 3 : 1;
      if (_tabController == null ||
          _tabController!.length != expectedTabLength) {
        // Llamar a _initializeTabController puede causar un setState durante el build.
        // Es mejor que _onViewModelChange lo maneje y haga setState.
        // Aquí solo construimos con lo que _tabController ya es.
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text("Configuración"),
          backgroundColor: SaintColors.primary,
          foregroundColor: SaintColors.white,
          bottom: _tabController == null || _tabController!.length == 1
              ? null // No mostrar TabBar si solo hay una pestaña
              : TabBar(
                  controller: _tabController,
                  labelColor: SaintColors.white,
                  unselectedLabelColor: SaintColors.white.withOpacity(0.7),
                  indicatorColor: SaintColors.orange,
                  tabs: const [
                    Tab(icon: Icon(Icons.settings_outlined), text: "General"),
                    Tab(icon: Icon(Icons.business_outlined), text: "Empresa"),
                    Tab(icon: Icon(Icons.list_alt_outlined), text: "Auditoría"),
                  ],
                ),
        ),
        body: _tabController == null
            ? const Center(
                child:
                    CircularProgressIndicator()) // Estado inicial antes de que _tabController se inicialice
            : TabBarView(
                controller: _tabController,
                physics: _tabController!.length == 1
                    ? const NeverScrollableScrollPhysics()
                    : null, // Deshabilitar swipe si solo hay 1 tab
                children: _tabController!.length == 1
                    ? [_buildGeneralSettingsTab()]
                    : [
                        _buildGeneralSettingsTab(),
                        _buildCompanyInfoTab(),
                        _buildAuditLogTab(),
                      ],
              ),
      );
    });
  }

  Widget _buildGeneralSettingsTab() {
    // Usar _viewModel directamente ya que _onViewModelChange y setState se encargarán de reconstruir.
    return ResponsiveLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              onPressed: _viewModel.isLoading ? null : _showLoginDialog,
              icon: _viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: SaintColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
              label: const Text("Probar conexión y Cargar Datos"),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _viewModel.companyName != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _viewModel.companyName != null
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _viewModel.companyName != null
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    color: _viewModel.companyName != null
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        _viewModel.companyName != null
                            ? "Conectado a: ${_viewModel.companyName}"
                            : "No conectado",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            _buildSectionTitle("Acceso a Módulos"),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModuleSwitch(
                      _viewModel, 'billing', 'Facturación', Icons.receipt_long),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildModuleSwitch(_viewModel, 'budget', 'Presupuesto',
                      Icons.account_balance_wallet),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildModuleSwitch(_viewModel, 'delivery_note',
                      'Notas de Entrega', Icons.local_shipping),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildModuleSwitch(
                      _viewModel, 'orders', 'Pedidos', Icons.shopping_cart),
                ],
              ),
            ),
            const Divider(height: 32),
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
            FilledButton.icon(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(SaintColors.primary),
                minimumSize: WidgetStateProperty.all(
                  const Size(double.infinity, 56),
                ),
                foregroundColor: WidgetStateProperty.all(SaintColors.white),
              ),
              onPressed: _viewModel.isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                "GUARDAR CONFIGURACIÓN GENERAL",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoTab() {
    // Usar _viewModel directamente
    final companySettings = _viewModel.companySettings;

    if (_viewModel.isLoading && companySettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (companySettings == null) {
      // Este caso debería ser manejado por la lógica que oculta la pestaña
      // Pero si se muestra, es un fallback.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Información de la empresa no disponible.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Por favor, realice una 'Prueba de conexión' en la pestaña 'General' para cargar estos datos.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_sync_outlined),
                label: const Text("Probar Conexión"),
                onPressed:
                    _showLoginDialog, // Reutilizar el diálogo de login para probar
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaintColors.orange,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      );
    }

    return ResponsiveLayout(
      maxWidth: 700,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Datos de la Empresa Registrados"),
              const SizedBox(height: 20.0),
              _buildInfoRow("Nombre:", companySettings.name),
              _buildInfoRow("RIF/ID Fiscal:", companySettings.taxidentifier),
              _buildInfoRow("Dirección Principal:", companySettings.address1),
              if (companySettings.address2.isNotEmpty)
                _buildInfoRow(
                    "Dirección Secundaria:", companySettings.address2),
              _buildInfoRow(
                  "País (Código):", companySettings.countrycode.toString()),
              _buildInfoRow(
                  "Estado (Código):", companySettings.statecode.toString()),
              _buildInfoRow(
                  "Ciudad (Código):", companySettings.citycode.toString()),
              _buildInfoRow("Código Impuesto (IVA):", companySettings.taxcode),
              _buildInfoRow("Símbolo Moneda Referencia:",
                  companySettings.referencesymbol),
              _buildInfoRow("Tasa de Referencia:",
                  companySettings.referencerate.toStringAsFixed(2)),
              _buildInfoRow("Porcentaje Retención IVA:",
                  companySettings.taxretentionperct.toStringAsFixed(2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    // Usar _viewModel directamente
    return ResponsiveLayout(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text("Recargar"),
                  onPressed: _viewModel.isLoadingLogs
                      ? null
                      : () => _viewModel.fetchLogs(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SaintColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_viewModel.isLoadingLogs) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_viewModel.logs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No hay registros de auditoría disponibles.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _viewModel.logs.length,
                  itemBuilder: (context, index) {
                    final logEntry = _viewModel.logs[index];
                    String title = "Evento Desconocido";
                    String subtitle = logEntry;
                    final parts = logEntry.split(" - ");
                    if (parts.length >= 3) {
                      title = "${parts[0]} - ${parts[1]}";
                      subtitle = parts.sublist(2).join(" - ");
                    }

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SaintColors.primary.withOpacity(0.1),
                          foregroundColor: SaintColors.primary,
                          child: const Icon(Icons.history, size: 20),
                        ),
                        title: Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        dense: true,
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: SaintColors.primary),
          ),
          const SizedBox(height: 4),
          SelectableText(
            // Hacer el valor seleccionable
            value.isNotEmpty ? value : "N/D",
            style: TextStyle(
                fontSize: 15,
                color: value.isNotEmpty ? Colors.black87 : Colors.grey[600]),
          ),
          if (label.isNotEmpty)
            const Divider(height: 12, thickness: 0.5, color: Colors.black12),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 15, // Reducido ligeramente
          fontWeight: FontWeight.w700, // Un poco más de peso
          color: SaintColors.orange,
          letterSpacing: 0.8, // Ajustado
        ),
      ),
    );
  }

  Widget _buildModuleSwitch(SettingsViewmodel viewModel, String moduleKey,
      String moduleTitle, IconData icon) {
    return SwitchListTile(
      title: Text(moduleTitle, style: const TextStyle(fontSize: 15)),
      secondary: Icon(icon, color: SaintColors.primary.withOpacity(0.8)),
      value: viewModel.getModuleAccess(moduleKey),
      activeColor: SaintColors.orange,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon, color: SaintColors.primary.withOpacity(0.8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search_outlined, color: SaintColors.orange),
            tooltip: "Buscar y seleccionar $type",
            onPressed: () => _fetchAndShowSearchDialog(type),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
      readOnly: true,
      onTap: () => _fetchAndShowSearchDialog(type),
    );
  }

  @override
  void dispose() {
    _viewModel
        .removeListener(_onViewModelChange); // Importante remover el listener
    _tabController?.dispose(); // Hacer dispose seguro
    _urlController.dispose();
    _customerController.dispose();
    _sellerController.dispose();
    _warehouseController.dispose();
    _terminalController.dispose();
    super.dispose();
  }
}
