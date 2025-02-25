import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:saint_mobile/constants/saint_colors.dart';
import 'package:saint_mobile/constants/saint_invoice_options.dart';
import 'package:saint_mobile/viewmodels/settings_viewmodel.dart';
import 'package:saint_mobile/views/widgets/responsive_layout.dart';
import 'package:saint_mobile/views/widgets/saint_appbar.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required String type,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: SaintColors.white,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SaintColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the settings viewmodel to check module access
    final settingsViewModel = Provider.of<SettingsViewmodel>(context);

    return Scaffold(
      appBar: const SaintAppbar(
        title: "Menu",
        showLogout: true,
      ),
      body: ResponsiveLayout(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;

            if (constraints.maxWidth < 600) {
              crossAxisCount = 2;
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 4;
            }

            // Filter menu options based on module access settings
            final filteredMenuOptions = menuOptions.where((option) {
              // Check if this option has a module access key
              final moduleKey = option['moduleKey'] as String?;
              if (moduleKey == null) {
                // If no moduleKey is defined, always show the option
                return true;
              }

              // Otherwise, check if the module is enabled in settings
              return settingsViewModel.getModuleAccess(moduleKey);
            }).toList();

            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              padding: const EdgeInsets.all(16),
              children: filteredMenuOptions.map(
                (option) {
                  return _buildMenuCard(
                    icon: option['icon'],
                    title: option['title'],
                    color: option['color'],
                    type: option['type'],
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        option['route'],
                        arguments: option,
                      );
                    },
                  );
                },
              ).toList(),
            );
          },
        ),
      ),
    );
  }
}
