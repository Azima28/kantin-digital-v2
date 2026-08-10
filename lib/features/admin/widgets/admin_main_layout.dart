import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';
import 'package:kantin_digital/core/widgets/premium_bottom_nav_bar.dart';
import 'package:kantin_digital/core/widgets/nebula_sidebar.dart';

class AdminMainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const AdminMainLayout({super.key, required this.child});

  @override
  ConsumerState<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends ConsumerState<AdminMainLayout> {
  final List<int> _tabHistory = [0];

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/users')) {
      return 1;
    } else if (location.startsWith('/admin/audit')) {
      return 2;
    } else if (location.startsWith('/admin/settings')) {
      return 3;
    } else if (location.startsWith('/admin/profile')) {
      return 4;
    }
    return 0; // default to /admin
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
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        context.go('/admin/audit');
        break;
      case 3:
        context.go('/admin/settings');
        break;
      case 4:
        context.go('/admin/profile');
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
            _buildSidebar(context, ref, selectedIndex),
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
          activeColor: Nebula.purple,
          items: const [
            PremiumBottomNavBarItem(
              icon: CupertinoIcons.square_grid_2x2,
              activeIcon: CupertinoIcons.square_grid_2x2_fill,
              label: 'Home',
            ),
            PremiumBottomNavBarItem(
              icon: CupertinoIcons.group,
              activeIcon: CupertinoIcons.group_solid,
              label: 'Users',
            ),
            PremiumBottomNavBarItem(
              icon: CupertinoIcons.doc_text,
              activeIcon: CupertinoIcons.doc_text_fill,
              label: 'Audit',
            ),
            PremiumBottomNavBarItem(
              icon: CupertinoIcons.settings,
              activeIcon: CupertinoIcons.settings_solid,
              label: 'Settings',
            ),
            PremiumBottomNavBarItem(
              icon: CupertinoIcons.person,
              activeIcon: CupertinoIcons.person_fill,
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


  Widget _buildSidebar(BuildContext context, WidgetRef ref, int selectedIndex) {
    return NebulaSidebar(
      headerIcon: CupertinoIcons.shield_fill,
      items: const [
        NebulaSidebarItemData(
          icon: CupertinoIcons.square_grid_2x2,
          activeIcon: CupertinoIcons.square_grid_2x2_fill,
          label: 'Beranda',
        ),
        NebulaSidebarItemData(
          icon: CupertinoIcons.group,
          activeIcon: CupertinoIcons.group_solid,
          label: 'Pengguna',
        ),
        NebulaSidebarItemData(
          icon: CupertinoIcons.doc_text,
          activeIcon: CupertinoIcons.doc_text_fill,
          label: 'Log Audit',
        ),
        NebulaSidebarItemData(
          icon: CupertinoIcons.settings,
          activeIcon: CupertinoIcons.settings_solid,
          label: 'Setelan',
        ),
        NebulaSidebarItemData(
          icon: CupertinoIcons.person,
          activeIcon: CupertinoIcons.person_fill,
          label: 'Akun Saya',
        ),
      ],
      selectedIndex: selectedIndex,
      onItemTapped: (index) => _onItemTapped(index, context),
      footerLabel: 'Super Admin',
      footerIcon: CupertinoIcons.shield_fill,
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