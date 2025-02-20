import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';

class SettingScreen extends StatefulWidget {
  final ApiService apiService;

  const SettingScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final TextEditingController _urlController = TextEditingController();
  String? _companyName;
  bool _isLoading = false;

  // Module access toggles
  final Map<String, bool> _moduleAccess = {
    'billing': false,
    'budget': false,
    'delivery_notes': false,
    'orders': false,
  };

  // Default field controllers
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _depositoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load saved settings here if needed
  }

  void _testUrlConnection() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese una URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await widget.apiService.login('001', '12345');
      setState(() {
        _companyName = response['enterprise'];
        debugPrint(_companyName);
      });
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveSettings() {
    // Add logic to save settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: _isLoading ? null : _testUrlConnection,
                icon: _isLoading
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
                  color: _companyName != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _companyName != null
                        ? Colors.green.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _companyName != null ? Icons.cloud_done : Icons.cloud_off,
                      color: _companyName != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _companyName != null
                          ? Text("Conectado a: $_companyName",
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
                      'billing',
                      'Facturación',
                      Icons.receipt_long,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
                      'budget',
                      'Presupuesto',
                      Icons.account_balance_wallet,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
                      'delivery_notes',
                      'Notas de Entrega',
                      Icons.local_shipping,
                    ),
                    const Divider(height: 1, indent: 72),
                    _buildModuleSwitch(
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
                "Cliente por omisión",
                "Seleccione un cliente por defecto",
                Icons.person,
                _clienteController,
              ),
              const SizedBox(height: 16),
              _buildDefaultField(
                "Vendedor por omisión",
                "Seleccione un vendedor por defecto",
                Icons.badge,
                _vendedorController,
              ),
              const SizedBox(height: 16),
              _buildDefaultField(
                "Depósito por omisión",
                "Seleccione un depósito por defecto",
                Icons.warehouse,
                _depositoController,
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
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text(
                  "GUARDAR CONFIGURACIÓN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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

  Widget _buildModuleSwitch(
      String moduleKey, String moduleTitle, IconData icon) {
    return SwitchListTile(
      title: Text(moduleTitle),
      secondary: Icon(icon, color: SaintColors.orange),
      value: _moduleAccess[moduleKey] ?? false,
      activeColor: SaintColors.orange,
      onChanged: (value) {
        setState(() {
          _moduleAccess[moduleKey] = value;
        });
      },
    );
  }

  Widget _buildDefaultField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: SaintColors.orange),
        suffixIcon: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Show selection dialog or dropdown
          },
        ),
      ),
    );
  }
}
