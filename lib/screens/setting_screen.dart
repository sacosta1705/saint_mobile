import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SaintAppbar(title: "Configuración"),
      body: ResponsiveLayout(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Configuracion"),
          ],
        ),
      ),
    );
  }
}
