import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_invoice_options.dart';
import 'package:saint_mobile/constants/saint_colors.dart';

class SaintAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final bool showLogout;
  final String? type;
  final Color? backgroundColor;

  const SaintAppbar({
    super.key,
    required this.title,
    this.leading,
    this.showLogout = false,
    this.type,
    this.backgroundColor,
  });

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  String _getTitle() {
    if (type != null) {
      final menuOption = menuOptions.firstWhere(
        (option) => option['type'] == type,
        orElse: () => {'title': 'Saint'},
      );
      return menuOption['title'] as String;
    }
    return 'Saint';
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        _getTitle(),
        style: const TextStyle(color: SaintColors.white),
      ),
      leading: leading,
      iconTheme: const IconThemeData(color: SaintColors.white),
      backgroundColor: backgroundColor ?? SaintColors.primary,
      actions: [
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            color: SaintColors.white,
            tooltip: 'Cerrar sesión',
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
