import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/features/login/login_viewmodel.dart';
import 'package:saint_mobile/features/menu/menu_viewmodel.dart';
import 'package:saint_mobile/features/settings/settings_viewmodel.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/features/transaction/transaction_screen.dart';
import 'package:saint_mobile/features/login/login_screen.dart';
import 'package:saint_mobile/features/menu/menu_screen.dart';
import 'package:saint_mobile/features/startup/setup_check_screen.dart';
import 'package:saint_mobile/features/settings/setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final settingsHelper = SettingsHelper();

  final serverUrl = await settingsHelper.getSetting('server_url');
  if (serverUrl != null && serverUrl.isNotEmpty) {
    apiService.setBaseUrl(serverUrl);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider(
          create: (_) => apiService,
        ),
        ChangeNotifierProvider(
          create: (_) => LoginViewmodel(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SetupViewmodel(settingsHelper: settingsHelper),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewmodel(
            apiService: apiService,
            settingsHelper: settingsHelper,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MenuViewmodel(
            apiService: apiService,
          ),
        ),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facturación móvil Saint',
      debugShowCheckedModeBanner: false,
      home: const SetupCheckScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => const SettingScreen(),
        '/menu': (context) => const MenuScreen(),
        '/billing': (context) => const TransactionScreen(),
        '/orders': (context) => const TransactionScreen(),
        '/delivery_notes': (context) => const TransactionScreen(),
        '/budget': (context) => const TransactionScreen(),
      },
    );
  }
}
