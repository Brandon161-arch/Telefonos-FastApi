import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../services/api_client.dart';
import '../state/cart_controller.dart';
import '../theme/app_theme.dart';
import 'store_scaffold.dart';

class PhoneCard extends StatefulWidget {
  const PhoneCard({
    super.key,
    required this.phone,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  final Phone phone;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  @override
  State<PhoneCard> createState() => _PhoneCardState();
}

class _PhoneCardState extends State<PhoneCard> {
  late bool _fav = widget.isFavorite;
  bool _togglingFav = false;

  Future<void> _toggleFavorite() async {
    if (_togglingFav) return;
    final api = context.read<ApiClient>();
    final user = await api.getSavedUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para guardar favoritos'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push('/login');
      }
      return;
    }

    setState(() => _togglingFav = true);
    try {
      if (_fav) {
        await api.removeFavorite(widget.phone.id);
        setState(() => _fav = false);
        widget.onFavoriteChanged?.call(false);
      } else {
        await api.addFavorite(widget.phone.id);
        setState(() => _fav = true);
        widget.onFavoriteChanged?.call(true);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _togglingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    final hasDiscount = widget.phone.discountPrice != null &&
        widget.phone.discountPrice! > 0 &&
        widget.phone.discountPrice! < widget.phone.price;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/phone/${widget.phone.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Presentation Box
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFF0F1422),
                      padding: const EdgeInsets.all(16),
                      child: widget.phone.imageUrl.isEmpty
                          ? const Center(
                              child: Icon(Icons.smartphone, size: 64, color: AppColors.textDim),
                            )
                          : Image.network(
                              widget.phone.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.smartphone, size: 64, color: AppColors.textDim),
                              ),
                            ),
                    ),

                    // Badges Top Left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Row(
                        children: [
                          if (hasDiscount) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradientOrange,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF97316).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                '🔥 Oferta',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (widget.phone.is5g)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
                              ),
                              child: const Text(
                                '⚡ 5G',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Favorite Button Top Right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _toggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              _fav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: _fav ? Colors.redAccent : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info & Price
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (widget.phone.brandName ?? 'SMARTPHONE').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Row(
                          children: [
                            const Text('⭐ ', style: TextStyle(fontSize: 11)),
                            Text(
                              widget.phone.rating > 0
                                  ? widget.phone.rating.toStringAsFixed(1)
                                  : '5.0',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Phone Name
                    Text(
                      widget.phone.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Specs Badges
                    Wrap(
                      spacing: 4,
                      children: [
                        _specChip('${widget.phone.ramGb}GB RAM'),
                        _specChip('${widget.phone.storageGb}GB'),
                        if (widget.phone.color.isNotEmpty)
                          _specChip(widget.phone.color),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price & Cart Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasDiscount)
                                Text(
                                  formatCop(widget.phone.price),
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11.5,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                formatCop(widget.phone.currentPrice),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Add to Cart Button
                        Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            gradient: widget.phone.stock > 0 ? AppColors.primaryGradient : null,
                            color: widget.phone.stock <= 0 ? const Color(0x1AFFFFFF) : null,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: widget.phone.stock > 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: widget.phone.stock > 0
                                  ? 'Agregar al carrito'
                                  : 'Agotado',
                              onPressed: widget.phone.stock > 0
                                  ? () {
                                      cart.add(widget.phone);
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Agregado: ${widget.phone.name}'),
                                          duration: const Duration(seconds: 2),
                                          action: SnackBarAction(
                                            label: 'Ver carrito',
                                            textColor: AppColors.accent,
                                            onPressed: () => context.go('/cart'),
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                widget.phone.stock > 0
                                    ? Icons.add_shopping_cart
                                    : Icons.remove_shopping_cart,
                                size: 18,
                                color: widget.phone.stock > 0
                                    ? Colors.white
                                    : AppColors.textDim,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
