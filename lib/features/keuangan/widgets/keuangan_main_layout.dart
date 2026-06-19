import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class KeuanganMainLayout extends ConsumerWidget {
  final Widget child;
  const KeuanganMainLayout({super.key, required this.child});

  static const Color primaryTeal = Color(0xFF003434);

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/finance/settings')) {
      return 4;
    } else if (location.startsWith('/finance/students')) {
      return 1;
    } else if (location.startsWith('/finance/users')) {
      return 1;
    } else if (location.startsWith('/finance/history')) {
      return 2;
    } else if (location.startsWith('/finance/report')) {
      return 3;
    }
    return 0; // default to /finance (dashboard)
  }

  void _onItemTapped(int index, BuildContext context) {
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
        context.go('/finance/report');
        break;
      case 4:
        context.go('/finance/settings');
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
            const VerticalDivider(
              width: 0.5,
              thickness: 0.5,
              color: Color(0xFFE4E2E1),
            ),
            // Right content
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE4E2E1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (int index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryTeal,
          unselectedItemColor: const Color(0xFF6F7978),
          selectedLabelStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(
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
              label: 'Pengguna',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet, size: 22),
              activeIcon: Icon(CupertinoIcons.list_bullet, size: 22),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar, size: 22),
              activeIcon: Icon(CupertinoIcons.chart_bar_fill, size: 22),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.gear, size: 22),
              activeIcon: Icon(CupertinoIcons.gear_solid, size: 22),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, int selectedIndex) {
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Admin Keuangan';
    final String school =
        authState.profile?['assigned_school'] ?? 'SMP Terpadu';

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
                    color: primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.money_rubl_circle_fill, // Finance/money icon
                    color: primaryTeal,
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
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryTeal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'DIGITAL',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1B1C1B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE4E2E1)),
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
                  label: 'Pengguna',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.list_bullet,
                  activeIcon: CupertinoIcons.list_bullet,
                  label: 'Transaksi',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.chart_bar,
                  activeIcon: CupertinoIcons.chart_bar_fill,
                  label: 'Laporan',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                const SizedBox(height: 8),
                _buildSidebarItem(
                  context: context,
                  icon: CupertinoIcons.gear,
                  activeIcon: CupertinoIcons.gear_solid,
                  label: 'Settings',
                  isSelected: selectedIndex == 4,
                  onTap: () => _onItemTapped(4, context),
                ),
              ],
            ),
          ),

          // User Profile Card & Logout at bottom
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE4E2E1)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryTeal.withValues(alpha: 0.1),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
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
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                      Text(
                        'Keuangan · $school',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          color: const Color(0xFF6F7978),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.square_arrow_right,
                    color: Color(0xFFBA1A1A),
                    size: 20,
                  ),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (BuildContext ctx) => CupertinoAlertDialog(
                        title: const Text('Keluar dari Akun'),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar dari akun keuangan ini?',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Batal'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/login');
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
            color: isSelected
                ? primaryTeal.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryTeal : const Color(0xFF6F7978),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? primaryTeal : const Color(0xFF1B1C1B),
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
