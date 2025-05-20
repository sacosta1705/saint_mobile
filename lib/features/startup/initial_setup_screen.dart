
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/features/login/login_screen.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';

class InitialSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  const InitialSetupScreen({
    super.key,
    this.onSetupComplete,
  });

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 600;
    final setupViewModel = Provider.of<SetupViewmodel>(context);

    return Scaffold(
      appBar: const SaintAppbar(title: "Configuración Inicial"),
      body: Container(
        color: SaintColors.primary,
        child: ResponsiveLayout(
          maxWidth: 600,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Logo section
                  SizedBox(
                    height: isSmallScreen ? 80 : 120,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_blanco.png',
                        width: isSmallScreen ? 80 : 120,
                        height: isSmallScreen ? 80 : 120,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Welcome section
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: isSmallScreen ? 40 : 64,
                          color: SaintColors.primary,
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 24),
                        const Text(
                          '¡Bienvenido!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Para comenzar, configure la clave de administrador que se utilizará para acceder a la configuración del sistema.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Password form section
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Clave',
                              hintText: 'Mínimo 6 caracteres',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 10 : 16,
                                horizontal: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese una clave';
                              }
                              if (value.length < 6) {
                                return 'La clave debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmar clave',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 10 : 16,
                                horizontal: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Las claves no coinciden';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: setupViewModel.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final success =
                                  await setupViewModel.setInitialPassword(
                                _passwordController.text,
                              );

                              if (success && mounted) {
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()));
                              } else if (!success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Error al guardar la clave. Por favor intente nuevamente.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: SaintColors.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: setupViewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SaintColors.primary,
                            ),
                          )
                        : const Text(
                            'Completar Configuración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
