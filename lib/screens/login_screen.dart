import 'package:flutter/material.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/widgets/login_form.dart';
import 'package:saint_mobile/widgets/responsive_layout.dart';
import 'package:saint_mobile/widgets/saint_appbar.dart';

class LoginScreen extends StatelessWidget {
  static const String routeName = '/login';
  final ApiService apiService;

  const LoginScreen({
    super.key,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SaintAppbar(title: "Iniciar sesión"),
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
