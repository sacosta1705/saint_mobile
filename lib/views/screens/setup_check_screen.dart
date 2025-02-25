import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/views/screens/initial_setup_screen.dart';
import 'package:saint_mobile/views/screens/login_screen.dart';

class SetupCheckScreen extends StatelessWidget {
  const SetupCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final setupViewModel = Provider.of<SetupViewmodel>(context);

    // Si estamos cargando o revisando la configuración
    if (setupViewModel.isLoading) {
      return _buildLoadingScreen();
    }

    // Decidir qué pantalla mostrar basado en el estado del ViewModel
    return setupViewModel.isSetupComplete
        ? const LoginScreen()
        : const InitialSetupScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SaintColors.primary,
              SaintColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: SaintColors.white,
              ),
              SizedBox(
                height: 24,
              ),
              Text(
                "Iniciando aplicacion...",
                style: TextStyle(
                  color: SaintColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
