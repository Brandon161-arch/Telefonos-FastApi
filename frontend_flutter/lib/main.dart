import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'screens/account_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/track_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/api_client.dart';
import 'state/cart_controller.dart';

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
            GoRoute(path: '/phone/:slug', builder: (context, state) => ProductDetailScreen(slug: state.pathParameters['slug']!)),
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
            GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
            GoRoute(path: '/account', builder: (context, state) => const AccountScreen()),
            GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
            GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
            GoRoute(path: '/verify-email', builder: (context, state) => VerifyEmailScreen(token: state.uri.queryParameters['token'] ?? '')),
          ],
        );

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF818CF8);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
      surface: const Color(0xFF15182A),
      primary: const Color(0xFF818CF8),
      secondary: const Color(0xFF34D399),
    );
    return MaterialApp.router(
      title: 'ElectroPhone Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0B0D17),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF101322), centerTitle: false),
        cardTheme: CardThemeData(color: const Color(0xFF15182A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF15182A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
