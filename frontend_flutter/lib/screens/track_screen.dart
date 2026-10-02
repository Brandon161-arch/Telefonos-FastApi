import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
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
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
    });
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
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'Rastreo de Pedidos',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                            child: Text('📦', style: TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Rastrear Estado de Pedido',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ingresa el código de orden enviado a tu correo (ej. ORD-ABC123XYZ)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Search Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _track(),
                          decoration: const InputDecoration(
                            hintText: 'ORD-XXXXXXXX',
                            prefixIcon: Icon(Icons.local_shipping_outlined,
                                color: AppColors.accent),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GradientButton(
                        width: 130,
                        onPressed: _loading ? null : _track,
                        child: Text(_loading ? 'Buscando...' : 'Consultar'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Error Card
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Order Result Card with Animated Entrance
                if (_order != null)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 350),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1.0 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: _buildOrderDetails(_order!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'pending';
    final items = (order['items'] as List<dynamic>? ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Número de Orden',
                      style:
                          TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    order['order_number']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 24),

          // 4-Step Animated Timeline
          _buildTimeline(status),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Shipping & Customer Info
          const Text('Detalles de Entrega',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 10),
          _infoRow('Cliente', order['customer_name'] ?? 'Cliente ElectroPhone'),
          _infoRow('Dirección',
              '${order['shipping_address'] ?? ''}, ${order['city'] ?? ''}'),
          _infoRow('Pago',
              '${order['payment_method'] ?? ''} • ${order['payment_status'] ?? ''}'),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Items List
          const Text('Artículos Comprados',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 12),
          ...items.map((item) {
            final map = item as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${map['phone_name']} (x${map['quantity']})',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13.5),
                    ),
                  ),
                  Text(
                    formatCop((map['subtotal'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pagado',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text(
                formatCop((order['total'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    const steps = [
      ('Recibido', 'pending'),
      ('Confirmado', 'processing'),
      ('En Camino', 'shipped'),
      ('Entregado', 'delivered'),
    ];

    int currentIndex = switch (currentStatus) {
      'delivered' => 3,
      'shipped' => 2,
      'processing' => 1,
      _ => 0,
    };

    if (currentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text('Este pedido ha sido cancelado.',
              style: TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          return Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.0, end: isCompleted ? 1.0 : 0.0),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : const Color(0x2EFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          );
        } else {
          final stepIndex = index ~/ 2;
          final isPassed = stepIndex <= currentIndex;
          final isCurrent = stepIndex == currentIndex;

          final circle = Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: isPassed ? AppColors.primaryGradient : null,
              color: isPassed ? null : const Color(0x14FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent ? AppColors.accent : AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                isPassed ? Icons.check : Icons.circle,
                size: 14,
                color: Colors.white,
              ),
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isCurrent
                  ? PulsingGlowRing(glowColor: AppColors.accent, child: circle)
                  : circle,
              const SizedBox(height: 6),
              Text(
                steps[stepIndex].$1,
                style: TextStyle(
                  color: isPassed ? Colors.white : AppColors.textDim,
                  fontSize: 11,
                  fontWeight: isPassed ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.textDim, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'shipped' => ('🚚 En camino', AppColors.accent),
      'delivered' => ('✓ Entregado', AppColors.success),
      'cancelled' => ('✗ Cancelado', AppColors.danger),
      'processing' => ('⚙️ Confirmado', AppColors.primary),
      _ => ('⏳ Recibido', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
