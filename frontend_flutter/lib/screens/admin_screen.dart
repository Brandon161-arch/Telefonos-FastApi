import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../services/api_client.dart';
import '../widgets/store_scaffold.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<OrderSummary>> _ordersFuture;
  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _ordersFuture = _api.getAdminOrders();
  }

  Future<void> _reload() async {
    setState(() => _ordersFuture = _api.getAdminOrders());
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'Panel de administración',
        body: FutureBuilder<List<OrderSummary>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 56),
                const SizedBox(height: 12),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión como administrador')),
              ])));
            }
            final orders = snapshot.data ?? [];
            return ListView(padding: const EdgeInsets.all(20), children: [
              Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Órdenes de la tienda', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${orders.length} órdenes registradas', style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                if (orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aún no hay órdenes registradas.'))),
                ...orders.map((order) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                    Text(order.customerName, style: const TextStyle(color: Colors.white60)),
                  ])),
                  Text(formatCop(order.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: order.status,
                    items: const ['pending', 'processing', 'shipped', 'delivered', 'cancelled'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      try {
                        await _api.changeOrderStatus(order.id, value);
                        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado'))); _reload(); }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                  ),
                ])))),
              ]))),
            ]);
          },
        ),
      );
}
