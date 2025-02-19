import 'package:flutter/material.dart';
import 'package:saint_mobile/helpers/settings_helper.dart';
import 'package:saint_mobile/screens/initial_setup_screen.dart';
import 'package:saint_mobile/screens/setting_screen.dart';
import 'package:saint_mobile/screens/setup_check_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  final settingsHelper = SettingsHelper();

  runApp(App(
    apiService: apiService,
    settingsHelper: settingsHelper,
  ));
}

class App extends StatelessWidget {
  final ApiService apiService;
  final SettingsHelper settingsHelper;

  const App({
    super.key,
    required this.apiService,
    required this.settingsHelper,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saint',
      debugShowCheckedModeBanner: false,
      home: SetupCheckScreen(
        settingsHelper: settingsHelper,
        onSetupComplete: (context) => LoginScreen(apiService: apiService),
        onSetupNeeded: (context) => InitialSetupScreen(
          settingsHelper: settingsHelper,
          onSetupComplete: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoginScreen(apiService: apiService),
              ),
            );
          },
        ),
      ),
      routes: {
        '/login': (context) => LoginScreen(apiService: apiService),
        '/settings': (context) => SettingScreen(apiService: apiService),
        '/menu': (context) => MenuScreen(apiService: apiService),
        '/billing': (context) => BillingScreen(apiService: apiService),
        '/budget': (context) => BillingScreen(apiService: apiService),
        '/delivery_notes': (context) => BillingScreen(apiService: apiService),
        '/orders': (context) => BillingScreen(apiService: apiService),
      },
    );
  }
}
