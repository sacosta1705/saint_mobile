import 'package:flutter/material.dart';
import 'package:saint_mobile/constants/saint_colors.dart';

final List<Map<String, dynamic>> menuOptions = [
  {
    'type': 'A',
    'title': 'Facturación',
    'icon': Icons.receipt,
    'color': SaintColors.orange,
    'route': '/billing',
    'moduleKey': 'billing',
  },
  {
    'type': 'F',
    'title': 'Presupuesto',
    'icon': Icons.savings,
    'color': SaintColors.purple,
    'route': '/budget',
    'moduleKey': 'budget',
  },
  {
    'type': 'C',
    'title': 'Notas de entrega',
    'icon': Icons.delivery_dining,
    'color': SaintColors.yellow,
    'route': '/delivery_notes',
    'moduleKey': 'delivery_note',
  },
  {
    'type': 'E',
    'title': 'Pedidos',
    'icon': Icons.request_quote,
    'color': SaintColors.green,
    'route': '/orders',
    'moduleKey': 'orders',
  },
];
