import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
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
    final isDark = context.isDark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBg : AppColors.lightScaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: <Widget>[
              // Header Section (40% height, Logo & App Title)
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Clean Logo Badge (128x128 container)
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.creditcard_fill,
                        color: primaryColor,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'v2.0 by Nebula Labs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // Spacer / Loading Indicator
              const CupertinoActivityIndicator(
                radius: 14,
              ),
              const SizedBox(height: 32),

              // Footer Section (Action Button & Encrypted Badge)
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Full Width Primary Button (56px height, 16px radius)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          final authState = ref.read(authNotifierProvider);
                          _redirectAfterSplash(authState);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: isDark ? 0 : 2,
                          shadowColor: isDark ? Colors.transparent : primaryColor.withValues(alpha: 0.25),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.buttonGetStarted,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Security Encryption Footer Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Keamanan data dienkripsi',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
