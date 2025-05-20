import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/widgets/login_form.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';
import 'package:saint_mobile/constants/saint_colors.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  Future<void> _showAdminPasswordDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AdminPasswordDialog();
      },
    );

    // Check if the widget is still mounted and result is true before navigating
    if (result == true && context.mounted) {
      Navigator.of(context).pushNamed('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SaintAppbar(
        title: "Iniciar sesión",
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showAdminPasswordDialog(context),
            color: Colors.white,
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 32),
              const LoginForm()
            ],
          ),
        ),
      ),
    );
  }
}

class AdminPasswordDialog extends StatefulWidget {
  const AdminPasswordDialog({super.key});

  @override
  State<AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<AdminPasswordDialog> {
  late TextEditingController passwordController;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupViewModel = Provider.of<SetupViewmodel>(context);

    return AlertDialog(
      title: const Text('Acceso a configuración'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingrese la clave de administrador para acceder a la configuración.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Clave de administrador',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.admin_panel_settings),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
            ),
          ),
          if (setupViewModel.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: CircularProgressIndicator(
                color: SaintColors.primary,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: setupViewModel.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: setupViewModel.isLoading
              ? null
              : () async {
                  final isValid = await setupViewModel.validateAdminPassword(
                    passwordController.text,
                  );

                  if (mounted) {
                    if (isValid) {
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pop(false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Clave incorrecta. Acceso denegado.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
          child: const Text('Acceder'),
        ),
      ],
    );
  }
}
