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

CustomTransitionPage<void> _buildPageTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: childWidget,
        ),
      );
    },
  );
}

class ElectroPhoneApp extends StatelessWidget {
  ElectroPhoneApp({super.key, required ApiClient api})
      : _router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const CatalogScreen(),
              ),
            ),
            GoRoute(
              path: '/phone/:slug',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: ProductDetailScreen(slug: state.pathParameters['slug']!),
              ),
            ),
            GoRoute(
              path: '/cart',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const CartScreen(),
              ),
            ),
            GoRoute(
              path: '/login',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const LoginScreen(),
              ),
            ),
            GoRoute(
              path: '/account',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const AccountScreen(),
              ),
            ),
            GoRoute(
              path: '/favorites',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const FavoritesScreen(),
              ),
            ),
            GoRoute(
              path: '/track',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const TrackScreen(),
              ),
            ),
            GoRoute(
              path: '/admin',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: const AdminScreen(),
              ),
            ),
            GoRoute(
              path: '/verify-email',
              pageBuilder: (context, state) => _buildPageTransition(
                key: state.pageKey,
                child: VerifyEmailScreen(
                  token: state.uri.queryParameters['token'] ?? '',
                ),
              ),
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
