import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/features/login/login_viewmodel.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewmodel>(context);

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
            onPressed: loginViewModel.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final success = await loginViewModel.login(
                        _usernameController.text,
                        _passwordController.text,
                      );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Sesión iniciada.",
                              style: TextStyle(color: SaintColors.white),
                            ),
                            backgroundColor: SaintColors.green,
                          ),
                        );
                        Navigator.of(context).pushReplacementNamed('/menu');
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Error: ${loginViewModel.errorMessage}",
                              style: const TextStyle(color: SaintColors.white),
                            ),
                            backgroundColor: SaintColors.red,
                          ),
                        );
                      }
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: loginViewModel.isLoading
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
      obscureText: isObscured,
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
