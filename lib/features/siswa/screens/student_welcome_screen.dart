import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';

class StudentWelcomeScreen extends ConsumerStatefulWidget {
  const StudentWelcomeScreen({super.key});

  @override
  ConsumerState<StudentWelcomeScreen> createState() => _StudentWelcomeScreenState();
}

class _StudentWelcomeScreenState extends ConsumerState<StudentWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _phoneFloatController;
  late Animation<double> _phoneFloatAnimation;

  @override
  void initState() {
    super.initState();

    // Floating 3D motion for Phone Mockup (6s cycle)
    _phoneFloatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _phoneFloatAnimation = Tween<double>(begin: 0, end: -16).animate(
      CurvedAnimation(
        parent: _phoneFloatController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _phoneFloatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    // Color tokens matching unified Emerald / Teal theme
    final pageBgColor = isDark ? AppColors.darkScaffoldBg : AppColors.lightScaffoldBg;
    final primaryTeal = isDark ? AppColors.tealConst : AppColors.darkTealConst;
    final primaryTealDark = isDark ? AppColors.darkTealConst : const Color(0xFF065F56);
    final accentBlue = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final gradientCyan = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);

    final glassBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final glassBorder = isDark ? AppColors.darkCardBorder : AppColors.lightInputFieldBorder;

    final headlineColor = isDark ? AppColors.darkTextPrimaryVal : AppColors.lightTextPrimaryVal;
    final textMutedColor = isDark ? AppColors.darkTextSecondaryVal : AppColors.lightTextSecondaryVal;
    final featureCardBg = isDark ? AppColors.darkInputFieldBg : AppColors.lightInputFieldBg;
    final featureCardBorder = isDark ? AppColors.darkInputFieldBorder : AppColors.lightInputFieldBorder;

    final double maxContainerWidth = isDesktop ? 1200.0 : (isTablet ? 720.0 : 500.0);
    final double outerPadding = isDesktop ? 60.0 : (isTablet ? 36.0 : 24.0);

    return Scaffold(
      backgroundColor: pageBgColor,
      body: Stack(
        children: [
          // 1. Dynamic Background Orbs (orb-1 & orb-2 from HTML)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryTeal.withValues(alpha: isDark ? 0.3 : 0.12),
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Glass Container Wrapper
          SafeArea(
            child: Column(
              children: [
                // Top Nav Bar (Theme Switcher)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PressScale(
                        onTap: () => ref.read(themeProvider.notifier).toggle(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: isDark ? 0.12 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryTeal.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                size: 16,
                                color: primaryTeal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDark ? 'Mode Terang' : 'Mode Gelap',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Scrollable Main Container
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 16,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContainerWidth),
                        child: Container(
                          padding: EdgeInsets.all(outerPadding),
                          decoration: BoxDecoration(
                            color: glassBg,
                            borderRadius: BorderRadius.circular(isDesktop ? 48 : 32),
                            border: Border.all(color: glassBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.8)
                                    : const Color(0x14065F56),
                                blurRadius: 80,
                                offset: const Offset(0, 30),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Split Section (Hero Left + Mockup Right)
                              if (isDesktop)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left Column
                                    Expanded(
                                      flex: 11,
                                      child: _buildLeftHeroContent(
                                        context: context,
                                        primaryTeal: primaryTeal,
                                        primaryTealDark: primaryTealDark,
                                        gradientCyan: gradientCyan,
                                        headlineColor: headlineColor,
                                        textMutedColor: textMutedColor,
                                        glassBorder: glassBorder,
                                        isDesktop: true,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 40),

                                    // Right Column (Phone Mockup)
                                    Expanded(
                                      flex: 9,
                                      child: Center(
                                        child: _buildPhoneMockup(
                                          primaryTeal: primaryTeal,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildLeftHeroContent(
                                      context: context,
                                      primaryTeal: primaryTeal,
                                      primaryTealDark: primaryTealDark,
                                      gradientCyan: gradientCyan,
                                      headlineColor: headlineColor,
                                      textMutedColor: textMutedColor,
                                      glassBorder: glassBorder,
                                      isDesktop: false,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 36),
                                    _buildPhoneMockup(
                                      primaryTeal: primaryTeal,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 48),

                              // Bottom Features Grid (3 Cards)
                              _buildFeaturesGrid(
                                context: context,
                                primaryTeal: primaryTeal,
                                headlineColor: headlineColor,
                                textMutedColor: textMutedColor,
                                featureCardBg: featureCardBg,
                                featureCardBorder: featureCardBorder,
                                isDesktop: isDesktop,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Left Column: Badge, Title with Gradient, Paragraph, CTA Buttons
  Widget _buildLeftHeroContent({
    required BuildContext context,
    required Color primaryTeal,
    required Color primaryTealDark,
    required Color gradientCyan,
    required Color headlineColor,
    required Color textMutedColor,
    required Color glassBorder,
    required bool isDesktop,
    required bool isDark,
  }) {
    final double titleFontSize = isDesktop ? 54.0 : 36.0;

    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Badge (.badge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: primaryTeal.withValues(alpha: isDark ? 0.1 : 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: primaryTeal.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_rounded, size: 16, color: primaryTeal),
              const SizedBox(width: 8),
              Text(
                AppStrings.welcomeBadge,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textMutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Heading Title (`Jajan jadi sederhana.`) with Gradient Effect
        RichText(
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
              color: headlineColor,
            ),
            children: [
              const TextSpan(text: 'Jajan jadi\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [primaryTeal, gradientCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'sederhana.',
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Description Paragraph
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            AppStrings.welcomeHeroDesc,
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: textMutedColor,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // 4. CTA Action Buttons Group (.cta-group)
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Primary Button: Mulai Sekarang
            PressScale(
              onTap: () => context.go('/login?from=/welcome'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryTeal, primaryTealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.welcomeBtnEnter,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Right Column: 3D Animated Smartphone Mockup (.mockup-phone)
  Widget _buildPhoneMockup({
    required Color primaryTeal,
    required bool isDark,
  }) {
    return AnimatedBuilder(
      animation: _phoneFloatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _phoneFloatAnimation.value),
          child: Container(
            width: 280,
            height: 540,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(44),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFCBD5E1),
                width: 8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.8) : const Color(0x1F000000),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: primaryTeal.withValues(alpha: isDark ? 0.1 : 0.15),
                  blurRadius: 30,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                color: isDark ? const Color(0xFF242424) : const Color(0xFFFFFFFF),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mockup Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 14, color: primaryTeal),
                            const SizedBox(width: 6),
                            Text(
                              'Kantin',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: primaryTeal,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '12:00',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mockup Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: isDark ? 0.1 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryTeal.withValues(alpha: isDark ? 0.15 : 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SALDO DIGITAL',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp 150.000',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mockup Menu Title
                    Text(
                      'Menu Populer Hari Ini',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mockup Menu Items List
                    Expanded(
                      child: Column(
                        children: [
                          _buildMockupMenuItem(
                            name: 'Nasi Goreng',
                            desc: 'Telur + Kerupuk',
                            price: 'Rp 15k',
                            primaryTeal: primaryTeal,
                            isDark: isDark,
                          ),
                          _buildMockupMenuItem(
                            name: 'Ayam Penyet',
                            desc: 'Sambal + Lalapan',
                            price: 'Rp 20k',
                            primaryTeal: primaryTeal,
                            isDark: isDark,
                          ),
                          _buildMockupMenuItem(
                            name: 'Es Teh Manis',
                            desc: 'Es batu besar',
                            price: 'Rp 3k',
                            primaryTeal: primaryTeal,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // Mockup Footer Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: primaryTeal.withValues(alpha: isDark ? 0.12 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryTeal.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 14, color: primaryTeal),
                          const SizedBox(width: 6),
                          Text(
                            'Pesan Sekarang',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMockupMenuItem({
    required String name,
    required String desc,
    required String price,
    required Color primaryTeal,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Features Grid (.features-grid) — 3 Feature Cards
  Widget _buildFeaturesGrid({
    required BuildContext context,
    required Color primaryTeal,
    required Color headlineColor,
    required Color textMutedColor,
    required Color featureCardBg,
    required Color featureCardBorder,
    required bool isDesktop,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = isDesktop;
        return useRow
            ? Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.bolt_rounded,
                      title: AppStrings.welcomeFeature1Title,
                      desc: AppStrings.welcomeFeature1Desc,
                      primaryTeal: primaryTeal,
                      headlineColor: headlineColor,
                      textMutedColor: textMutedColor,
                      featureCardBg: featureCardBg,
                      featureCardBorder: featureCardBorder,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: AppStrings.welcomeFeature2Title,
                      desc: AppStrings.welcomeFeature2Desc,
                      primaryTeal: primaryTeal,
                      headlineColor: headlineColor,
                      textMutedColor: textMutedColor,
                      featureCardBg: featureCardBg,
                      featureCardBorder: featureCardBorder,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFeatureCard(
                      icon: Icons.access_time_rounded,
                      title: AppStrings.welcomeFeature3Title,
                      desc: AppStrings.welcomeFeature3Desc,
                      primaryTeal: primaryTeal,
                      headlineColor: headlineColor,
                      textMutedColor: textMutedColor,
                      featureCardBg: featureCardBg,
                      featureCardBorder: featureCardBorder,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildFeatureCard(
                    icon: Icons.bolt_rounded,
                    title: AppStrings.welcomeFeature1Title,
                    desc: AppStrings.welcomeFeature1Desc,
                    primaryTeal: primaryTeal,
                    headlineColor: headlineColor,
                    textMutedColor: textMutedColor,
                    featureCardBg: featureCardBg,
                    featureCardBorder: featureCardBorder,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: AppStrings.welcomeFeature2Title,
                    desc: AppStrings.welcomeFeature2Desc,
                    primaryTeal: primaryTeal,
                    headlineColor: headlineColor,
                    textMutedColor: textMutedColor,
                    featureCardBg: featureCardBg,
                    featureCardBorder: featureCardBorder,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.access_time_rounded,
                    title: AppStrings.welcomeFeature3Title,
                    desc: AppStrings.welcomeFeature3Desc,
                    primaryTeal: primaryTeal,
                    headlineColor: headlineColor,
                    textMutedColor: textMutedColor,
                    featureCardBg: featureCardBg,
                    featureCardBorder: featureCardBorder,
                  ),
                ],
              );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color primaryTeal,
    required Color headlineColor,
    required Color textMutedColor,
    required Color featureCardBg,
    required Color featureCardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: featureCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: featureCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: headlineColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
