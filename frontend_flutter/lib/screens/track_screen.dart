import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../widgets/store_scaffold.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _order;
  String? _error;
  bool _loading = false;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; _order = null; });
    try {
      final order = await _api.trackOrder(code);
      if (mounted) setState(() => _order = order);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'Rastrear pedido',
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Consulta el estado de tu pedido', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _track(),
                      decoration: const InputDecoration(hintText: 'ORD-XXXXXXXX', prefixIcon: Icon(Icons.local_shipping_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _loading ? null : _track, child: Text(_loading ? 'Buscando…' : 'Consultar')),
                ]),
                const SizedBox(height: 20),
                if (_error != null) Card(color: Theme.of(context).colorScheme.errorContainer, child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!))),
                if (_order != null) _orderCard(_order!),
              ]),
            ),
          ),
        ),
      );

  Widget _orderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>? ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order['order_number']?.toString() ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _statusBadge(order['status']?.toString() ?? 'processing'),
          const SizedBox(height: 14),
          Text('Cliente: ${order['customer_name'] ?? ''}'),
          Text('Dirección: ${order['shipping_address'] ?? ''}, ${order['city'] ?? ''}'),
          Text('Pago: ${order['payment_method'] ?? ''} (${order['payment_status'] ?? ''})'),
          const Divider(height: 24),
          ...items.map((item) {
            final itemMap = item as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text('${itemMap['phone_name']} x${itemMap['quantity']}')),
                Text(formatCop((itemMap['subtotal'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            );
          }),
          const Divider(height: 24),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            Text(formatCop((order['total'] as num?)?.toDouble() ?? 0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'shipped' => ('En camino', Colors.blueAccent),
      'delivered' => ('Entregado', Colors.greenAccent),
      'cancelled' => ('Cancelado', Colors.redAccent),
      'pending' => ('Pendiente', Colors.orangeAccent),
      _ => ('En proceso', Colors.amberAccent),
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)));
  }
}
