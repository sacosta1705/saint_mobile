import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/views/screens/initial_setup_screen.dart';
import 'package:saint_mobile/views/screens/login_screen.dart';

class SetupCheckScreen extends StatefulWidget {
  const SetupCheckScreen({super.key});

  @override
  State<SetupCheckScreen> createState() => _SetupCheckScreenState();
}

class _SetupCheckScreenState extends State<SetupCheckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final setupViewModel =
          Provider.of<SetupViewmodel>(context, listen: false);
      setupViewModel.addListener(() {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final setupViewModel = Provider.of<SetupViewmodel>(context);

    if (setupViewModel.isLoading) {
      return _buildLoadingScreen();
    }

    if (setupViewModel.isSetupComplete) {
      return const LoginScreen();
    }

    return InitialSetupScreen(
      onSetupComplete: () {},
    );
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
