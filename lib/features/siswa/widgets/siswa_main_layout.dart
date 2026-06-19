import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class SiswaMainLayout extends ConsumerWidget {
  final Widget child;
  const SiswaMainLayout({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/student/history')) {
      return 1;
    } else if (location.startsWith('/student/cards')) {
      return 2;
    } else if (location.startsWith('/student/profile')) {
      return 3;
    }
    return 0; // default to /student
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/student');
        break;
      case 1:
        context.go('/student/history');
        break;
      case 2:
        context.go('/student/cards');
        break;
      case 3:
        context.go('/student/profile');
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
              child: child,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
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
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.house, size: 22),
              activeIcon: Icon(CupertinoIcons.house_fill, size: 22),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.clock, size: 22),
              activeIcon: Icon(CupertinoIcons.clock_fill, size: 22),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.creditcard, size: 22),
              activeIcon: Icon(CupertinoIcons.creditcard_fill, size: 22),
              label: 'Kartu',
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
    final String fullName = authState.profile?['full_name'] ?? 'Siswa';
    final String email = authState.profile?['email'] ?? '';

    return Container(
      width: 260,
      color: Colors.white,
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
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.square_grid_2x2_fill,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'KANTIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
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
                  icon: CupertinoIcons.house,
                  activeIcon: CupertinoIcons.house_fill,
                  label: 'Beranda',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.clock,
                  activeIcon: CupertinoIcons.clock_fill,
                  label: 'Riwayat',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.creditcard,
                  activeIcon: CupertinoIcons.creditcard_fill,
                  label: 'Kartu RFID',
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
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(CupertinoIcons.person, color: AppColors.primary, size: 18),
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
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext ctx) => CupertinoAlertDialog(
                        title: const Text('Keluar dari Akun'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun siswa ini?'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Batal'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref.read(authNotifierProvider.notifier).logout();
                              if (context.mounted) {
                                context.go('/welcome');
                              }
                            },
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
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
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textGray,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
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
