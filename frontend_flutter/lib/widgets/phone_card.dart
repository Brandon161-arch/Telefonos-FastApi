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

class _PhoneCardState extends State<PhoneCard>
    with SingleTickerProviderStateMixin {
  late bool _fav = widget.isFavorite;
  bool _togglingFav = false;
  bool _hovered = false;
  bool _pressed = false;

  late final AnimationController _heartController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _heartScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35), weight: 50),
    TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(covariant PhoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _fav = widget.isFavorite;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_togglingFav) return;
    final api = context.read<ApiClient>();
    final user = await api.getSavedUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inicia sesión para guardar favoritos'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Ingresar',
              textColor: AppColors.accent,
              onPressed: () => context.push('/login'),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _togglingFav = true);
    _heartController.forward(from: 0.0);
    try {
      if (_fav) {
        await api.removeFavorite(widget.phone.id);
        if (mounted) setState(() => _fav = false);
        widget.onFavoriteChanged?.call(false);
      } else {
        await api.addFavorite(widget.phone.id);
        if (mounted) setState(() => _fav = true);
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

    final cardScale = _pressed ? 0.98 : (_hovered ? 1.025 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: cardScale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgCardHover : AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered ? AppColors.borderGlow : AppColors.border,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : const Color(0x33000000),
                  blurRadius: _hovered ? 24 : 16,
                  offset: _hovered ? const Offset(0, 10) : const Offset(0, 6),
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
                    // Product Image Box
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            color: _hovered
                                ? const Color(0xFF131A2D)
                                : const Color(0xFF0F1422),
                            padding: const EdgeInsets.all(16),
                            child: widget.phone.imageUrl.isEmpty
                                ? const Center(
                                    child: Icon(Icons.smartphone,
                                        size: 64, color: AppColors.textDim),
                                  )
                                : Image.network(
                                    widget.phone.imageUrl,
                                    fit: BoxFit.contain,
                                    frameBuilder: (context, child, frame,
                                        wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                        child: child,
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.smartphone,
                                          size: 64, color: AppColors.textDim),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.accentGradientOrange,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF97316)
                                              .withValues(alpha: 0.4),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF06B6D4)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.6)),
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

                          // Favorite Heart Button with Pop Animation
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ScaleTransition(
                              scale: _heartScale,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _toggleFavorite,
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: Icon(
                                      _fav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 19,
                                      color: _fav
                                          ? const Color(0xFFF43F5E)
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Info & Price Area
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
                                (widget.phone.brandName ?? 'SMARTPHONE')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text('⭐ ',
                                      style: TextStyle(fontSize: 11)),
                                  Text(
                                    widget.phone.rating > 0
                                        ? widget.phone.rating
                                            .toStringAsFixed(1)
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

                          // Name
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

                          // Specs Chips
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

                          // Pricing and Add Button
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
                                          decoration:
                                              TextDecoration.lineThrough,
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

                              // Quick Add to Cart button with micro-animation
                              _AddToCartQuickButton(
                                phone: widget.phone,
                                onAdd: () {
                                  cart.add(widget.phone);
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: AppColors.success,
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                                'Agregado: ${widget.phone.name}'),
                                          ),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Ver carrito',
                                        textColor: AppColors.accent,
                                        onPressed: () => context.go('/cart'),
                                      ),
                                    ),
                                  );
                                },
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

class _AddToCartQuickButton extends StatefulWidget {
  const _AddToCartQuickButton({required this.phone, required this.onAdd});
  final Phone phone;
  final VoidCallback onAdd;

  @override
  State<_AddToCartQuickButton> createState() => _AddToCartQuickButtonState();
}

class _AddToCartQuickButtonState extends State<_AddToCartQuickButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final inStock = widget.phone.stock > 0;

    return GestureDetector(
      onTapDown: inStock ? (_) => setState(() => _pressed = true) : null,
      onTapUp: inStock
          ? (_) {
              setState(() => _pressed = false);
              widget.onAdd();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            gradient: inStock ? AppColors.primaryGradient : null,
            color: inStock ? null : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(10),
            boxShadow: inStock
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              inStock
                  ? Icons.add_shopping_cart
                  : Icons.remove_shopping_cart,
              size: 18,
              color: inStock ? Colors.white : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
