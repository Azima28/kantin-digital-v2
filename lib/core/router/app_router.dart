import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/features/auth/screens/login_screen.dart';
import 'package:kantin_digital/features/auth/screens/splash_screen.dart';
import 'package:kantin_digital/features/kantin/screens/pos_home_screen.dart';
import 'package:kantin_digital/features/kantin/screens/pos_dashboard_screen.dart';
import 'package:kantin_digital/features/kantin/screens/cart_screen.dart';
import 'package:kantin_digital/features/kantin/screens/manage_products_screen.dart';
import 'package:kantin_digital/features/kantin/screens/product_form_screen.dart';
import 'package:kantin_digital/features/kantin/screens/check_card_screen.dart';
import 'package:kantin_digital/features/kantin/screens/sales_history_screen.dart';
import 'package:kantin_digital/features/kantin/widgets/kantin_main_layout.dart';

import 'package:kantin_digital/features/siswa/screens/student_welcome_screen.dart';
import 'package:kantin_digital/features/siswa/screens/student_login_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_dashboard_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_topup_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_history_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_cards_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_profile_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_notifications_screen.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_main_layout.dart';
import 'package:kantin_digital/features/parent/screens/parent_search_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_dashboard_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_topup_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_receipt_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  
  // Student App Routes
  static const String studentWelcome = '/student/welcome';
  static const String studentLogin = '/student/login';
  static const String studentHome = '/student';
  static const String studentTopUp = '/student/topup';
  static const String studentHistory = '/student/history';
  static const String studentCards = '/student/cards';
  static const String studentProfile = '/student/profile';
  static const String studentNotifications = '/student/notifications';

  // Parent App Routes
  static const String parentHome = '/parent';
  static const String parentDashboard = '/parent/dashboard/:studentId';
  static const String parentTopUp = '/parent/topup/:studentId';
  static const String parentReceipt = '/parent/receipt';

  // POS Canteen App Routes
  static const String posHome = '/pos';
  static const String posTerminal = '/pos/terminal';
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
      
      // Siswa Welcome & Login
      GoRoute(
        path: studentWelcome,
        builder: (BuildContext context, GoRouterState state) => const StudentWelcomeScreen(),
      ),
      GoRoute(
        path: studentLogin,
        builder: (BuildContext context, GoRouterState state) => const StudentLoginScreen(),
      ),

      // Parent Routes
      GoRoute(
        path: parentHome,
        builder: (BuildContext context, GoRouterState state) => const ParentSearchScreen(),
      ),
      GoRoute(
        path: parentDashboard,
        builder: (BuildContext context, GoRouterState state) => ParentDashboardScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: parentTopUp,
        builder: (BuildContext context, GoRouterState state) => ParentTopUpScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: parentReceipt,
        builder: (BuildContext context, GoRouterState state) => ParentReceiptScreen(
          receiptData: state.extra as Map<String, dynamic>,
        ),
      ),

      // Siswa Main layout with bottom tabs (Beranda, Riwayat, Kartu, Akun)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return SiswaMainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: studentHome,
            builder: (BuildContext context, GoRouterState state) => const SiswaDashboardScreen(),
          ),
          GoRoute(
            path: studentHistory,
            builder: (BuildContext context, GoRouterState state) => const SiswaHistoryScreen(),
          ),
          GoRoute(
            path: studentCards,
            builder: (BuildContext context, GoRouterState state) => const SiswaCardsScreen(),
          ),
          GoRoute(
            path: studentProfile,
            builder: (BuildContext context, GoRouterState state) => const SiswaProfileScreen(),
          ),
        ],
      ),

      // Siswa sub-pages (without bottom tab bar)
      GoRoute(
        path: studentTopUp,
        builder: (BuildContext context, GoRouterState state) => const SiswaTopUpScreen(),
      ),
      GoRoute(
        path: studentNotifications,
        builder: (BuildContext context, GoRouterState state) => const SiswaNotificationsScreen(),
      ),

      // POS Cashier Tab Pages (Beranda, Cek Kartu, Menu, Riwayat)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return KantinMainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: posHome,
            builder: (BuildContext context, GoRouterState state) => const PosHomeScreen(),
          ),
          GoRoute(
            path: posCheckCard,
            builder: (BuildContext context, GoRouterState state) => const CheckCardScreen(),
          ),
          GoRoute(
            path: posManageProducts,
            builder: (BuildContext context, GoRouterState state) => const ManageProductsScreen(),
          ),
          GoRoute(
            path: posHistorySales,
            builder: (BuildContext context, GoRouterState state) => const SalesHistoryScreen(),
          ),
        ],
      ),
      
      // POS Canteen sub-pages (without bottom tab bar)
      GoRoute(
        path: posTerminal,
        builder: (BuildContext context, GoRouterState state) => const PosDashboardScreen(),
      ),
      GoRoute(
        path: posCart,
        builder: (BuildContext context, GoRouterState state) => const CartScreen(),
      ),
      GoRoute(
        path: posAddEditProduct,
        builder: (BuildContext context, GoRouterState state) => ProductFormScreen(
          initialProduct: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
}
