import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

import 'package:kantin_digital/core/widgets/premium_panel.dart';

class AdminMainLayout extends ConsumerWidget {
  final Widget child;
  const AdminMainLayout({super.key, required this.child});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = _getSelectedIndex(context);
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 768;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left sidebar
            _buildSidebar(context, ref, selectedIndex),
            const VerticalDivider(width: 0.5, thickness: 0.5, color: AppColors.borderLight),
            // Right content
            Expanded(
              child: PremiumPanel(
                isDesktop: true,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: PremiumPanel(
        isDesktop: false,
        child: child,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (int index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.darkTeal,
          unselectedItemColor: AppColors.textGray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_grid_2x2, size: 22),
              activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.group, size: 22),
              activeIcon: Icon(CupertinoIcons.group_solid, size: 22),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.doc_text, size: 22),
              activeIcon: Icon(CupertinoIcons.doc_text_fill, size: 22),
              label: 'Audit',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings, size: 22),
              activeIcon: Icon(CupertinoIcons.settings_solid, size: 22),
              label: 'Settings',
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

  Widget _buildSidebar(BuildContext context, WidgetRef ref, int selectedIndex) {
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Super Admin';
    final String email = authState.profile?['email'] ?? 'admin@kantindigital.com';

    return Container(
      width: 260,
      color: AppColors.white,
      child: Column(
        children: [
          // Sidebar Header
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
                  child: Icon(
                    CupertinoIcons.shield_fill,
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkTeal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'DIGITAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.square_grid_2x2,
                  activeIcon: CupertinoIcons.square_grid_2x2_fill,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.group,
                  activeIcon: CupertinoIcons.group_solid,
                  label: 'Users',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.doc_text,
                  activeIcon: CupertinoIcons.doc_text_fill,
                  label: 'Audit Log',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.settings,
                  activeIcon: CupertinoIcons.settings_solid,
                  label: 'Setelan Sistem',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.person,
                  activeIcon: CupertinoIcons.person_fill,
                  label: 'Akun Saya',
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4, context),
                ),
              ],
            ),
          ),

          // User Profile Card & Logout
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.darkTeal.withValues(alpha: 0.1),
                  child: Icon(CupertinoIcons.person_solid, color: AppColors.darkTeal, size: 18),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.square_arrow_right, color: AppColors.error, size: 20),
                  onPressed: () async {
                    final confirmed = await showLogoutConfirmationDialog(context);
                    if (confirmed) {
                      await ref.read(authNotifierProvider.notifier).logout();
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
            color: isSelected ? AppColors.darkTeal.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.darkTeal : AppColors.textGray,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.darkTeal : AppColors.textDark,
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
