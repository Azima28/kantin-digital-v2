import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';

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
            const VerticalDivider(
              width: 0.5,
              thickness: 0.5,
              color: AppColors.borderGray,
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
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderGray, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (int index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.darkTeal,
            unselectedItemColor: AppColors.mutedGray,
            selectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 0,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house, size: 22),
                activeIcon: Icon(CupertinoIcons.house_fill, size: 22),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.group, size: 22),
                activeIcon: Icon(CupertinoIcons.group_solid, size: 22),
                label: AppStrings.adminUsers,
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.list_bullet, size: 22),
                activeIcon: Icon(CupertinoIcons.list_bullet, size: 22),
                label: AppStrings.labelTransaction,
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person, size: 22),
                activeIcon: Icon(CupertinoIcons.person_fill, size: 22),
                label: 'Akun',
              ),
            ],
          ),
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
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Admin Keuangan';
    final String school =
        authState.profile?['assigned_school'] ?? 'SMP Terpadu';

    return Container(
      width: 260,
      color: AppColors.white,
      child: Column(
        children: [
          // Sidebar Header (Logo & Title)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.money_rubl_circle_fill, // Finance/money icon
                    color: AppColors.darkTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KANTIN',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkTeal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'DIGITAL',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.nearBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderGray),
          const SizedBox(height: 16),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.house,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Beranda',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.group,
                  activeIcon: CupertinoIcons.group_solid,
                  label: AppStrings.adminUsers,
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.list_bullet,
                  activeIcon: CupertinoIcons.list_bullet,
                  label: AppStrings.labelTransaction,
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.person,
                  activeIcon: CupertinoIcons.person_fill,
                  label: 'Akun Saya',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
              ],
            ),
          ),

          // User Profile Card & Logout at bottom
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderGray),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nearBlack,
                        ),
                      ),
                      Text(
                        'Keuangan · $school',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.mutedGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.square_arrow_right,
                    color: AppColors.errorRed2,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirmed = await showLogoutConfirmationDialog(context);
                    if (confirmed) {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.darkTeal.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.darkTeal : AppColors.mutedGray,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.darkTeal : AppColors.nearBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
