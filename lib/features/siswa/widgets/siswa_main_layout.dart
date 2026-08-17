import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/widgets/premium_bottom_nav_bar.dart';
import 'package:kantin_digital/core/widgets/nebula_sidebar.dart';

class SiswaMainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const SiswaMainLayout({super.key, required this.child});

  @override
  ConsumerState<SiswaMainLayout> createState() => _SiswaMainLayoutState();
}

class _SiswaMainLayoutState extends ConsumerState<SiswaMainLayout> {
  final List<int> _tabHistory = [0];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/public/menu')) {
      return 1;
    } else if (location.startsWith('/student/active-orders')) {
      return 2;
    } else if (location.startsWith('/student/history')) {
      return 3;
    } else if (location.startsWith('/student/profile')) {
      return 4;
    }
    return 0; // default to /student
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
        context.go('/student');
        break;
      case 1:
        context.go('/public/menu');
        break;
      case 2:
        context.go('/student/active-orders');
        break;
      case 3:
        context.go('/student/history');
        break;
      case 4:
        context.go('/student/profile');
        break;
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
            _buildSidebar(context, ref, selectedIndex, sidebarW),
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
        bottomNavigationBar: Consumer(
          builder: (context, ref, child) {
            final activeOrdersCount = ref.watch(siswaActiveOrdersCountProvider);

            return PremiumBottomNavBar(
              currentIndex: selectedIndex,
              onTap: (int index) => _onItemTapped(index, context),
              items: [
                const PremiumBottomNavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Beranda',
                ),
                const PremiumBottomNavBarItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                  label: 'Menu',
                ),
                PremiumBottomNavBarItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Pesanan',
                  badgeCount: activeOrdersCount,
                ),
                const PremiumBottomNavBarItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history_rounded,
                  label: 'Riwayat',
                ),
                const PremiumBottomNavBarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Akun',
                ),
              ],
            );
          },
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


  Widget _buildSidebar(BuildContext context, WidgetRef ref, int selectedIndex, double sidebarWidth) {
    return NebulaSidebar(
      headerIcon: Icons.school_rounded,
      items: const [
        NebulaSidebarItemData(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Beranda',
        ),
        NebulaSidebarItemData(
          icon: Icons.grid_view_outlined,
          activeIcon: Icons.grid_view_rounded,
          label: 'Menu Kantin',
        ),
        NebulaSidebarItemData(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Pesanan',
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
      footerLabel: 'Siswa',
      footerIcon: Icons.school_rounded,
      onLogout: () async {
        final confirmed = await showLogoutConfirmationDialog(context);
        if (confirmed) {
          await ref.read(authNotifierProvider.notifier).logout();
          if (context.mounted) {
            context.go('/welcome');
          }
        }
      },
    );
  }
}

