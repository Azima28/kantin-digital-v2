import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/widgets/premium_bottom_nav_bar.dart';
import 'package:kantin_digital/core/widgets/nebula_sidebar.dart';

class KantinMainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const KantinMainLayout({super.key, required this.child});

  @override
  ConsumerState<KantinMainLayout> createState() => _KantinMainLayoutState();
}

class _KantinMainLayoutState extends ConsumerState<KantinMainLayout> {
  final List<int> _tabHistory = [0];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pos/orders')) {
      return 1;
    } else if (location.startsWith('/pos/products')) {
      return 2;
    } else if (location.startsWith('/pos/sales')) {
      return 3;
    } else if (location.startsWith('/pos/profile')) {
      return 4;
    }
    return 0; // default to /pos
  }

  void _onItemTapped(int index, BuildContext context) {
    final int currentIndex = _getSelectedIndex(context);
    if (currentIndex == index) return;

    setState(() {
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });

    _navigateToTab(index, context);
  }

  void _navigateToTab(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/pos');
        break;
      case 1:
        context.go('/pos/orders');
        break;
      case 2:
        context.go('/pos/products');
        break;
      case 3:
        context.go('/pos/sales');
        break;
      case 4:
        context.go('/pos/profile');
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _getSelectedIndex(context);
    final bool isDesktop = Responsive.showSidebar(context);
    final double sidebarW = Responsive.sidebarWidth(context);

    // Sync external navigation changes with our history stack
    if (_tabHistory.isEmpty || _tabHistory.last != selectedIndex) {
      _tabHistory.remove(selectedIndex);
      _tabHistory.add(selectedIndex);
    }

    Widget mainWidget;
    if (isDesktop) {
      mainWidget = Scaffold(
        body: Row(
          children: [
            // Left sidebar
            _buildSidebar(context, selectedIndex, sidebarW),
            VerticalDivider(width: 0.5, thickness: 0.5, color: context.borderLight),
            // Right content
            Expanded(
              child: PremiumPanel(
                isDesktop: true,
                child: widget.child,
              ),
            ),
          ],
        ),
      );
    } else {
      mainWidget = Scaffold(
        body: PremiumPanel(
          isDesktop: false,
          child: widget.child,
        ),
        bottomNavigationBar: PremiumBottomNavBar(
          currentIndex: selectedIndex,
          onTap: (int index) => _onItemTapped(index, context),
          items: const [
            PremiumBottomNavBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            PremiumBottomNavBarItem(
              icon: Icons.shopping_bag_outlined,
              activeIcon: Icons.shopping_bag_rounded,
              label: 'Pesanan',
            ),
            PremiumBottomNavBarItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              label: 'Produk',
            ),
            PremiumBottomNavBarItem(
              icon: Icons.history_outlined,
              activeIcon: Icons.history_rounded,
              label: 'Riwayat',
            ),
            PremiumBottomNavBarItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Akun',
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PopScope(
          canPop: _tabHistory.length <= 1,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) return;
            if (_tabHistory.length > 1) {
              setState(() {
                _tabHistory.removeLast(); // Remove current tab
                final prevTab = _tabHistory.last;
                _navigateToTab(prevTab, context);
              });
            }
          },
          child: mainWidget,
        ),
      ],
    );
  }


  Widget _buildSidebar(BuildContext context, int selectedIndex, double sidebarWidth) {
    final authState = ref.watch(authNotifierProvider);
    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';

    return NebulaSidebar(
      headerIcon: Icons.storefront_rounded,
      items: const [
        NebulaSidebarItemData(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Beranda',
        ),
        NebulaSidebarItemData(
          icon: Icons.shopping_cart_outlined,
          activeIcon: Icons.shopping_cart_rounded,
          label: 'Kasir POS',
        ),
        NebulaSidebarItemData(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          label: 'Kelola Produk',
        ),
        NebulaSidebarItemData(
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          label: 'Riwayat',
        ),
        NebulaSidebarItemData(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Akun Saya',
        ),
      ],
      selectedIndex: selectedIndex,
      onItemTapped: (index) => _onItemTapped(index, context),
      footerLabel: canteenName,
      footerIcon: Icons.storefront_rounded,
      onLogout: () => _handleLogout(context),
    );
  }
}
