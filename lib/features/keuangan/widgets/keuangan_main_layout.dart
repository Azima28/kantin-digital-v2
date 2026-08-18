import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/widgets/premium_bottom_nav_bar.dart';
import 'package:kantin_digital/core/widgets/nebula_sidebar.dart';

class KeuanganMainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const KeuanganMainLayout({super.key, required this.child});

  @override
  ConsumerState<KeuanganMainLayout> createState() => _KeuanganMainLayoutState();
}

class _KeuanganMainLayoutState extends ConsumerState<KeuanganMainLayout> {
  final List<int> _tabHistory = [0];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/finance/settings')) {
      return 3;
    } else if (location.startsWith('/finance/students') || location.startsWith('/finance/users')) {
      return 1;
    } else if (location.startsWith('/finance/history')) {
      return 2;
    }
    return 0; // default to /finance (dashboard)
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
        context.go('/finance');
        break;
      case 1:
        context.go('/finance/users');
        break;
      case 2:
        context.go('/finance/history');
        break;
      case 3:
        context.go('/finance/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _getSelectedIndex(context);
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 768;

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
            _buildSidebar(context, selectedIndex),
            VerticalDivider(
              width: 0.5,
              thickness: 0.5,
              color: context.dividerCol,
            ),
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
          activeColor: Nebula.teal,
          items: const [
            PremiumBottomNavBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            PremiumBottomNavBarItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: AppStrings.adminUsers,
            ),
            PremiumBottomNavBarItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: AppStrings.labelTransaction,
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

    return PopScope(
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
    );
  }

  Widget _buildSidebar(BuildContext context, int selectedIndex) {
    return NebulaSidebar(
      headerIcon: CupertinoIcons.money_rubl_circle_fill,
      items: const [
        NebulaSidebarItemData(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Beranda',
        ),
        NebulaSidebarItemData(
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          label: 'Pengguna',
        ),
        NebulaSidebarItemData(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Transaksi',
        ),
        NebulaSidebarItemData(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Akun Saya',
        ),
      ],
      selectedIndex: selectedIndex,
      onItemTapped: (index) => _onItemTapped(index, context),
      footerLabel: 'Keuangan',
      footerIcon: Icons.account_balance_wallet_rounded,
      onLogout: () async {
        final confirmed = await showLogoutConfirmationDialog(context);
        if (confirmed) {
          await ref.read(authNotifierProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
    );
  }
}