import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/cart_controller.dart';
import '../theme/app_theme.dart';

class StoreScaffold extends StatelessWidget {
  const StoreScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showFooter = true,
  });

  final String title;
  final Widget body;
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().itemCount;
    final userFuture = context.read<ApiClient>().getSavedUser();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE60A0E17),
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Brand Logo with gentle hover scale
                      _BrandLogoButton(onTap: () => context.go('/')),

                      const Spacer(),

                      // Navigation Actions
                      if (!isMobile) ...[
                        _NavActionButton(
                          label: '📦 Rastrear',
                          onTap: () => context.go('/track'),
                        ),
                        const SizedBox(width: 4),
                        _NavActionButton(
                          label: '❤️ Favoritos',
                          onTap: () => context.go('/favorites'),
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: userFuture,
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final isAdmin = user?['is_admin'] == true;
                            if (isAdmin) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _NavActionButton(
                                  label: '⚙️ Admin',
                                  onTap: () => context.go('/admin'),
                                  isAccent: true,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: userFuture,
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            if (user != null) {
                              return _NavActionButton(
                                label:
                                    '👤 ${user['full_name']?.toString().split(' ').first ?? 'Mi Cuenta'}',
                                onTap: () => context.go('/account'),
                              );
                            }
                            return _NavActionButton(
                              label: '👤 Ingresar',
                              onTap: () => context.go('/login'),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        IconButton(
                          tooltip: 'Rastrear orden',
                          icon: const Icon(Icons.local_shipping_outlined,
                              size: 22),
                          onPressed: () => context.go('/track'),
                        ),
                        IconButton(
                          tooltip: 'Favoritos',
                          icon:
                              const Icon(Icons.favorite_border, size: 22),
                          onPressed: () => context.go('/favorites'),
                        ),
                        IconButton(
                          tooltip: 'Cuenta',
                          icon:
                              const Icon(Icons.person_outline, size: 22),
                          onPressed: () => context.go('/account'),
                        ),
                      ],

                      // Cart Action Button with Animated Scale Badge
                      _AnimatedCartButton(
                        cartCount: cartCount,
                        isMobile: isMobile,
                        onTap: () => context.go('/cart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: showFooter
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  body,
                  const StoreFooter(),
                ],
              ),
            )
          : body,
    );
  }
}

class _BrandLogoButton extends StatefulWidget {
  const _BrandLogoButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BrandLogoButton> createState() => _BrandLogoButtonState();
}

class _BrandLogoButtonState extends State<_BrandLogoButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: _hovered ? 0.6 : 0.4),
                        blurRadius: _hovered ? 14 : 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('📱', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                const Row(
                  children: [
                    Text(
                      'Electro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GradientText(
                      'Phone',
                      gradient: AppColors.primaryGradient,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavActionButton extends StatefulWidget {
  const _NavActionButton({
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  @override
  State<_NavActionButton> createState() => _NavActionButtonState();
}

class _NavActionButtonState extends State<_NavActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0x1FFFFFFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isAccent
                  ? AppColors.accent
                  : (_hovered ? Colors.white : AppColors.textMain),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCartButton extends StatefulWidget {
  const _AnimatedCartButton({
    required this.cartCount,
    required this.isMobile,
    required this.onTap,
  });

  final int cartCount;
  final bool isMobile;
  final VoidCallback onTap;

  @override
  State<_AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<_AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _bounceAnimation = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
    TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(
      parent: _bounceController, curve: Curves.easeOutCubic));

  bool _hovered = false;

  @override
  void didUpdateWidget(covariant _AnimatedCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartCount != widget.cartCount && widget.cartCount > 0) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.cartCount > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: hasItems ? AppColors.primaryGradient : null,
              color: hasItems
                  ? null
                  : (_hovered
                      ? const Color(0x33FFFFFF)
                      : const Color(0x1FFFFFFF)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: hasItems ? Colors.transparent : AppColors.border,
              ),
              boxShadow: hasItems
                  ? [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: _hovered ? 0.6 : 0.4),
                        blurRadius: _hovered ? 16 : 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 18, color: Colors.white),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    widget.isMobile
                        ? '${widget.cartCount}'
                        : 'Carrito (${widget.cartCount})',
                    key: ValueKey<int>(widget.cartCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _brandInfo(context)),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _quickLinks(context)),
                    const SizedBox(width: 32),
                    Expanded(flex: 3, child: _trustGuarantees()),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _paymentMethods()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _brandInfo(context),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _quickLinks(context),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _trustGuarantees(),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _paymentMethods(),
                  ],
                ),
              const SizedBox(height: 36),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      '© 2026 ElectroPhone Store Colombia. Todos los derechos reservados.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ),
                  Text(
                    '⚡ FastAPI + Flutter Web/Mobile',
                    style: TextStyle(
                      color: AppColors.accent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Text('📱', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
            const Text(
              'Electro',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            const GradientText(
              'Phone',
              gradient: AppColors.primaryGradient,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu tienda oficial de smartphones libres en Colombia. Equipos 100% originales con garantía oficial directa de 12 meses y envíos asegurados a todo el país.',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _quickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Navegación',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _footerLink('Catálogo de Smartphones', () => context.go('/')),
        _footerLink('Rastrear Pedido', () => context.go('/track')),
        _footerLink('Mis Favoritos', () => context.go('/favorites')),
        _footerLink('Mi Cuenta', () => context.go('/account')),
      ],
    );
  }

  Widget _trustGuarantees() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Garantías y Envíos',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        _guaranteeItem('🚚 Envíos Gratis',
            'En todos los pedidos superiores a \$ 1.200.000 COP.'),
        const SizedBox(height: 8),
        _guaranteeItem('🛡️ Garantía 12 Meses',
            'Directa con factura legal e IMEI registrado.'),
        const SizedBox(height: 8),
        _guaranteeItem('🔒 Compra Protegida',
            'Tus datos y transacciones 100% encriptados.'),
      ],
    );
  }

  Widget _paymentMethods() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medios de Pago',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PayBadge('Nequi'),
            _PayBadge('Daviplata'),
            _PayBadge('Bancolombia'),
            _PayBadge('PSE'),
            _PayBadge('Tarjetas'),
            _PayBadge('Contraentrega'),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _guaranteeItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 12.5)),
        Text(desc,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      ],
    );
  }
}

class _PayBadge extends StatelessWidget {
  const _PayBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Helper function to format numbers in Colombian Pesos ($ 4.999.900)
String formatCop(num amount) {
  final whole = amount.round();
  final digits = whole.toString().split('').reversed.toList();
  final groups = <String>[];
  for (var i = 0; i < digits.length; i += 3) {
    groups.add(digits.skip(i).take(3).toList().reversed.join());
  }
  return '\$ ${groups.reversed.join('.')}';
}
