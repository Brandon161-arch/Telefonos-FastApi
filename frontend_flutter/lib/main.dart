import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/track_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/api_client.dart';
import 'state/cart_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final cart = CartController()..load();
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: ElectroPhoneApp(api: api),
    ),
  );
}

class ElectroPhoneApp extends StatelessWidget {
  ElectroPhoneApp({super.key, required ApiClient api})
      : _router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const CatalogScreen()),
            GoRoute(
              path: '/phone/:slug',
              builder: (context, state) =>
                  ProductDetailScreen(slug: state.pathParameters['slug']!),
            ),
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
            GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
            GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
            GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
            GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
            GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
            GoRoute(
              path: '/verify-email',
              builder: (context, state) =>
                  VerifyEmailScreen(token: state.uri.queryParameters['token'] ?? ''),
            ),
          ],
        );

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ElectroPhone | Tienda Oficial de Smartphones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
