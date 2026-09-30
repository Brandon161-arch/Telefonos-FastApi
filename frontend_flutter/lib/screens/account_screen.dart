import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../widgets/store_scaffold.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<Map<String, dynamic>?> _userFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _userFuture = _api.getSavedUser();
    _ordersFuture = _api.getMyOrders();
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'Mi cuenta',
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            final user = snapshot.data;
            if (user == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Inicia sesión para consultar tu cuenta y tus pedidos.'), const SizedBox(height: 12), FilledButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión'))]));
            return ListView(padding: const EdgeInsets.all(20), children: [
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hola, ${user['full_name'] ?? 'cliente'}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user['email']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  Text(user['is_verified'] == true ? 'Correo verificado' : 'Correo pendiente de verificación', style: TextStyle(color: user['is_verified'] == true ? Colors.greenAccent : Colors.orangeAccent)),
                  if (user['is_admin'] == true) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Administrador')),
                ]))),
                const SizedBox(height: 22),
                Text('Mis pedidos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ordersFuture,
                  builder: (context, ordersSnapshot) {
                    if (ordersSnapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                    if (ordersSnapshot.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text(ordersSnapshot.error.toString()));
                    final orders = ordersSnapshot.data ?? [];
                    if (orders.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Todavía no tienes pedidos.')));
                    return Column(children: orders.map((order) => Card(child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: Text(order['order_number']?.toString() ?? ''),
                      subtitle: Text('${order['status']} • ${order['created_at'] ?? ''}'),
                      trailing: Text(formatCop((order['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ))).toList());
                  },
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(onPressed: () async { await _api.logout(); if (context.mounted) context.go('/'); }, icon: const Icon(Icons.logout), label: const Text('Cerrar sesión')),
              ]))),
            ]);
          },
        ),
      );
}
