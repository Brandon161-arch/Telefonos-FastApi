import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../models/phone.dart';
import '../services/api_client.dart';
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
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: StoreScaffold(
          title: 'Panel de administración',
          body: Column(children: [
            const TabBar(tabs: [
              Tab(text: 'Métricas'),
              Tab(text: 'Inventario'),
              Tab(text: 'Órdenes'),
            ]),
            Expanded(
              child: TabBarView(children: [
                _metricsTab(),
                _inventoryTab(),
                _ordersTab(),
              ]),
            ),
          ]),
        ),
      );

  // ================= MÉTRICAS =================
  Widget _metricsTab() => FutureBuilder<AdminMetrics>(
        future: _metricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _error(snapshot.error.toString());
          final m = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 14, runSpacing: 14, children: [
                _metricCard('Ventas totales', formatCop(m.totalRevenue), Icons.payments_outlined),
                _metricCard('Órdenes', '${m.totalOrders}', Icons.receipt_long_outlined),
                _metricCard('Celulares', '${m.totalPhones}', Icons.smartphone),
                _metricCard('Marcas', '${m.totalBrands}', Icons.business_outlined),
                _metricCard('Usuarios', '${m.totalUsers}', Icons.people_outline),
              ]),
              const SizedBox(height: 24),
              Text('Stock bajo (≤5 unidades)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (m.lowStockCount == 0)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Todo el inventario está saludable ✅'))),
              ...m.lowStockItems.map((item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orangeAccent),
                      title: Text(item['name']?.toString() ?? ''),
                      subtitle: Text('Stock: ${item['stock']} unidades'),
                      trailing: Text(formatCop((item['price'] as num?)?.toDouble() ?? 0)),
                    ),
                  )),
            ]))),
          ]);
        },
      );

  Widget _metricCard(String label, String value, IconData icon) => SizedBox(
        width: 180,
        child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]))),
      );

  // ================= INVENTARIO =================
  Widget _inventoryTab() => FutureBuilder<List<Phone>>(
        future: _phonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _error(snapshot.error.toString());
          final phones = snapshot.data ?? [];
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Inventario de smartphones', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                FilledButton.icon(onPressed: () => _openPhoneForm(context, null, phones), icon: const Icon(Icons.add), label: const Text('Agregar celular')),
              ]),
              const SizedBox(height: 16),
              if (phones.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay celulares registrados.'))),
              ...phones.map((phone) => Card(
                    child: ListTile(
                      leading: SizedBox(width: 56, child: Image.network(phone.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.smartphone))),
                      title: Text(phone.name),
                      subtitle: Text('${phone.brandName ?? '-'} • ${phone.ramGb}GB/${phone.storageGb}GB • Stock: ${phone.stock}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(formatCop(phone.currentPrice), style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(tooltip: 'Editar', onPressed: () => _openPhoneForm(context, phone, phones), icon: const Icon(Icons.edit_outlined)),
                        IconButton(tooltip: 'Eliminar', onPressed: () => _confirmDeletePhone(phone), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                      ]),
                    ),
                  )),
            ]))),
          ]);
        },
      );

  Future<void> _confirmDeletePhone(Phone phone) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Eliminar celular'),
      content: Text('¿Eliminar "${phone.name}" del catálogo? Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
      ],
    ));
    if (ok != true) return;
    try {
      await _api.deletePhone(phone.id);
      if (mounted) { _reload(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Celular eliminado'))); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openPhoneForm(BuildContext context, Phone? phone, List<Phone> allPhones) async {
    final brands = await _brandsFuture;
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PhoneFormDialog(api: _api, phone: phone, brands: brands),
    );
    _reload();
  }

  // ================= ÓRDENES =================
  Widget _ordersTab() => FutureBuilder<List<OrderSummary>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _error(snapshot.error.toString());
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
                      _snack('Estado actualizado'); _reload();
                    } catch (e) {
                      _snack(e.toString());
                    }
                  },
                ),
              ])))),
            ]))),
          ]);
        },
      );

  Widget _error(String message) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.admin_panel_settings_outlined, size: 56),
    const SizedBox(height: 12),
    Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 12),
    FilledButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión como administrador')),
  ])));

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ================= FORMULARIO CREAR/EDITAR TELÉFONO =================
class _PhoneFormDialog extends StatefulWidget {
  const _PhoneFormDialog({required this.api, required this.brands, this.phone});
  final ApiClient api;
  final List<Brand> brands;
  final Phone? phone;

