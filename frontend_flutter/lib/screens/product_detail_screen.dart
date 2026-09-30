import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../models/store_review.dart';
import '../services/api_client.dart';
import '../state/cart_controller.dart';
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
    if (_commentController.text.trim().length < 3) return;
    setState(() => _submitting = true);
    try {
      await _api.addReview(phoneId, rating: _rating, comment: _commentController.text.trim());
      _commentController.clear();
      await _loadReviews(phoneId);
      if (mounted) _message('Reseña publicada. ¡Gracias!', isError: false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        if (mounted) context.push('/login');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
    ));
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'ElectroPhone',
        body: FutureBuilder<Phone>(
          future: _phoneFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || !snapshot.hasData) return Center(child: Text(snapshot.error?.toString() ?? 'No encontramos este teléfono.'));
            final phone = snapshot.data!;
            if (_reviewsLoading && _reviews.isEmpty) _loadReviews(phone.id);
            return _buildContent(phone);
          },
        ),
      );

  Widget _buildContent(Phone phone) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.arrow_back), label: const Text('Volver al catálogo')),
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final image = Container(
                  height: compact ? 300 : 470,
                  decoration: BoxDecoration(color: const Color(0xFF15182A), borderRadius: BorderRadius.circular(22)),
                  child: phone.imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.smartphone, size: 100, color: Colors.white30))
                      : Center(child: Image.network(phone.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.smartphone, size: 100, color: Colors.white30))),
                );
                final details = _productSummary(phone);
                return compact
                    ? Column(children: [image, const SizedBox(height: 24), details])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: image), const SizedBox(width: 32), Expanded(child: details)]);
              }),
              const SizedBox(height: 32),
              Text('Especificaciones', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 24, runSpacing: 18, children: [
                _spec('Procesador', phone.processor),
                _spec('Pantalla', '${phone.screenSize ?? '-'}" ${phone.screenType ?? ''}'),
                _spec('RAM', '${phone.ramGb} GB'),
                _spec('Almacenamiento', '${phone.storageGb} GB'),
                _spec('Color', phone.color),
                _spec('Cámara principal', '${phone.mainCameraMp ?? '-'} MP'),
                _spec('Cámara frontal', '${phone.frontCameraMp ?? '-'} MP'),
                _spec('Batería', '${phone.batteryMah ?? '-'} mAh'),
                _spec('Sistema operativo', phone.os),
              ]))),
              const SizedBox(height: 32),
              Text('Opiniones de clientes', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _reviewsSection(phone),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _productSummary(Phone phone) {
    final cart = context.read<CartController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(phone.brandName?.toUpperCase() ?? 'SMARTPHONE', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.3)),
      const SizedBox(height: 8),
      Text(phone.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Row(children: [const Icon(Icons.star, color: Color(0xFFFBBF24)), Text(' ${phone.rating.toStringAsFixed(1)} (${phone.ratingCount} reseñas)')]),
      const SizedBox(height: 16),
      Text(phone.description ?? 'Sin descripción disponible.', style: const TextStyle(color: Colors.white70, height: 1.5)),
      const SizedBox(height: 22),
      Text(formatCop(phone.currentPrice), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
      if (phone.discountPrice != null && phone.discountPrice! < phone.price)
        Text(formatCop(phone.price), style: const TextStyle(color: Colors.white54, decoration: TextDecoration.lineThrough)),
      const SizedBox(height: 12),
      _stockIndicator(phone),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: phone.stock > 0 ? () { cart.add(phone); _message('Agregado al carrito', isError: false); } : null,
            icon: Icon(phone.stock > 0 ? Icons.add_shopping_cart : Icons.block),
            label: Text(phone.stock > 0 ? 'Agregar al carrito' : 'Agotado'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'Guardar en favoritos',
          onPressed: () => _toggleFavorite(phone),
          icon: const Icon(Icons.favorite_border),
        ),
      ]),
    ]);
  }

  Future<void> _toggleFavorite(Phone phone) async {
    try {
      await _api.addFavorite(phone.id);
      if (mounted) _message('Guardado en favoritos', isError: false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        if (mounted) context.push('/login');
      } else if (e.statusCode == 400) {
        // Ya está en favoritos -> quitar
        try {
          await _api.removeFavorite(phone.id);
          if (mounted) _message('Eliminado de favoritos', isError: false);
        } catch (e2) {
          if (mounted) _message(e2.toString());
        }
      } else {
        if (mounted) _message(e.message);
      }
    } catch (e) {
      if (mounted) _message(e.toString());
    }
  }

  Widget _stockIndicator(Phone phone) {
    if (phone.stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error_outline, color: Colors.redAccent, size: 18), SizedBox(width: 6), Text('Sin disponibilidad por el momento', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600))]),
      );
    }
    if (phone.stock <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Text('¡Quedan pocas unidades! (${phone.stock})', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
      );
    }
    return Text('Disponible • ${phone.stock} unidades', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600));
  }

  Widget _spec(String title, String? value) => SizedBox(width: 210, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 4), Text(value?.isNotEmpty == true ? value! : 'N/D', style: const TextStyle(fontWeight: FontWeight.w600))]));

  Widget _reviewsSection(Phone phone) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_reviewsLoading) const LinearProgressIndicator(),
            if (!_reviewsLoading && _reviews.isEmpty) const Text('Todavía no hay reseñas. ¡Sé el primero en compartir tu opinión!'),
            ..._reviews.map((review) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(children: [Expanded(child: Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w700))), Text('${'★' * review.rating}${'☆' * (5 - review.rating)}', style: const TextStyle(color: Color(0xFFFBBF24)))]),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(review.comment)),
                )),
            const Divider(height: 30),
            Text('Deja una reseña', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 2, children: List.generate(5, (index) => IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: const Color(0xFFFBBF24)),
                ))),
            TextField(controller: _commentController, minLines: 3, maxLines: 5, maxLength: 2000, decoration: const InputDecoration(hintText: '¿Qué te pareció este teléfono?')),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _submitting ? null : () => _submitReview(phone.id),
              child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publicar reseña'),
            ),
            const SizedBox(height: 6),
            const Text('Debes iniciar sesión y verificar tu correo para publicar.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
}
