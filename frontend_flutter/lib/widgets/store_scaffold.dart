import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/cart_controller.dart';

class StoreScaffold extends StatelessWidget {
  const StoreScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().itemCount;
    final userFuture = context.read<ApiClient>().getSavedUser();
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.go('/'),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        actions: [
          IconButton(tooltip: 'Rastrear pedido', onPressed: () => context.go('/track'), icon: const Icon(Icons.local_shipping_outlined)),
          FutureBuilder<Map<String, dynamic>?>(
            future: userFuture,
            builder: (context, snapshot) {
              final isAdmin = snapshot.data?['is_admin'] == true;
              if (isAdmin) {
                return IconButton(tooltip: 'Panel admin', onPressed: () => context.go('/admin'), icon: const Icon(Icons.admin_panel_settings_outlined));
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(tooltip: 'Mi cuenta / iniciar sesión', onPressed: () => context.go('/account'), icon: const Icon(Icons.person_outline)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: IconButton(tooltip: 'Carrito', onPressed: () => context.go('/cart'), icon: const Icon(Icons.shopping_cart_outlined)),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}

String formatCop(num amount) {
  final whole = amount.round();
  final digits = whole.toString().split('').reversed.toList();
  final groups = <String>[];
  for (var i = 0; i < digits.length; i += 3) {
    groups.add(digits.skip(i).take(3).toList().reversed.join());
  }
  return '\$ ${groups.reversed.join('.')}';
}
