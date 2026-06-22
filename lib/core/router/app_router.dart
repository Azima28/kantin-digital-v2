import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/auth/screens/login_screen.dart';
import 'package:kantin_digital/features/auth/screens/splash_screen.dart';
import 'package:kantin_digital/features/auth/screens/unauthorized_screen.dart';
import 'package:kantin_digital/features/kantin/screens/pos_home_screen.dart';
import 'package:kantin_digital/features/kantin/screens/pos_dashboard_screen.dart';
import 'package:kantin_digital/features/kantin/screens/cart_screen.dart';
import 'package:kantin_digital/features/kantin/screens/manage_products_screen.dart';
import 'package:kantin_digital/features/kantin/screens/product_form_screen.dart';
import 'package:kantin_digital/features/kantin/screens/order_list_screen.dart';
import 'package:kantin_digital/features/kantin/screens/check_card_screen.dart';
import 'package:kantin_digital/features/kantin/screens/sales_history_screen.dart';
import 'package:kantin_digital/features/kantin/widgets/kantin_main_layout.dart';

import 'package:kantin_digital/features/siswa/screens/student_welcome_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_dashboard_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_topup_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_history_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_cards_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_profile_screen.dart';
import 'package:kantin_digital/features/siswa/screens/siswa_notifications_screen.dart';
import 'package:kantin_digital/features/siswa/widgets/siswa_main_layout.dart';
import 'package:kantin_digital/features/parent/screens/parent_dashboard_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_topup_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_receipt_screen.dart';
import 'package:kantin_digital/features/parent/screens/parent_portal_screen.dart';

import 'package:kantin_digital/features/admin/screens/secure_entry_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_dashboard_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_users_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_audit_log_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_settings_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_student_detail_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_merchant_detail_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_finance_detail_screen.dart';
import 'package:kantin_digital/features/admin/screens/admin_parent_detail_screen.dart';
import 'package:kantin_digital/features/admin/widgets/admin_main_layout.dart';

import 'package:kantin_digital/features/keuangan/screens/keuangan_dashboard_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_students_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_student_detail_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_users_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_card_registration_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_topup_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_correction_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_history_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_report_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_profile_screen.dart';
import 'package:kantin_digital/features/keuangan/screens/keuangan_settings_screen.dart';
import 'package:kantin_digital/features/keuangan/widgets/keuangan_main_layout.dart';
import 'package:kantin_digital/features/public/screens/public_home_screen.dart';
import 'package:kantin_digital/features/public/screens/public_menu_screen.dart';
import 'package:kantin_digital/features/public/screens/public_school_info_screen.dart';
import 'package:kantin_digital/core/models/models.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String unauthorized = '/unauthorized';
  
  // Student App Routes
  static const String studentWelcome = '/welcome';
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
  static const String posOrders = '/pos/orders';
  static const String posCheckCard = '/pos/check-card';
  static const String posManageProducts = '/pos/products';
  static const String posAddEditProduct = '/pos/products/form';
  static const String posHistorySales = '/pos/sales';

  // Super Admin App Routes
  static const String adminSecureEntry = '/admin/secure-entry';
  static const String adminHome = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminAudit = '/admin/audit';
  static const String adminSettings = '/admin/settings';
  static const String adminStudentDetail = '/admin/users/student/:studentId';
  static const String adminMerchantDetail = '/admin/users/merchant/:merchantId';
  static const String adminFinanceDetail = '/admin/users/finance/:officerId';
  static const String adminParentDetail = '/admin/users/parent/:parentId';

  // Keuangan App Routes
  static const String financeHome = '/finance';
  static const String financeStudents = '/finance/students';
  static const String financeUsers = '/finance/users';
  static const String financeStudentDetail = '/finance/students/:studentId';
  static const String financeCardReg = '/finance/students/:studentId/card';
  static const String financeMerchantDetail = '/finance/users/merchant/:merchantId';
  static const String financeParentDetail = '/finance/users/parent/:parentId';
  static const String financeTopUp = '/finance/topup';
  static const String financeCorrection = '/finance/correction';
  static const String financeHistory = '/finance/history';
  static const String financeReport = '/finance/report';
  static const String financeProfile = '/finance/profile';
  static const String financeSettings = '/finance/settings';

  // Public (No Auth Required)
  static const String publicHome = '/public';
  static const String publicMenu = '/public/menu';
  static const String publicInfo = '/public/info';
}

/// Role constants used for route guard checks.
const Set<String> _adminRoles = {'super_admin', 'admin'};
const Set<String> _keuanganRoles = {'petugas_keuangan'};
const Set<String> _canteenRoles = {'petugas_kantin'};
const Set<String> _studentRoles = {'student'};
const Set<String> _parentRoles = {'parent'};

