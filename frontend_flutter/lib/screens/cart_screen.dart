import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/cart_controller.dart';
import '../widgets/store_scaffold.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  String _payment = 'credit_card';
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose(); _address.dispose(); _city.dispose(); _postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final api = context.read<ApiClient>();
    return StoreScaffold(
      title: 'Tu carrito',
      body: cart.lines.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.remove_shopping_cart_outlined, size: 58), const SizedBox(height: 12), const Text('Tu carrito está vacío'), const SizedBox(height: 12), OutlinedButton(onPressed: () => context.go('/'), child: const Text('Ver catálogo'))]))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Productos', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  ...cart.lines.map((line) => Card(child: ListTile(
                    leading: SizedBox(width: 56, child: Image.network(line.phone.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.smartphone))),
                    title: Text(line.phone.name),
                    subtitle: Text('${formatCop(line.phone.currentPrice)} • ${line.phone.color}'),
                    trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                      IconButton(onPressed: () => cart.changeQuantity(line.phone.id, -1), icon: const Icon(Icons.remove_circle_outline)),
                      Text('${line.quantity}'),
                      IconButton(onPressed: () => cart.changeQuantity(line.phone.id, 1), icon: const Icon(Icons.add_circle_outline)),
                      IconButton(onPressed: () => cart.remove(line.phone.id), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                    ]),
                  ))),
                  const SizedBox(height: 18),
                  Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _summaryRow('Subtotal', cart.subtotal),
                    _summaryRow('Envío', cart.shipping, free: cart.shipping == 0),
                    const Divider(height: 24),
                    _summaryRow('Total', cart.total, bold: true),
                  ]))),
                  const SizedBox(height: 26),
                  Text('Datos de envío y pago', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Form(key: _formKey, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
                    _field(_name, 'Nombre completo'),
                    _field(_email, 'Correo electrónico', keyboard: TextInputType.emailAddress),
                    _field(_phone, 'Teléfono', keyboard: TextInputType.phone),
                    _field(_address, 'Dirección de envío'),
                    _field(_city, 'Ciudad'),
                    _field(_postal, 'Código postal / barrio', required: false),
                    DropdownButtonFormField<String>(
                      value: _payment,
                      decoration: const InputDecoration(labelText: 'Método de pago'),
                      items: const [
                        DropdownMenuItem(value: 'pse', child: Text('PSE')),
                        DropdownMenuItem(value: 'nequi', child: Text('Nequi / Daviplata')),
                        DropdownMenuItem(value: 'credit_card', child: Text('Tarjeta')),
                        DropdownMenuItem(value: 'cash_on_delivery', child: Text('Contra entrega')),
                      ],
                      onChanged: (value) { if (value != null) setState(() => _payment = value); },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: _submitting ? null : () => _checkout(cart, api),
                      icon: const Icon(Icons.lock_outline),
                      label: Text(_submitting ? 'Procesando…' : 'Confirmar pedido'),
                    )),
                  ])))),
                ]))),
              ],
            ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, bool free = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null))), Text(free ? 'Gratis' : formatCop(value), style: TextStyle(fontWeight: bold ? FontWeight.w900 : null, fontSize: bold ? 18 : null))]),
      );

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboard, bool required = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
          validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Este campo es obligatorio' : null,
        ),
      );

  Future<void> _checkout(CartController cart, ApiClient api) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final order = await api.createOrder({
        'customer_name': _name.text.trim(),
        'customer_email': _email.text.trim(),
        'customer_phone': _phone.text.trim(),
        'shipping_address': _address.text.trim(),
        'city': _city.text.trim(),
        'postal_code': _postal.text.trim(),
        'payment_method': _payment,
        'items': cart.lines.map((line) => {'phone_id': line.phone.id, 'quantity': line.quantity}).toList(),
      });
      await cart.clear();
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('¡Pedido realizado!'),
        content: Text('Tu código de seguimiento es ${order['order_number']}. Guarda este código para consultar tu pedido.'),
        actions: [TextButton(onPressed: () { Navigator.pop(dialogContext); context.go('/'); }, child: const Text('Volver a la tienda'))],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
