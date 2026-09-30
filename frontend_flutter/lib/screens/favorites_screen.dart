import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../services/api_client.dart';
import '../widgets/phone_card.dart';
import '../widgets/store_scaffold.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Phone>> _future;
  ApiClient get _api => context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _future = _api.getFavorites();
  }

  void _reload() => setState(() => _future = _api.getFavorites());

  void _snack(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'Mis favoritos',
        body: FutureBuilder<List<Phone>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) {
              return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite_border, size: 56),
                const SizedBox(height: 12),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => context.go('/login'), child: const Text('Iniciar sesión')),
              ])));
            }
            final phones = snapshot.data ?? [];
            if (phones.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                const Text('Aún no tienes favoritos.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/'), child: const Text('Explorar catálogo')),
              ]));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: phones.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : MediaQuery.of(context).size.width > 720 ? 3 : MediaQuery.of(context).size.width > 480 ? 2 : 1,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: MediaQuery.of(context).size.width < 480 ? 0.92 : 0.68,
              ),
              itemBuilder: (context, index) => Stack(children: [
                PhoneCard(phone: phones[index]),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Quitar de favoritos',
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      onPressed: () async {
                        try {
                          await _api.removeFavorite(phones[index].id);
                          if (mounted) { _reload(); _snack('Eliminado de favoritos'); }
                        } catch (e) {
                          if (mounted) _snack(e.toString());
                        }
                      },
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      );
}