  @override
  State<_PhoneFormDialog> createState() => _PhoneFormDialogState();
}

class _PhoneFormDialogState extends State<_PhoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.phone?.name);
  late final _slug = TextEditingController(text: widget.phone?.slug);
  late final _price = TextEditingController(text: widget.phone?.price.toString());
  late final _discount = TextEditingController(text: widget.phone?.discountPrice?.toString());
  late final _stock = TextEditingController(text: widget.phone?.stock.toString() ?? '15');
  late final _ram = TextEditingController(text: widget.phone?.ramGb.toString() ?? '12');
  late final _storage = TextEditingController(text: widget.phone?.storageGb.toString() ?? '256');
  late final _color = TextEditingController(text: widget.phone?.color);
  late final _imageUrl = TextEditingController(text: widget.phone?.imageUrl);
  late final _description = TextEditingController(text: widget.phone?.description);
  late final _processor = TextEditingController(text: widget.phone?.processor);
  late final _battery = TextEditingController(text: widget.phone?.batteryMah?.toString());
  late final _mainCamera = TextEditingController(text: widget.phone?.mainCameraMp?.toString());
  late int? _brandId = widget.phone?.brandId ?? (widget.brands.isNotEmpty ? widget.brands.first.id : null);
  late bool _is5g = widget.phone?.is5g ?? true;
  late bool _featured = widget.phone?.isFeatured ?? false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _slug, _price, _discount, _stock, _ram, _storage, _color, _imageUrl, _description, _processor, _battery, _mainCamera]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final payload = <String, dynamic>{
      'brand_id': _brandId,
      'name': _name.text.trim(),
      'slug': _slug.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'price': double.parse(_price.text),
      'stock': int.parse(_stock.text),
      'ram_gb': int.parse(_ram.text),
      'storage_gb': int.parse(_storage.text),
      'color': _color.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'description': _description.text.trim(),
      'is_5g': _is5g,
      'is_featured': _featured,
    };
    if (_discount.text.trim().isNotEmpty) payload['discount_price'] = double.parse(_discount.text);
    if (_processor.text.trim().isNotEmpty) payload['processor'] = _processor.text.trim();
    if (_battery.text.trim().isNotEmpty) payload['battery_mah'] = int.parse(_battery.text);
    if (_mainCamera.text.trim().isNotEmpty) payload['main_camera_mp'] = int.parse(_mainCamera.text);

    try {
      if (widget.phone == null) {
        await widget.api.createPhone(payload);
      } else {
        await widget.api.updatePhone(widget.phone!.id, payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.phone != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar celular' : 'Agregar celular'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(_name, 'Nombre', required: true),
              _field(_slug, 'Slug (URL única)', required: true),
              Row(children: [
                Expanded(child: _field(_price, 'Precio (COP)', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_discount, 'Precio descuento')),
              ]),
              Row(children: [
                Expanded(child: _field(_stock, 'Stock', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_ram, 'RAM (GB)', required: true, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_storage, 'Almacenamiento (GB)', required: true, number: true)),
              ]),
              Row(children: [
                Expanded(child: _field(_color, 'Color', required: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_battery, 'Batería (mAh)', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_mainCamera, 'Cámara (MP)', number: true)),
              ]),
              _field(_processor, 'Procesador'),
              _field(_imageUrl, 'URL de imagen', required: true),
              _field(_description, 'Descripción', lines: 3),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _brandId,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: widget.brands.map((b) => DropdownMenuItem<int?>(value: b.id, child: Text(b.name))).toList(),
                onChanged: (value) => setState(() => _brandId = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conectividad 5G'),
                value: _is5g,
                onChanged: (v) => setState(() => _is5g = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Destacado'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Guardando…' : 'Guardar')),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = false, bool number = false, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          maxLines: lines,
          decoration: InputDecoration(labelText: label + (required ? ' *' : '')),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'Requerido' : null : null,
        ),
      );
}