/// Provider for GoRouter with authentication route guards.
///
/// Uses a [ValueNotifier] as [refreshListenable] so that GoRouter re-evaluates
/// the [redirect] callback whenever auth state changes (without recreating
/// the entire router instance).
final routerProvider = Provider<GoRouter>((ref) {
  // Trigger GoRouter redirect re-evaluation when auth state changes
  final authListenable = ValueNotifier(0);

  ref.listen<AuthState>(authNotifierProvider, (_, __) {
    authListenable.value++;
  });

  return GoRouter(
    refreshListenable: authListenable,
    initialLocation: AppRouter.splash,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggedIn = authState.isAuthenticated;
      final role = authState.profile?['role'] as String?;

      final path = state.matchedLocation;

      // ─── Routes accessible without authentication ───
      final publicRoutes = <String>{
        AppRouter.splash,
        AppRouter.login,
        AppRouter.studentWelcome,
        AppRouter.studentLogin,
        AppRouter.publicHome,
        AppRouter.publicMenu,
        AppRouter.publicInfo,
        AppRouter.unauthorized,
      };
      final isPublicRoute = publicRoutes.contains(path) ||
          path.startsWith('/public/');

      // If NOT logged in and trying to access a protected route → /login
      if (!isLoggedIn && !isPublicRoute) {
        return AppRouter.login;
      }

      // If logged in and trying to visit login/splash → redirect to home
      if (isLoggedIn &&
          (path == AppRouter.login || path == AppRouter.splash)) {
        if (role == 'petugas_kantin') return AppRouter.posHome;
        if (role == 'student') return AppRouter.studentHome;
        if (role == 'super_admin' || role == 'admin') {
          return AppRouter.adminHome;
        }
        if (role == 'petugas_keuangan') return AppRouter.financeHome;
        if (role == 'parent') return AppRouter.parentHome;
        return AppRouter.publicHome;
      }

      // ─── Role-based access control ───
      if (isLoggedIn) {
        // Admin & super_admin routes
        if (path == AppRouter.adminSecureEntry ||
            path == AppRouter.adminHome ||
            path.startsWith('/admin/')) {
          if (!_adminRoles.contains(role)) {
            return AppRouter.unauthorized;
          }
        }

        // Keuangan routes
        if (path == AppRouter.financeHome ||
            path.startsWith('/finance/')) {
          if (!_keuanganRoles.contains(role)) {
            return AppRouter.unauthorized;
          }
        }

        // POS / Canteen routes
        if (path == AppRouter.posHome ||
            path.startsWith('/pos/')) {
          if (!_canteenRoles.contains(role)) {
            return AppRouter.unauthorized;
          }
        }

        // Student routes
        if (path == AppRouter.studentHome ||
            path.startsWith('/student/')) {
          if (!_studentRoles.contains(role)) {
            return AppRouter.unauthorized;
          }
        }

        // Parent routes
        if (path == AppRouter.parentHome ||
            path.startsWith('/parent/')) {
          if (!_parentRoles.contains(role)) {
            return AppRouter.unauthorized;
          }
        }
      }

      return null; // no redirect
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRouter.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.login,
        builder: (BuildContext context, GoRouterState state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(from: from);
        },
      ),
      GoRoute(
        path: AppRouter.unauthorized,
        builder: (BuildContext context, GoRouterState state) =>
            const UnauthorizedScreen(),
      ),

      // ─── Public Routes (Tanpa Login) ───
      GoRoute(
        path: AppRouter.publicHome,
        builder: (context, state) => const PublicHomeScreen(),
        routes: [
          GoRoute(
            path: 'menu',
            builder: (context, state) => const PublicMenuScreen(),
          ),
          GoRoute(
            path: 'info',
            builder: (context, state) => const PublicSchoolInfoScreen(),
          ),
        ],
      ),

      // Siswa Welcome & Login
      GoRoute(
        path: AppRouter.studentWelcome,
        builder: (BuildContext context, GoRouterState state) =>
            const StudentWelcomeScreen(),
      ),
      GoRoute(
        path: AppRouter.studentLogin,
        builder: (BuildContext context, GoRouterState state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(from: from);
        },
      ),

      // Parent Routes
      GoRoute(
        path: AppRouter.parentHome,
        builder: (BuildContext context, GoRouterState state) =>
            const ParentPortalScreen(),
      ),
      GoRoute(
        path: AppRouter.parentDashboard,
        builder: (BuildContext context, GoRouterState state) =>
            ParentDashboardScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.parentTopUp,
        builder: (BuildContext context, GoRouterState state) =>
            ParentTopUpScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.parentReceipt,
        builder: (BuildContext context, GoRouterState state) =>
            ParentReceiptScreen(
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
            path: AppRouter.studentHome,
            builder: (BuildContext context, GoRouterState state) =>
                const SiswaDashboardScreen(),
          ),
          GoRoute(
            path: AppRouter.studentHistory,
            builder: (BuildContext context, GoRouterState state) =>
                const SiswaHistoryScreen(),
          ),
          GoRoute(
            path: AppRouter.studentCards,
            builder: (BuildContext context, GoRouterState state) =>
                const SiswaCardsScreen(),
          ),
          GoRoute(
            path: AppRouter.studentProfile,
            builder: (BuildContext context, GoRouterState state) =>
                const SiswaProfileScreen(),
          ),
        ],
      ),

      // Siswa sub-pages (without bottom tab bar)
      GoRoute(
        path: AppRouter.studentTopUp,
        builder: (BuildContext context, GoRouterState state) =>
            const SiswaTopUpScreen(),
      ),
      GoRoute(
        path: AppRouter.studentNotifications,
        builder: (BuildContext context, GoRouterState state) =>
            const SiswaNotificationsScreen(),
      ),

      // POS Cashier Tab Pages (Beranda, Cek Kartu, Menu, Riwayat)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return KantinMainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRouter.posHome,
            builder: (BuildContext context, GoRouterState state) =>
                const PosHomeScreen(),
          ),
          GoRoute(
            path: AppRouter.posOrders,
            builder: (BuildContext context, GoRouterState state) =>
                const OrderListScreen(),
          ),
          GoRoute(
            path: AppRouter.posCheckCard,
            builder: (BuildContext context, GoRouterState state) =>
                const CheckCardScreen(),
          ),
          GoRoute(
            path: AppRouter.posManageProducts,
            builder: (BuildContext context, GoRouterState state) =>
                const ManageProductsScreen(),
          ),
          GoRoute(
            path: AppRouter.posHistorySales,
            builder: (BuildContext context, GoRouterState state) =>
                const SalesHistoryScreen(),
          ),
        ],
      ),
      
      // POS Canteen sub-pages (without bottom tab bar)
      GoRoute(
        path: AppRouter.posTerminal,
        builder: (BuildContext context, GoRouterState state) =>
            const PosDashboardScreen(),
      ),
      GoRoute(
        path: AppRouter.posCart,
        builder: (BuildContext context, GoRouterState state) =>
            const CartScreen(),
      ),
      GoRoute(
        path: AppRouter.posAddEditProduct,
        builder: (BuildContext context, GoRouterState state) =>
            ProductFormScreen(
          initialProduct: state.extra as Product?,
        ),
      ),

      // Super Admin Secure PIN/Biometric Entry
      GoRoute(
        path: AppRouter.adminSecureEntry,
        builder: (BuildContext context, GoRouterState state) =>
            const SecureEntryScreen(),
      ),

      // Super Admin Main tab layouts (Home, Users, Audit, Settings)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AdminMainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRouter.adminHome,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRouter.adminUsers,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminUsersScreen(),
          ),
          GoRoute(
            path: AppRouter.adminAudit,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminAuditLogScreen(),
          ),
          GoRoute(
            path: AppRouter.adminSettings,
            builder: (BuildContext context, GoRouterState state) =>
                const AdminSettingsScreen(),
          ),
        ],
      ),

      // Super Admin Sub-pages details
      GoRoute(
        path: AppRouter.adminStudentDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminStudentDetailScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.adminMerchantDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminMerchantDetailScreen(
          merchantId: state.pathParameters['merchantId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.adminFinanceDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminFinanceDetailScreen(
          officerId: state.pathParameters['officerId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.adminParentDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminParentDetailScreen(
          parentId: state.pathParameters['parentId']!,
        ),
      ),

      // Keuangan Main layout with bottom tabs
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return KeuanganMainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRouter.financeSettings,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganSettingsScreen(),
          ),
          GoRoute(
            path: AppRouter.financeHome,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganDashboardScreen(),
          ),
          GoRoute(
            path: AppRouter.financeStudents,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganStudentsScreen(),
          ),
          GoRoute(
            path: AppRouter.financeUsers,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganUsersScreen(),
          ),
          GoRoute(
            path: AppRouter.financeHistory,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganHistoryScreen(),
          ),
          GoRoute(
            path: AppRouter.financeReport,
            builder: (BuildContext context, GoRouterState state) =>
                const KeuanganReportScreen(),
          ),
        ],
      ),

      // Keuangan sub-pages (without bottom tab bar)
      GoRoute(
        path: AppRouter.financeStudentDetail,
        builder: (BuildContext context, GoRouterState state) =>
            KeuanganStudentDetailScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.financeCardReg,
        builder: (BuildContext context, GoRouterState state) =>
            KeuanganCardRegistrationScreen(
          studentId: state.pathParameters['studentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.financeMerchantDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminMerchantDetailScreen(
          merchantId: state.pathParameters['merchantId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.financeParentDetail,
        builder: (BuildContext context, GoRouterState state) =>
            AdminParentDetailScreen(
          parentId: state.pathParameters['parentId']!,
        ),
      ),
      GoRoute(
        path: AppRouter.financeTopUp,
        builder: (BuildContext context, GoRouterState state) {
          final student = state.extra as StudentWithProfile?;
          return KeuanganTopupScreen(prefilledStudent: student);
        },
      ),
      GoRoute(
        path: AppRouter.financeCorrection,
        builder: (BuildContext context, GoRouterState state) {
          final student = state.extra as StudentWithProfile?;
          return KeuanganCorrectionScreen(prefilledStudent: student);
        },
      ),
      GoRoute(
        path: AppRouter.financeProfile,
        builder: (BuildContext context, GoRouterState state) =>
            const KeuanganProfileScreen(),
      ),
    ],
  );
});
