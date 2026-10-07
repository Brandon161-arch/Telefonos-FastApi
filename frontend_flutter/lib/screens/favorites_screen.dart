import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/phone.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'Mis Favoritos',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '❤️ Smartphones Favoritos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Phone>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(60),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    }

                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 48, color: AppColors.accent),
                              const SizedBox(height: 12),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                              const SizedBox(height: 16),
                              GradientButton(
                                width: 180,
                                onPressed: () => context.go('/login'),
                                child: const Text('INICIAR SESIÓN'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final phones = snapshot.data ?? [];
                    if (phones.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_border, size: 64, color: AppColors.textDim),
                              const SizedBox(height: 16),
                              const Text(
                                'Aún no has guardado teléfonos en favoritos',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Guarda los teléfonos que más te interesen para comparar o comprar después.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 20),
                              GradientButton(
                                width: 200,
                                onPressed: () => context.go('/'),
                                child: const Text('EXPLORAR CATÁLOGO'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w > 1000 ? 4 : w > 700 ? 3 : w > 480 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: phones.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: w < 480 ? 0.95 : 0.68,
                          ),
                          itemBuilder: (context, index) => PhoneCard(
                            phone: phones[index],
                            isFavorite: true,
                            onFavoriteChanged: (_) => _reload(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
