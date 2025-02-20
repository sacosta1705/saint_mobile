import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/services/api_service.dart';

class LoginForm extends StatefulWidget {
  final ApiService apiService;

  const LoginForm({
    super.key,
    required this.apiService,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _companyName;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await widget.apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _companyName = response['enterprise'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Sesión iniciada.",
                style: TextStyle(
                  color: SaintColors.white,
                ),
              ),
              backgroundColor: SaintColors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/menu');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error: $e",
                style: const TextStyle(
                  color: SaintColors.white,
                ),
              ),
              backgroundColor: SaintColors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SaintTextWidget(
            controller: _usernameController,
            icon: Icons.person,
            label: "Usuario",
            errMessage: "El usuario es requerido",
            isObscured: false,
          ),
          const SizedBox(height: 16),
          SaintTextWidget(
            controller: _passwordController,
            label: "Clave",
            icon: Icons.lock,
            errMessage: "Clave incorrecta",
            isObscured: true,
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(SaintColors.primary),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SaintTextWidget extends StatelessWidget {
  const SaintTextWidget({
    super.key,
    required TextEditingController controller,
    required this.label,
    required this.icon,
    required this.errMessage,
    required this.isObscured,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String label;
  final IconData icon;
  final String errMessage;
  final bool isObscured;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.text,
      obscureText: isObscured ? true : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return errMessage;
        }
        return null;
      },
    );
  }
}
