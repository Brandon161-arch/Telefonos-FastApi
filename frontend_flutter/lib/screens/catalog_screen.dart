import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../models/phone.dart';
import '../services/api_client.dart';
import '../widgets/phone_card.dart';
import '../widgets/store_scaffold.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _pageSize = 12;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final List<Phone> _phones = [];
  Timer? _debounce;
  String? _error;
  String _sort = 'created_at';
  int? _brandId;
  List<Brand> _brands = [];
  double? _minPrice;
  double? _maxPrice;
  int? _ramGb;
  int? _storageGb;
  bool? _is5g;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get _hasActiveFilters =>
      _brandId != null || _minPrice != null || _maxPrice != null || _ramGb != null || _storageGb != null || _is5g != null;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBrands();
    _load(reset: true);
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await _api.getBrands();
      if (mounted) setState(() => _brands = brands);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _phones.clear();
        _hasMore = true;
      });
    }
    try {
      final page = await _api.getPhones(
        skip: 0,
        limit: _pageSize,
        search: _searchController.text,
        brandId: _brandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        ramGb: _ramGb,
        storageGb: _storageGb,
        is5g: _is5g,
        sortBy: _sort,
      );
      final total = await _api.getPhoneCount(
        search: _searchController.text,
        brandId: _brandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        ramGb: _ramGb,
        storageGb: _storageGb,
        is5g: _is5g,
      );
      if (!mounted) return;
      setState(() {
        _phones
          ..clear()
          ..addAll(page);
        _total = total;
        _hasMore = _phones.length < _total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _api.getPhones(
        skip: _phones.length,
        limit: _pageSize,
        search: _searchController.text,
        brandId: _brandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        ramGb: _ramGb,
        storageGb: _storageGb,
        is5g: _is5g,
        sortBy: _sort,
      );
      if (!mounted) return;
      setState(() {
        _phones.addAll(page);
        _hasMore = _phones.length < _total;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'ElectroPhone',
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(child: _buildToolbar(context)),
            if (_error != null)
              SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))))
            else if (_loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
            else if (_phones.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('No encontramos teléfonos con esos criterios.')))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverToBoxAdapter(child: Text('$_total teléfonos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60))),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverLayoutBuilder(builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width > 1100 ? 4 : width > 720 ? 3 : width > 480 ? 2 : 1;
                  return SliverGrid.builder(
                    itemCount: _phones.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: width < 480 ? 0.92 : 0.68,
                    ),
                    itemBuilder: (context, index) => PhoneCard(phone: _phones[index]),
                  );
                }),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: _loadingMore ? const CircularProgressIndicator() : Text(_hasMore ? 'Desplázate para ver más' : 'Mostrando todo el catálogo', style: const TextStyle(color: Colors.white54))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFF282B50), Color(0xFF171A30)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ELECTROPHONE STORE', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text('Tu próximo smartphone\nestá aquí.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                const Text('Tecnología original, garantía y envíos en Colombia.', style: TextStyle(color: Colors.white70)),
              ]),
            ),
          ),
        ),
      );

  Widget _buildToolbar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchChanged,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar marca o modelo'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filtros',
                  onPressed: _openFilters,
                  icon: Badge(
                    isLabelVisible: _hasActiveFilters,
                    child: const Icon(Icons.tune),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(value: 'created_at', child: Text('Novedades')),
                    DropdownMenuItem(value: 'price_asc', child: Text('Menor precio')),
                    DropdownMenuItem(value: 'price_desc', child: Text('Mayor precio')),
                    DropdownMenuItem(value: 'rating', child: Text('Mejor valorados')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    _load(reset: true);
                  },
                ),
              ]),
              if (_brands.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _brandChip(null, 'Todas'),
                      ..._brands.map((b) => _brandChip(b.id, b.name)),
                    ],
                  ),
                ),
              ],
            ]),
          ),
        ),
      );

  Widget _brandChip(int? id, String label) {
    final selected = _brandId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _brandId = id);
          _load(reset: true);
        },
      ),
    );
  }

  Future<void> _openFilters() async {
    // Copias locales para no tocar el estado hasta aplicar
    double? minPrice = _minPrice;
    double? maxPrice = _maxPrice;
    int? ramGb = _ramGb;
    int? storageGb = _storageGb;
    bool? is5g = _is5g;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Filtros', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                TextButton(onPressed: () { setSheetState(() { minPrice = null; maxPrice = null; ramGb = null; storageGb = null; is5g = null; }); }, child: const Text('Limpiar')),
              ]),
              const SizedBox(height: 8),
              const Text('Precio máximo', style: TextStyle(color: Colors.white70)),
              Slider(
                value: maxPrice ?? 7000000,
                min: 1000000,
                max: 7000000,
                divisions: 12,
                label: maxPrice == null ? 'Sin límite' : formatCop(maxPrice!),
                onChanged: (v) => setSheetState(() => maxPrice = v),
              ),
              Text(maxPrice == null ? 'Sin límite' : 'Hasta ${formatCop(maxPrice!)}', style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              _chipRow<int?>(
                'RAM',
                const [6, 8, 12, 16],
                ramGb,
                (v) => setSheetState(() => ramGb = v),
                (v) => '$v GB',
              ),
              const SizedBox(height: 16),
              _chipRow<int?>(
                'Almacenamiento',
                const [128, 256, 512],
                storageGb,
                (v) => setSheetState(() => storageGb = v),
                (v) => '$v GB',
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo 5G'),
                value: is5g ?? false,
                onChanged: (v) => setSheetState(() => is5g = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = minPrice;
                      _maxPrice = maxPrice;
                      _ramGb = ramGb;
                      _storageGb = storageGb;
                      _is5g = is5g;
                    });
                    Navigator.pop(ctx);
                    _load(reset: true);
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chipRow<T>(String label, List<T> options, T? selected, ValueChanged<T?> onSelect, String Function(T) format) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, children: [
        for (final opt in options)
          ChoiceChip(
            label: Text(format(opt)),
            selected: selected == opt,
            onSelected: (_) => onSelect(selected == opt ? null : opt),
          ),
      ]),
    ]);
  }
}
