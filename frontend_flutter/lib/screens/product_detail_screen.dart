import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../models/store_review.dart';
import '../services/api_client.dart';
import '../state/cart_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/store_scaffold.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Phone> _phoneFuture;
  List<StoreReview> _reviews = [];
  bool _reviewsLoading = true;
  bool _submitting = false;
  int _rating = 5;
  int _quantity = 1;
  final _commentController = TextEditingController();

  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _phoneFuture = _api.getPhone(widget.slug);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews(int id) async {
    setState(() => _reviewsLoading = true);
    try {
      final reviews = await _api.getReviews(id);
      if (mounted) setState(() { _reviews = reviews; _reviewsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _submitReview(int phoneId) async {
    if (_commentController.text.trim().length < 3) {
      _message('Escribe un comentario más detallado');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.addReview(
        phoneId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadReviews(phoneId);
      if (mounted) _message('¡Reseña publicada con éxito!', isError: false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        if (mounted) {
          _message('Inicia sesión para publicar tu reseña');
          context.push('/login');
        }
      } else {
        if (mounted) _message(e.message);
      }
    } catch (e) {
      if (mounted) _message(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'Detalles del Smartphone',
      body: FutureBuilder<Phone>(
        future: _phoneFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(80),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error?.toString() ?? 'No encontramos este teléfono.',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.go('/'), child: const Text('Volver a la tienda')),
                  ],
                ),
              ),
            );
          }

          final phone = snapshot.data!;
          if (_reviewsLoading && _reviews.isEmpty) _loadReviews(phone.id);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumb
                    _buildBreadcrumb(phone),
                    const SizedBox(height: 20),

                    // Top Image & Details (2 columns on desktop)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: _buildImageShowcase(phone)),
                                  const SizedBox(width: 36),
                                  Expanded(flex: 6, child: _buildMainInfo(phone)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildImageShowcase(phone),
                                  const SizedBox(height: 24),
                                  _buildMainInfo(phone),
                                ],
                              );
                      },
                    ),

                    const SizedBox(height: 36),

                    // Technical Specifications Grid
                    _buildSpecsGrid(phone),

                    const SizedBox(height: 28),

                    // Trust Guarantees Bar
                    _buildTrustBar(),

                    const SizedBox(height: 36),

                    // Customer Reviews Section
                    _buildReviewsSection(phone),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= BREADCRUMB =================
  Widget _buildBreadcrumb(Phone phone) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/'),
          child: const Text('Inicio', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        const Text('  /  ', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        if (phone.brandName != null) ...[
          Text(phone.brandName!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Text('  /  ', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
        ],
        Expanded(
          child: Text(
            phone.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ================= IMAGE SHOWCASE =================
  Widget _buildImageShowcase(Phone phone) {
    final hasDiscount = phone.discountPrice != null &&
        phone.discountPrice! > 0 &&
        phone.discountPrice! < phone.price;

    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1422),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: phone.imageUrl.isEmpty
                ? const Center(child: Icon(Icons.smartphone, size: 96, color: AppColors.textDim))
                : Image.network(
                    phone.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.smartphone, size: 96, color: AppColors.textDim),
                    ),
                  ),
          ),
          if (hasDiscount)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradientOrange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '🔥 OFERTA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================= MAIN INFO =================
  Widget _buildMainInfo(Phone phone) {
    final cart = context.read<CartController>();
    final hasDiscount = phone.discountPrice != null &&
        phone.discountPrice! > 0 &&
        phone.discountPrice! < phone.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges Row
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (phone.is5g)
              _badge('5G ULTRA', AppColors.accent),
            if (phone.isFeatured)
              _badge('DESTACADO', AppColors.primary),
            _badge('${phone.ramGb}GB RAM', Colors.white70),
            _badge('${phone.storageGb}GB', Colors.white70),
          ],
        ),

        const SizedBox(height: 12),

        // Brand
        Text(
          (phone.brandName ?? 'SMARTPHONE').toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        // Title
        Text(
          phone.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 10),

        // Rating
        Row(
          children: [
            const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(
              '${phone.rating > 0 ? phone.rating.toStringAsFixed(1) : '5.0'} (${phone.ratingCount} reseñas de compradores)',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          phone.description ?? 'Smartphone libre para cualquier operador en Colombia con garantía directa oficial.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14.5, height: 1.55),
        ),

        const SizedBox(height: 20),

        // Price Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDiscount) ...[
                Row(
                  children: [
                    Text(
                      formatCop(phone.price),
                      style: const TextStyle(
                        color: AppColors.textDim,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ahorras ${formatCop(phone.price - phone.currentPrice)}',
                        style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Text(
                formatCop(phone.currentPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'IVA incluido • Garantía oficial 12 meses • Envío seguro',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Stock indicator
        Row(
          children: [
            Icon(
              phone.stock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 18,
              color: phone.stock > 0 ? AppColors.success : AppColors.danger,
            ),
            const SizedBox(width: 6),
            Text(
              phone.stock > 0 ? 'Disponible — ${phone.stock} unidades en bodega' : 'Agotado temporalmente',
              style: TextStyle(
                color: phone.stock > 0 ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quantity + Add to cart Button
        if (phone.stock > 0)
          Row(
            children: [
              // Quantity Counter
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: _quantity < phone.stock ? () => setState(() => _quantity++) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Add to Cart Button
              Expanded(
                child: GradientButton(
                  height: 50,
                  onPressed: () {
                    for (int i = 0; i < _quantity; i++) {
                      cart.add(phone);
                    }
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Agregado(s) $_quantity x ${phone.name}'),
                        action: SnackBarAction(
                          label: 'Ir al carrito',
                          textColor: AppColors.accent,
                          onPressed: () => context.go('/cart'),
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.white),
                      SizedBox(width: 10),
                      Text('AGREGAR AL CARRITO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Este smartphone no está disponible en este momento.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  // ================= SPECS GRID =================
  Widget _buildSpecsGrid(Phone phone) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Especificaciones Técnicas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 700 ? 3 : constraints.maxWidth > 450 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _specTile('Procesador', phone.processor ?? 'Octa-Core de alto rendimiento'),
                  _specTile('Pantalla', '${phone.screenSize ?? 6.7}" ${phone.screenType ?? 'OLED 120Hz'}'),
                  _specTile('Memoria RAM', '${phone.ramGb} GB'),
                  _specTile('Almacenamiento', '${phone.storageGb} GB'),
                  _specTile('Color', phone.color.isNotEmpty ? phone.color : 'Estándar'),
                  _specTile('Cámara Principal', '${phone.mainCameraMp ?? 50} MP'),
                  _specTile('Cámara Frontal', '${phone.frontCameraMp ?? 12} MP'),
                  _specTile('Batería', '${phone.batteryMah ?? 5000} mAh'),
                  _specTile('Sistema Operativo', phone.os ?? 'Android / iOS'),
                  _specTile('Conectividad', phone.is5g ? '5G Ultra + Wi-Fi 6' : '4G LTE + Wi-Fi'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _specTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ================= TRUST GUARANTEES BAR =================
  Widget _buildTrustBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          return isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _trustItem('🚚 Envío Asegurado', 'A todas las ciudades de Colombia'),
                    _trustItem('🛡️ Garantía 12 Meses', 'Directa e IMEI legal homologado'),
                    _trustItem('🔒 Compra 100% Protegida', 'Pasarela segura con factura legal'),
                  ],
                )
              : Column(
                  children: [
                    _trustItem('🚚 Envío Asegurado', 'A todas las ciudades de Colombia'),
                    const SizedBox(height: 12),
                    _trustItem('🛡️ Garantía 12 Meses', 'Directa e IMEI legal homologado'),
                    const SizedBox(height: 12),
                    _trustItem('🔒 Compra 100% Protegida', 'Pasarela segura con factura legal'),
                  ],
                );
        },
      ),
    );
  }

  Widget _trustItem(String title, String desc) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
      ],
    );
  }

  // ================= REVIEWS SECTION =================
  Widget _buildReviewsSection(Phone phone) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                '⭐ Reseñas de Clientes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Text(
                '${_reviews.length} opiniones',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Add Review Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deja tu calificación sobre este smartphone:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFBBF24),
                        size: 26,
                      ),
                      onPressed: () => setState(() => _rating = star),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '¿Qué te pareció el rendimiento, batería, cámara o acabados del teléfono?',
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submitReview(phone.id),
                    child: Text(_submitting ? 'Publicando...' : 'Publicar Reseña'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Review List
          if (_reviewsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Sé el primero en dejar una reseña para este equipo.', style: TextStyle(color: AppColors.textDim)),
              ),
            )
          else
            Column(
              children: _reviews.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text('⭐' * r.rating, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.comment, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }
}
