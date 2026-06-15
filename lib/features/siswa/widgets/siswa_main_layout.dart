import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

class SiswaMainLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final int selectedIndex = _getSelectedIndex(context);

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
}
