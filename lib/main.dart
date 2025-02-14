import 'package:flutter/material.dart';
import 'screens/billing_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  final apiService = ApiService();

  runApp(App(apiService: apiService));
}

class App extends StatelessWidget {
  final ApiService apiService;

  const App({
    super.key,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saint',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(apiService: apiService),
      // Add more routes as you build them
      routes: {
        '/login': (context) => LoginScreen(apiService: apiService),
        '/menu': (context) => MenuScreen(apiService: apiService),
        '/billing': (context) => BillingScreen(apiService: apiService),
        '/budget': (context) => BillingScreen(apiService: apiService),
        '/delivery_notes': (context) => BillingScreen(apiService: apiService),
        '/orders': (context) => BillingScreen(apiService: apiService),
      },
    );
  }
}
