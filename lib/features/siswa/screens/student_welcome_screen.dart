import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

class StudentWelcomeScreen extends ConsumerStatefulWidget {
  const StudentWelcomeScreen({super.key});

  @override
  ConsumerState<StudentWelcomeScreen> createState() =>
      _StudentWelcomeScreenState();
}

class _StudentWelcomeScreenState extends ConsumerState<StudentWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const List<String> _welcomeMessages = [
    'Selamat Datang di Kantin Digital!',
    'Jajan Praktis, Tanpa Uang Tunai',
    'Nikmati Berbagai Menu Lezat',
    'Cukup Tap Kartu, Makan Siang Siap!',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String imageUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAj9v7hCFkrRMAey43LSqCsH44EKtneScrHLtAbaq6ds1WZOLUwWuTjULCt-RAxdUsHfVqA4YVlpA0Xt52989-Cz_lGBEGQ_lC4s82hTAGoVB_0f0MrONfgiu-EWk-JYao2dwaXApSFQsp41tQzh38H1K1sf7Zgy0D21UR-tkIBvJCscPwhynCK-7XZjwElD3qjwM9pLSA6WjPWAXPHBBDTjXQ2U_RmLDJyBviDR4jfZvqq0SfKYRC8BGNieqbbXrKyYBwE5NEVcbY';

    return Scaffold(
      backgroundColor: AppColors.systemBackground,
      body: Stack(
        children: [
          // Ambient Background Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 320,
              width: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(20),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Welcome message
                      Text(
                        _welcomeMessages.isNotEmpty ? _welcomeMessages[0] : 'Halo!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Animated Illustration
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _animation.value),
                            child: child,
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Main illustration circle
                            Container(
                              width: 224,
                              height: 224,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.white,
                                border:
                                    Border.all(color: AppColors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (c, i) => const Center(child: CupertinoActivityIndicator()),
                                  errorWidget: (c, i, e) {
                                    return Container(
                                      color: AppColors.primaryLight,
                                      child: const Icon(
                                        CupertinoIcons.creditcard,
                                        color: AppColors.primary,
                                        size: 64,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Floating Wifi Badge (Top Right)
                            Positioned(
                              top: -4,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  CupertinoIcons.wifi,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                            // Floating Restaurant Badge (Bottom Left)
                            Positioned(
                              bottom: -2,
                              left: -4,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.accentOrange,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // App Title
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        AppStrings.subtitleSplash,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGray,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/login?from=/welcome');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                AppStrings.buttonGetStarted,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.arrow_right,
                                color: AppColors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
