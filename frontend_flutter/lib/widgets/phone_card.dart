import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../state/cart_controller.dart';
import 'store_scaffold.dart';

class PhoneCard extends StatelessWidget {
  const PhoneCard({super.key, required this.phone});
  final Phone phone;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/phone/${phone.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFF101322),
                    child: phone.imageUrl.isEmpty
                        ? const Icon(Icons.smartphone, size: 72, color: Colors.white30)
                        : Image.network(phone.imageUrl, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.smartphone, size: 72, color: Colors.white30)),
                  ),
                  if (phone.discountPrice != null && phone.discountPrice! < phone.price)
                    const Positioned(left: 10, top: 10, child: Chip(label: Text('Oferta'))),
                  if (phone.is5g)
                    const Positioned(right: 10, top: 10, child: Chip(label: Text('5G'))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone.brandName ?? 'Smartphone', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(phone.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('${phone.ramGb} GB RAM • ${phone.storageGb} GB', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(formatCop(phone.currentPrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      IconButton.filledTonal(
                        tooltip: 'Agregar al carrito',
                        onPressed: phone.stock > 0 ? () => cart.add(phone) : null,
                        icon: const Icon(Icons.add_shopping_cart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
