import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
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
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'Mi Cuenta',
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(80),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.textDim),
                    const SizedBox(height: 16),
                    const Text('Inicia sesión en ElectroPhone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Accede para ver tu historial de compras y pedidos activos.', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 20),
                    GradientButton(
                      width: 200,
                      onPressed: () => context.go('/login'),
                      child: const Text('INICIAR SESIÓN'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                (user['full_name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user['full_name']?.toString() ?? 'Cliente',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    if (user['is_admin'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.accent),
                                        ),
                                        child: const Text('ADMIN', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(user['email']?.toString() ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      user['is_verified'] == true ? Icons.verified : Icons.warning_amber,
                                      size: 14,
                                      color: user['is_verified'] == true ? AppColors.success : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user['is_verified'] == true ? 'Cuenta Verificada' : 'Correo pendiente de verificación',
                                      style: TextStyle(
                                        color: user['is_verified'] == true ? AppColors.success : AppColors.warning,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _api.logout();
                              if (context.mounted) context.go('/');
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            label: const Text('Salir'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Orders List Header
                    const Text(
                      '📦 Historial de Pedidos',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 14),

                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _ordersFuture,
                      builder: (context, ordersSnapshot) {
                        if (ordersSnapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        }
                        final orders = ordersSnapshot.data ?? [];
                        if (orders.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text('Aún no has realizado pedidos con esta cuenta.', style: TextStyle(color: AppColors.textMuted)),
                            ),
                          );
                        }

                        return Column(
                          children: orders.map((order) {
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
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0x14FFFFFF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_shipping_outlined, color: AppColors.accent, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order['order_number']?.toString() ?? '',
                                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Estado: ${order['status']} • Fecha: ${order['created_at']?.toString().split('T').first ?? ''}',
                                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatCop((order['total'] as num?)?.toDouble() ?? 0),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
