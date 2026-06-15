import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/features/auth/screens/login_screen.dart';
import 'package:kantin_digital/features/auth/screens/splash_screen.dart';

// Import placeholders/screens if they exist, otherwise we define inline mocks
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  
  // Siswa App Routes
  static const String studentHome = '/student';
  static const String studentTopUp = '/student/topup';
  static const String studentHistory = '/student/history';
  static const String studentCards = '/student/cards';
  static const String studentProfile = '/student/profile';
  static const String studentNotifications = '/student/notifications';

  // POS Canteen App Routes
  static const String posHome = '/pos';
  static const String posCart = '/pos/cart';
  static const String posCheckCard = '/pos/check-card';
  static const String posManageProducts = '/pos/products';
  static const String posAddEditProduct = '/pos/products/form';
  static const String posHistorySales = '/pos/sales';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: <RouteBase>[
      GoRoute(
        path: splash,
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      
      // Siswa Routes
      GoRoute(
        path: studentHome,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Siswa Dashboard'),
      ),
      GoRoute(
        path: studentTopUp,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Isi Saldo Siswa'),
      ),
      GoRoute(
        path: studentHistory,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Riwayat Jajan Siswa'),
      ),
      GoRoute(
        path: studentCards,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Manajemen Kartu Siswa'),
      ),
      GoRoute(
        path: studentProfile,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Profil Siswa'),
      ),
      GoRoute(
        path: studentNotifications,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Notifikasi Siswa'),
      ),

      // POS Cashier Routes
      GoRoute(
        path: posHome,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Beranda Kasir POS'),
      ),
      GoRoute(
        path: posCart,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Keranjang Belanja'),
      ),
      GoRoute(
        path: posCheckCard,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Cek Kartu Siswa'),
      ),
      GoRoute(
        path: posManageProducts,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Kelola Jajanan'),
      ),
      GoRoute(
        path: posAddEditProduct,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Form Jajanan'),
      ),
      GoRoute(
        path: posHistorySales,
        builder: (BuildContext context, GoRouterState state) => const _PlaceholderScreen(title: 'Rekap Penjualan'),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
