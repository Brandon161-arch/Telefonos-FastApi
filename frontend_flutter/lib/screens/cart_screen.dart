import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/cart_controller.dart';
import '../theme/app_theme.dart';
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
  final _coupon = TextEditingController();

  String _payment = 'nequi';
  bool _submitting = false;
  String? _couponCode;
  double? _couponDiscount;
  bool _validatingCoupon = false;

  @override
  void initState() {
    super.initState();
    _prefillUser();
  }

  Future<void> _prefillUser() async {
    final api = context.read<ApiClient>();
    final user = await api.getSavedUser();
    if (user != null) {
      setState(() {
        if (_name.text.isEmpty) _name.text = user['full_name']?.toString() ?? '';
        if (_email.text.isEmpty) _email.text = user['email']?.toString() ?? '';
        if (_phone.text.isEmpty) _phone.text = user['phone_number']?.toString() ?? '';
        if (_address.text.isEmpty) _address.text = user['address']?.toString() ?? '';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _postal.dispose();
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(ApiClient api, double subtotal) async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingCoupon = true);
    try {
      final res = await api.validateCoupon(code, subtotal);
      final discount = (res['discount'] as num?)?.toDouble() ?? 0;
      if (!mounted) return;
      setState(() {
        _couponCode = code;
        _couponDiscount = discount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cupón aplicado! Descuento de ${formatCop(discount)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  Future<void> _submitCheckout(CartController cart, ApiClient api) async {
    if (!_formKey.currentState!.validate()) return;
    if (cart.lines.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final itemsPayload = cart.lines
          .map((line) => {
                'phone_id': line.phone.id,
                'quantity': line.quantity,
              })
          .toList();

      final orderData = await api.createOrder({
        'customer_name': _name.text.trim(),
        'customer_email': _email.text.trim(),
        'customer_phone': _phone.text.trim(),
        'shipping_address': _address.text.trim(),
        'city': _city.text.trim(),
        'postal_code': _postal.text.trim(),
        'payment_method': _payment,
        'coupon_code': _couponCode,
        'items': itemsPayload,
      });

      await cart.clear();

      if (!mounted) return;
      final orderNumber = orderData['order_number'] ?? 'ORD-COMPLETED';

      // Success Dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.bgSecondary,
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text('¡Pedido Confirmado!', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu compra ha sido registrada con éxito en ElectroPhone.', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Número de orden:', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                    Text(
                      '$orderNumber',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hemos enviado la confirmación y los detalles de envío a tu correo electrónico.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/track');
              },
              child: const Text('Rastrear mi pedido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final api = context.read<ApiClient>();

    return StoreScaffold(
      title: 'Tu Carrito',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: cart.lines.isEmpty
                ? _buildEmptyCart(context)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 850;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Carrito de Compras (${cart.itemCount} artículo${cart.itemCount == 1 ? '' : 's'})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => cart.clear(),
                                icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.danger),
                                label: const Text('Vaciar carrito', style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 6, child: _buildItemsList(cart)),
                                    const SizedBox(width: 32),
                                    Expanded(flex: 5, child: _buildCheckoutSummary(cart, api)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildItemsList(cart),
                                    const SizedBox(height: 24),
                                    _buildCheckoutSummary(cart, api),
                                  ],
                                ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  // ================= EMPTY CART =================
  Widget _buildEmptyCart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.textDim),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explora los smartphones más recientes con las mejores ofertas de Colombia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GradientButton(
              width: 220,
              onPressed: () => context.go('/'),
              child: const Text('EXPLORAR CATÁLOGO'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ITEMS LIST =================
  Widget _buildItemsList(CartController cart) {
    return Column(
      children: cart.lines.map((line) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Product thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1422),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: line.phone.imageUrl.isEmpty
                    ? const Icon(Icons.smartphone, color: AppColors.textDim)
                    : Image.network(
                        line.phone.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.smartphone, color: AppColors.textDim),
                      ),
              ),
              const SizedBox(width: 14),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.phone.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${line.phone.ramGb}GB / ${line.phone.storageGb}GB • ${line.phone.color}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCop(line.phone.currentPrice),
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.changeQuantity(line.phone.id, -1),
                    ),
                    Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cart.changeQuantity(line.phone.id, 1),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                tooltip: 'Eliminar del carrito',
                onPressed: () => cart.remove(line.phone.id),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ================= CHECKOUT & SUMMARY =================
  Widget _buildCheckoutSummary(CartController cart, ApiClient api) {
    final discount = _couponDiscount ?? 0;
    final finalTotal = (cart.total - discount).clamp(0, double.infinity).toDouble();

    return Column(
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen de Orden',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 14),
              _summaryLine('Subtotal', formatCop(cart.subtotal)),
              _summaryLine(
                'Envío nacional',
                cart.shipping == 0 ? 'GRATIS 🚚' : formatCop(cart.shipping),
                highlight: cart.shipping == 0,
              ),
              if (_couponDiscount != null)
                _summaryLine('Cupón ($_couponCode)', '- ${formatCop(_couponDiscount!)}', isDiscount: true),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total a Pagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(
                    formatCop(finalTotal),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Coupon Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _coupon,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'CUPÓN DE DESCUENTO',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _validatingCoupon ? null : () => _applyCoupon(api, cart.subtotal),
                    child: Text(_validatingCoupon ? '...' : 'Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Shipping Form & Payment
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos de Entrega y Facturación',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _field(_name, 'Nombre y Apellidos completos'),
                const SizedBox(height: 10),
                _field(_email, 'Correo electrónico para confirmación', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _field(_phone, 'Teléfono celular de contacto', keyboard: TextInputType.phone),
                const SizedBox(height: 10),
                _field(_address, 'Dirección exacta de entrega (Calle / Carrera / Apto)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_city, 'Ciudad / Municipio')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_postal, 'Barrio / Código Postal', required: false)),
                  ],
                ),
                const SizedBox(height: 14),

                // Payment Method Selector
                const Text('Método de Pago:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _payment,
                  dropdownColor: AppColors.bgSecondary,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                  items: const [
                    DropdownMenuItem(value: 'nequi', child: Text('📱 Nequi (Transferencia Directa)')),
                    DropdownMenuItem(value: 'daviplata', child: Text('📱 Daviplata')),
                    DropdownMenuItem(value: 'pse', child: Text('🏛️ PSE / Transferencia Bancaria')),
                    DropdownMenuItem(value: 'credit_card', child: Text('💳 Tarjeta de Crédito / Débito')),
                    DropdownMenuItem(value: 'cash_on_delivery', child: Text('💵 Pago Contra Entrega (Solo Bogotá)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _payment = val);
                  },
                ),

                const SizedBox(height: 20),

                // Submit Button
                GradientButton(
                  height: 52,
                  onPressed: _submitting ? null : () => _submitCheckout(cart, api),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_submitting) ...[
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 10),
                        const Text('PROCESANDO COMPRA...'),
                      ] else ...[
                        const Icon(Icons.lock_outline, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('CONFIRMAR Y FINALIZAR COMPRA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryLine(String label, String value, {bool highlight = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount
                  ? AppColors.danger
                  : highlight
                      ? AppColors.success
                      : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Este campo es obligatorio' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
