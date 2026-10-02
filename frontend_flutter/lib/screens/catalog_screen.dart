import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog.dart';
import '../models/phone.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
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
  double? _maxPrice = 7000000;
  int? _ramGb;
  int? _storageGb;
  bool? _is5g;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get _hasActiveFilters =>
      _brandId != null ||
      _minPrice != null ||
      (_maxPrice != null && _maxPrice! < 7000000) ||
      _ramGb != null ||
      _storageGb != null ||
      _is5g != null ||
      _searchController.text.isNotEmpty;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
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
        maxPrice: _maxPrice == 7000000 ? null : _maxPrice,
        ramGb: _ramGb,
        storageGb: _storageGb,
        is5g: _is5g,
        sortBy: _sort,
      );
      final total = await _api.getPhoneCount(
        search: _searchController.text,
        brandId: _brandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice == 7000000 ? null : _maxPrice,
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
        maxPrice: _maxPrice == 7000000 ? null : _maxPrice,
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
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _load(reset: true));
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _brandId = null;
      _minPrice = null;
      _maxPrice = 7000000;
      _ramGb = null;
      _storageGb = null;
      _is5g = null;
    });
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return StoreScaffold(
      title: 'ElectroPhone',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Section with Floating Phone animation
              _buildHero(context, screenWidth),

              // 2. Animated Brands Bar
              _buildBrandsSection(context),

              const SizedBox(height: 24),

              // 3. Main Catalog Area (Sidebar Filters + Products Grid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Sidebar Filters
                          SizedBox(
                            width: 280,
                            child: _buildFiltersSidebar(context),
                          ),
                          const SizedBox(width: 24),
                          // Right Catalog Grid
                          Expanded(
                            child:
                                _buildCatalogContent(context, screenWidth - 320),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildMobileToolbar(context),
                          const SizedBox(height: 16),
                          _buildCatalogContent(context, screenWidth),
                        ],
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HERO SECTION =================
  Widget _buildHero(BuildContext context, double width) {
    final isCompact = width < 850;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: EdgeInsets.all(isCompact ? 20 : 36),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
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
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroTag(),
                const SizedBox(height: 16),
                _heroHeading(),
                const SizedBox(height: 14),
                _heroParagraph(),
                const SizedBox(height: 20),
                _heroStats(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroTag(),
                      const SizedBox(height: 18),
                      _heroHeading(),
                      const SizedBox(height: 16),
                      _heroParagraph(),
                      const SizedBox(height: 24),
                      _heroStats(),
                    ],
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  flex: 4,
                  child: FloatingPhoneWidget(
                    child: _heroFeaturedCard(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚡', style: TextStyle(fontSize: 13)),
          SizedBox(width: 6),
          Text(
            'Ofertas de Temporada 2026 en Colombia',
            style: TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeading() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.2,
          letterSpacing: -0.8,
        ),
        children: [
          TextSpan(text: 'Los Últimos '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GradientText(
              'Smartphones',
              gradient: AppColors.primaryGradient,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          TextSpan(text: ' al Mejor Precio'),
        ],
      ),
    );
  }

  Widget _heroParagraph() {
    return const Text(
      'Descubre lo último en tecnología móvil: iPhone 15 Pro Max, Galaxy S24 Ultra, Xiaomi 14 y más con procesadores de última generación, cámaras profesionales y garantía en Colombia.',
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 14.5,
        height: 1.55,
      ),
    );
  }

  Widget _heroStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        _statBox('100%', 'Originales Libres'),
        _statBox('12 Meses', 'Garantía Directa'),
        _statBox('Envío Gratis', 'En pedidos > \$ 1.200.000'),
      ],
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFeaturedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGlow),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 190,
              width: double.infinity,
              color: const Color(0xFF0F1422),
              child: Image.network(
                'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.smartphone,
                      size: 72, color: AppColors.textDim),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'TOP VENTAS EN COLOMBIA',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'iPhone 15 Pro Max 256GB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$ 4.999.900',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BRANDS SECTION =================
  Widget _buildBrandsSection(BuildContext context) {
    if (_brands.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explora por Marca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Selecciona tu fabricante preferido',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _brandPill(null, 'Todas'),
                ..._brands.map((b) => _brandPill(b.id, b.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandPill(int? id, String name) {
    final selected = _brandId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          setState(() => _brandId = id);
          _load(reset: true);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📱', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FILTERS SIDEBAR (DESKTOP) =================
  Widget _buildFiltersSidebar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Limpiar',
                      style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Search inside filters
          TextField(
            controller: _searchController,
            onChanged: _searchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar modelo...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _load(reset: true);
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 20),

          // Price Range Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Precio Máximo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Slider(
                value: _maxPrice ?? 7000000,
                min: 1000000,
                max: 7000000,
                divisions: 12,
                activeColor: AppColors.primary,
                inactiveColor: const Color(0x2EFFFFFF),
                onChanged: (v) {
                  setState(() => _maxPrice = v);
                },
                onChangeEnd: (_) => _load(reset: true),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('\$ 1.000.000',
                      style:
                          TextStyle(color: AppColors.textDim, fontSize: 11.5)),
                  Text(
                    _maxPrice == null || _maxPrice == 7000000
                        ? 'Hasta \$ 7.000.000'
                        : formatCop(_maxPrice!),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 10),

          // 5G Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Solo celulares 5G ⚡',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5),
            ),
            value: _is5g ?? false,
            activeThumbColor: AppColors.accent,
            onChanged: (v) {
              setState(() => _is5g = v ? true : null);
              _load(reset: true);
            },
          ),

          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // RAM Filter
          _filterGroupTitle('Memoria RAM'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _radioChip('Todas', null, _ramGb,
                  (v) => setState(() {
                        _ramGb = v;
                        _load(reset: true);
                      })),
              _radioChip('6 GB', 6, _ramGb,
                  (v) => setState(() {
                        _ramGb = v;
                        _load(reset: true);
                      })),
              _radioChip('8 GB', 8, _ramGb,
                  (v) => setState(() {
                        _ramGb = v;
                        _load(reset: true);
                      })),
              _radioChip('12 GB', 12, _ramGb,
                  (v) => setState(() {
                        _ramGb = v;
                        _load(reset: true);
                      })),
              _radioChip('16 GB', 16, _ramGb,
                  (v) => setState(() {
                        _ramGb = v;
                        _load(reset: true);
                      })),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Storage Filter
          _filterGroupTitle('Almacenamiento'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _radioChip('Todos', null, _storageGb,
                  (v) => setState(() {
                        _storageGb = v;
                        _load(reset: true);
                      })),
              _radioChip('128 GB', 128, _storageGb,
                  (v) => setState(() {
                        _storageGb = v;
                        _load(reset: true);
                      })),
              _radioChip('256 GB', 256, _storageGb,
                  (v) => setState(() {
                        _storageGb = v;
                        _load(reset: true);
                      })),
              _radioChip('512 GB', 512, _storageGb,
                  (v) => setState(() {
                        _storageGb = v;
                        _load(reset: true);
                      })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterGroupTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
      ),
    );
  }

  Widget _radioChip<T>(
    String label,
    T? value,
    T? selectedValue,
    ValueChanged<T?> onSelected,
  ) {
    final isSelected = value == selectedValue;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ================= MOBILE TOOLBAR =================
  Widget _buildMobileToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Buscar teléfono o marca...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _openMobileFilters,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      isLabelVisible: _hasActiveFilters,
                      child: const Icon(Icons.tune, size: 18),
                    ),
                    const SizedBox(width: 6),
                    const Text('Filtros'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMobileFilters() async {
    double? maxPrice = _maxPrice;
    int? ramGb = _ramGb;
    int? storageGb = _storageGb;
    bool? is5g = _is5g;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtros Avanzados',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        maxPrice = 7000000;
                        ramGb = null;
                        storageGb = null;
                        is5g = null;
                      });
                    },
                    child: const Text('Restablecer',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Precio Máximo',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
              Slider(
                value: maxPrice ?? 7000000,
                min: 1000000,
                max: 7000000,
                divisions: 12,
                activeColor: AppColors.primary,
                onChanged: (v) => setSheetState(() => maxPrice = v),
              ),
              Text(
                maxPrice == null || maxPrice == 7000000
                    ? 'Sin límite'
                    : 'Hasta ${formatCop(maxPrice!)}',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo celulares 5G ⚡',
                    style: TextStyle(color: Colors.white)),
                value: is5g ?? false,
                activeThumbColor: AppColors.accent,
                onChanged: (v) => setSheetState(() => is5g = v ? true : null),
              ),
              const SizedBox(height: 16),
              GradientButton(
                onPressed: () {
                  setState(() {
                    _maxPrice = maxPrice;
                    _ramGb = ramGb;
                    _storageGb = storageGb;
                    _is5g = is5g;
                  });
                  Navigator.pop(ctx);
                  _load(reset: true);
                },
                child: const Text('Aplicar Filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= RIGHT CATALOG CONTENT =================
  Widget _buildCatalogContent(BuildContext context, double availableWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Topbar (Count + Sort)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loading
                    ? 'Cargando catálogo...'
                    : '$_total smartphone${_total == 1 ? '' : 's'} disponible${_total == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Ordenar: ',
                    style: TextStyle(color: AppColors.textDim, fontSize: 13),
                  ),
                  DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.bgSecondary,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.textMuted),
                    items: const [
                      DropdownMenuItem(
                          value: 'created_at',
                          child: Text('Novedades',
                              style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'price_asc',
                          child: Text('Precio: Menor a Mayor',
                              style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'price_desc',
                          child: Text('Precio: Mayor a Menor',
                              style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(
                          value: 'rating',
                          child: Text('Mejor Valorados',
                              style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _sort = val);
                      _load(reset: true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Skeleton Shimmer Loading or States
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => _load(reset: true),
                    child: const Text('Reintentar')),
              ],
            ),
          )
        else if (_loading)
          _buildShimmerGrid()
        else if (_phones.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 56, color: AppColors.textDim),
                const SizedBox(height: 16),
                const Text(
                  'No se encontraron teléfonos con esos criterios',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Intenta cambiar los filtros de precio, RAM o almacenamiento.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: _resetFilters,
                  child: const Text('Limpiar todos los filtros'),
                ),
              ],
            ),
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final cols = w > 1000 ? 3 : w > 650 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _phones.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: w < 650 ? 0.95 : 0.68,
                ),
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 250 + (index % 6) * 50),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1.0 - value) * 15),
                          child: child,
                        ),
                      );
                    },
                    child: PhoneCard(phone: _phones[index]),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Text(
                      _hasMore
                          ? 'Desplázate para ver más productos'
                          : '✓ Has llegado al final del catálogo',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 13),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w > 1000 ? 3 : w > 650 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: w < 650 ? 0.95 : 0.68,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: ShimmerLoadingBox(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  ShimmerLoadingBox(width: 80, height: 12),
                  SizedBox(height: 8),
                  ShimmerLoadingBox(width: 160, height: 16),
                  SizedBox(height: 8),
                  ShimmerLoadingBox(width: 110, height: 12),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoadingBox(width: 100, height: 20),
                      ShimmerLoadingBox(width: 36, height: 36, borderRadius: 10),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
