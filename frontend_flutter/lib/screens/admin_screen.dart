import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../models/phone.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/store_scaffold.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<AdminMetrics> _metricsFuture;
  late Future<List<Phone>> _phonesFuture;
  late Future<List<Brand>> _brandsFuture;
  late Future<List<OrderSummary>> _ordersFuture;
  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    _metricsFuture = _api.getAdminMetrics();
    _phonesFuture = _api.getPhones(limit: 100);
    _brandsFuture = _api.getBrands();
    _ordersFuture = _api.getAdminOrders();
  }

  void _reload() => setState(_reloadAll);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: StoreScaffold(
        title: 'Panel de Administración',
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚙️ Panel de Control',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Gestión de inventario, métricas de ventas y pedidos en tiempo real',
                            style: TextStyle(color: AppColors.textDim, fontSize: 13),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Recargar datos',
                        icon: const Icon(Icons.refresh, color: AppColors.accent),
                        onPressed: _reload,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // TabBar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      tabs: const [
                        Tab(text: '📊 Métricas & Ventas'),
                        Tab(text: '📱 Inventario'),
                        Tab(text: '📦 Órdenes & Pedidos'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 800,
                    child: TabBarView(
                      children: [
                        _buildMetricsTab(),
                        _buildInventoryTab(),
                        _buildOrdersTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= METRICS TAB =================
  Widget _buildMetricsTab() {
    return FutureBuilder<AdminMetrics>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        final m = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _metricCard('Ventas Totales', formatCop(m.totalRevenue), Icons.payments_outlined, AppColors.success),
                _metricCard('Órdenes Registradas', '${m.totalOrders}', Icons.receipt_long_outlined, AppColors.primary),
                _metricCard('Celulares en Catálogo', '${m.totalPhones}', Icons.smartphone, AppColors.accent),
                _metricCard('Marcas Activas', '${m.totalBrands}', Icons.business_outlined, const Color(0xFFF97316)),
                _metricCard('Clientes Registrados', '${m.totalUsers}', Icons.people_outline, const Color(0xFFEC4899)),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              '⚠️ Alertas de Stock Bajo (≤ 5 unidades)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (m.lowStockCount == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 12),
                    Text('Todo el inventario está en niveles óptimos de stock ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              ...m.lowStockItems.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber, color: AppColors.warning),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text('Quedan solo ${item['stock']} unidades disponibles', style: const TextStyle(color: AppColors.warning, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          formatCop((item['price'] as num?)?.toDouble() ?? 0),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  )),
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12.5)),
        ],
      ),
    );
  }

  // ================= INVENTORY TAB =================
  Widget _buildInventoryTab() {
    return FutureBuilder<List<Phone>>(
      future: _phonesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        final phones = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${phones.length} teléfonos registrados', style: const TextStyle(color: AppColors.textMuted)),
                FilledButton.icon(
                  onPressed: _openCreatePhoneDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Teléfono'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...phones.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1422),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: p.imageUrl.isEmpty
                            ? const Icon(Icons.smartphone, size: 24, color: AppColors.textDim)
                            : Image.network(p.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.smartphone)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('${p.brandName ?? 'Marca'} • Stock: ${p.stock} • ${p.ramGb}GB / ${p.storageGb}GB', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formatCop(p.currentPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Eliminar producto',
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: Text('¿Deseas eliminar permanentemente "${p.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _api.deletePhone(p.id);
                              _reload();
                            } catch (e) {
                              _showSnack(e.toString());
                            }
                          }
                        },
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ================= ORDERS TAB =================
  Widget _buildOrdersTab() {
    return FutureBuilder<List<OrderSummary>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
        final orders = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            Text('${orders.length} órdenes recibidas', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            ...orders.map((o) => Container(
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
                        child: const Icon(Icons.receipt_long, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.orderNumber, style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Cliente: ${o.customerName} • Pago: ${o.paymentMethod}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formatCop(o.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: o.status,
                        dropdownColor: AppColors.bgSecondary,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('⏳ Pendiente', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'processing', child: Text('⚙️ Confirmado', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'shipped', child: Text('🚚 En camino', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'delivered', child: Text('✓ Entregado', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'cancelled', child: Text('✗ Cancelado', style: TextStyle(fontSize: 12.5))),
                        ],
                        onChanged: (newStatus) async {
                          if (newStatus == null || newStatus == o.status) return;
                          try {
                            await _api.changeOrderStatus(o.id, newStatus);
                            _reload();
                          } catch (e) {
                            _showSnack(e.toString());
                          }
                        },
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _openCreatePhoneDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final ramCtrl = TextEditingController(text: '8');
    final storageCtrl = TextEditingController(text: '256');
    final colorCtrl = TextEditingController(text: 'Negro');
    final imageCtrl = TextEditingController();
    int? selectedBrand;
    bool is5g = true;

    final brands = await _brandsFuture;
    if (brands.isNotEmpty) selectedBrand = brands.first.id;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Agregar Smartphone', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedBrand,
                      dropdownColor: AppColors.bgSecondary,
                      decoration: const InputDecoration(labelText: 'Marca'),
                      items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      onChanged: (v) => setDialogState(() => selectedBrand = v),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del modelo'),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                      onChanged: (v) {
                        slugCtrl.text = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(labelText: 'Slug URL'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Precio (COP)'),
                            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock unidades'),
                            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ramCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'RAM (GB)'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: storageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Almacenamiento (GB)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: imageCtrl,
                      decoration: const InputDecoration(labelText: 'URL de Imagen (HTTPS)'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Conectividad 5G ⚡', style: TextStyle(color: Colors.white)),
                      value: is5g,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setDialogState(() => is5g = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await _api.createPhone({
                    'name': nameCtrl.text.trim(),
                    'slug': slugCtrl.text.trim(),
                    'brand_id': selectedBrand,
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                    'stock': int.tryParse(stockCtrl.text) ?? 0,
                    'ram_gb': int.tryParse(ramCtrl.text) ?? 8,
                    'storage_gb': int.tryParse(storageCtrl.text) ?? 256,
                    'color': colorCtrl.text.trim(),
                    'image_url': imageCtrl.text.trim(),
                    'is_5g': is5g,
                  });
                  if (!mounted) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  _reload();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
