import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _redirectAfterSplash(AuthState authState) {
    if (!mounted) return;
    try {
      if (authState.isAuthenticated) {
        final role = authState.profile?['role'] ?? '';
        if (role == 'petugas_kantin') {
          context.go('/pos');
        } else if (role == 'petugas_keuangan') {
          context.go('/finance');
        } else if (role == 'super_admin') {
          context.go('/admin');
        } else if (role == 'parent') {
          final studentId = authState.profile?['student_id'] ?? '';
          if (studentId.isNotEmpty) {
            context.go('/parent/dashboard/$studentId');
          } else {
            context.go('/parent');
          }
        } else {
          context.go('/student');
        }
      } else {
        context.go('/welcome');
      }
    } catch (_) {
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to run redirect when initialized
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isInitialized) {
        _redirectAfterSplash(next);
      }
    });

    // Fallback in case state was already initialized on launch/hot-reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.isInitialized) {
        _redirectAfterSplash(authState);
      }
    });
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Minimalist wave plate icon (NFC + Plate)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.creditcard,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.subtitleSplash,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGray,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 80),
            const CupertinoActivityIndicator(
              color: AppColors.primary,
              radius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
