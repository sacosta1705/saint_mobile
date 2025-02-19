import 'package:flutter/material.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/widgets/login_form.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/constants/saint_colors.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';
  final ApiService apiService;
  final SettingsHelper settingsHelper = SettingsHelper();

  LoginScreen({
    super.key,
    required this.apiService,
  });

  void _showAdminPasswordDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AdminPasswordDialog();
      },
    ).then((success) {
      if (success == true) {
        Navigator.of(context).pushNamed('/settings');
      }
    });
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
              LoginForm(apiService: apiService)
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
  _AdminPasswordDialogState createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<AdminPasswordDialog> {
  late TextEditingController passwordController;
  bool isLoading = false;
  bool obscurePassword = true;
  final SettingsHelper settingsHelper = SettingsHelper();

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

  void _validatePassword(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    final password = passwordController.text;
    try {
      final storedPassword = await settingsHelper.getSetting('admin_password');

      if (storedPassword == password) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pop(false);
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
    } catch (e) {
      Navigator.of(context).pop(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error al verificar credenciales.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (isLoading)
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
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: isLoading ? null : () => _validatePassword(context),
          child: const Text('Acceder'),
        ),
      ],
    );
  }
}
