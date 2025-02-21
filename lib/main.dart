import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/services/api_service.dart';
import 'package:saint_mobile/viewmodels/login_viewmodel.dart';
import 'package:saint_mobile/viewmodels/menu_viewmodel.dart';
import 'package:saint_mobile/viewmodels/settings_viewmodel.dart';
import 'package:saint_mobile/viewmodels/setup_viewmodel.dart';
import 'package:saint_mobile/views/screens/login_screen.dart';
import 'package:saint_mobile/views/screens/menu_screen.dart';
import 'package:saint_mobile/views/screens/setup_check_screen.dart';
import 'package:saint_mobile/views/screens/setting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final settingsHelper = SettingsHelper();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LoginViewmodel(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SetupViewmodel(settingsHelper: settingsHelper),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewmodel(apiService: apiService),
        ),
        ChangeNotifierProvider(
            create: (_) => MenuViewmodel(
                  apiService: apiService,
                ))
      ],
      child: const App(),
    ),
  );
  // runApp(App(
  //   apiService: apiService,
  //   settingsHelper: settingsHelper,
  // ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saint',
      debugShowCheckedModeBanner: false,
      home: const SetupCheckScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => const SettingScreen(),
        '/menu': (context) => const MenuScreen(),
        // '/billing': (context) => BillingScreen(),
        // '/budget': (context) => BillingScreen(),
        // '/delivery_notes': (context) => BillingScreen(),
        // '/orders': (context) => BillingScreen(),
        // '/login': (context) => LoginScreen(apiService: apiService),
        // '/settings': (context) => SettingScreen(apiService: apiService),
        // '/menu': (context) => MenuScreen(apiService: apiService),
        // '/billing': (context) => BillingScreen(apiService: apiService),
        // '/budget': (context) => BillingScreen(apiService: apiService),
        // '/delivery_notes': (context) => BillingScreen(apiService: apiService),
        // '/orders': (context) => BillingScreen(apiService: apiService),
      },
    );
  }
}
