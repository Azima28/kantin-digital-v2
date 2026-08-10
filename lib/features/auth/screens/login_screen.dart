import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/auth/widgets/login_account_preview.dart';
import 'package:kantin_digital/features/auth/widgets/login_preview_item.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? from;
  const LoginScreen({super.key, this.from});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _selectedLoginTab = 0; // 0 for Siswa / Staff, 1 for Orang Tua
  bool _showDemoPanelMobile = false;

  // Base color constants
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color accentBlue = Color(0xFF14B8A6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    final bool success = await ref.read(authNotifierProvider.notifier).login(
          email,
          password,
          role: _selectedLoginTab == 1 ? 'parent' : '',
        );

    if (success) {
      if (mounted) {
        final profile = ref.read(authNotifierProvider).profile;
        final String role = profile?['role'] ?? '';

        if (role == 'petugas_kantin') {
          context.go('/pos');
        } else if (role == 'student') {
          context.go('/student');
        } else if (role == 'super_admin') {
          context.go('/admin');
        } else if (role == 'petugas_keuangan') {
          context.go('/finance');
        } else if (role == 'parent') {
          final String studentId = profile?['student_id'] ?? '';
          if (studentId.isNotEmpty) {
            context.go('/parent/dashboard/$studentId');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.errorParentNoChild),
                backgroundColor: Nebula.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.errorAccessDenied),
              backgroundColor: Nebula.rose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        final String? error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? AppStrings.loginError),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showToast(String message) {
    final isDark = context.isDark;
    final activeTeal = isDark ? primaryTeal : const Color(0xFF0D9488);
    final toastBg = isDark ? const Color(0xFF242424) : Colors.white;
    final toastText = isDark ? Colors.white : const Color(0xFF023835);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: activeTeal, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: toastText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: toastBg,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: activeTeal, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);
    final isDesktop = Responsive.isDesktop(context);
    final isDark = context.isDark;

    // Responsive Light & Dark Mode dynamic tokens (Unified Emerald/Teal Theme)
    final pageBg = isDark ? AppColors.darkScaffoldBg : AppColors.lightScaffoldBg;
    final activeTeal = isDark ? AppColors.tealConst : AppColors.darkTealConst;
    final activeTealDark = isDark ? AppColors.darkTealConst : const Color(0xFF065F56);
    final activeGlassBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final activeGlassBorder = isDark ? AppColors.darkCardBorder : AppColors.lightInputFieldBorder;
    final activeInputBg = isDark ? AppColors.darkInputFieldBg : AppColors.lightInputFieldBg;
    final activeInputBorder = isDark
        ? const BorderSide(color: AppColors.darkInputFieldBorder, width: 1)
        : const BorderSide(color: AppColors.lightInputFieldBorder, width: 1);
    final activeTextMain = isDark ? AppColors.darkTextPrimaryVal : AppColors.lightTextPrimaryVal;
    final activeTextMuted = isDark ? AppColors.darkTextSecondaryVal : AppColors.lightTextSecondaryVal;
    final activeTextLabel = isDark ? AppColors.darkTextPrimaryVal : AppColors.lightTextPrimaryVal;
    final activeTextPlaceholder = isDark ? AppColors.darkTextSecondaryVal : AppColors.lightTextSecondaryVal;
    final activeShadow = isDark ? Colors.transparent : const Color(0x0D000000);
    final activeSecBtnBg = isDark ? AppColors.darkInputFieldBg : const Color(0xFFE6F5F2);
    final activeSecBtnBorder = isDark ? AppColors.darkCardBorder : const Color(0xFFB2DFDF);
    final activeSecBtnText = isDark ? AppColors.darkTextPrimaryVal : AppColors.darkTealConst;

    return Scaffold(
      backgroundColor: pageBg,
      body: Stack(
        children: [
          // Background Animated Blobs (Light & Dark mode aware)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeTeal.withValues(alpha: isDark ? 0.35 : 0.15),
                boxShadow: [
                  BoxShadow(
                    color: activeTeal.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? accentBlue : activeTealDark).withValues(alpha: isDark ? 0.35 : 0.12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? accentBlue : activeTealDark).withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (Back Button + Theme Toggle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PressScale(
                        onTap: () {
                          if (widget.from != null && widget.from!.isNotEmpty) {
                            context.go(widget.from!);
                          } else {
                            context.go('/welcome');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.chevron_left_rounded, color: activeTeal, size: 22),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.buttonBack,
                                style: GoogleFonts.poppins(
                                  color: activeTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          // Theme Mode Toggle Switch Button (Light / Dark)
                          PressScale(
                            onTap: () {
                              ref.read(themeProvider.notifier).toggle();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: activeTeal.withValues(alpha: isDark ? 0.12 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: activeTeal.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    size: 16,
                                    color: activeTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isDark ? 'Mode Terang' : 'Mode Gelap',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: activeTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Mobile toggle for Akun Demo panel
                          if (!isDesktop) ...[
                            const SizedBox(width: 8),
                            PressScale(
                              onTap: () {
                                setState(() {
                                  _showDemoPanelMobile = !_showDemoPanelMobile;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: activeTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: activeTeal.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _showDemoPanelMobile
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 16,
                                      color: activeTeal,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DEMO',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: activeTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Layout Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Left Panel: Demo Accounts
                                    SizedBox(
                                      width: 300,
                                      child: LoginAccountPreview(
                                        child: _buildDemoItemsList(context),
                                      ),
                                    ),
                                    const SizedBox(width: 24),

                                    // Right Panel: Login Form
                                    Flexible(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 580),
                                        child: _buildMainLoginFormCard(
                                          context: context,
                                          authState: authState,
                                          activeTeal: activeTeal,
                                          activeTealDark: activeTealDark,
                                          activeGlassBg: activeGlassBg,
                                          activeGlassBorder: activeGlassBorder,
                                          activeInputBg: activeInputBg,
                                          activeInputBorder: activeInputBorder,
                                          activeTextMain: activeTextMain,
                                          activeTextMuted: activeTextMuted,
                                          activeTextLabel: activeTextLabel,
                                          activeTextPlaceholder: activeTextPlaceholder,
                                          activeShadow: activeShadow,
                                          activeSecBtnBg: activeSecBtnBg,
                                          activeSecBtnBorder: activeSecBtnBorder,
                                          activeSecBtnText: activeSecBtnText,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_showDemoPanelMobile) ...[
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 500),
                                        child: LoginAccountPreview(
                                          width: double.infinity,
                                          child: _buildDemoItemsList(context),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 500),
                                      child: _buildMainLoginFormCard(
                                        context: context,
                                        authState: authState,
                                        activeTeal: activeTeal,
                                        activeTealDark: activeTealDark,
                                        activeGlassBg: activeGlassBg,
                                        activeGlassBorder: activeGlassBorder,
                                        activeInputBg: activeInputBg,
                                        activeInputBorder: activeInputBorder,
                                        activeTextMain: activeTextMain,
                                        activeTextMuted: activeTextMuted,
                                        activeTextLabel: activeTextLabel,
                                        activeTextPlaceholder: activeTextPlaceholder,
                                        activeShadow: activeShadow,
                                        activeSecBtnBg: activeSecBtnBg,
                                        activeSecBtnBorder: activeSecBtnBorder,
                                        activeSecBtnText: activeSecBtnText,
                                        isDark: isDark,
                                      ),
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

  /// Right Panel Login Form Card (Light & Dark mode aware)
  Widget _buildMainLoginFormCard({
    required BuildContext context,
    required AuthState authState,
    required Color activeTeal,
    required Color activeTealDark,
    required Color activeGlassBg,
    required Color activeGlassBorder,
    required Color activeInputBg,
    required BorderSide activeInputBorder,
    required Color activeTextMain,
    required Color activeTextMuted,
    required Color activeTextLabel,
    required Color activeTextPlaceholder,
    required Color activeShadow,
    required Color activeSecBtnBg,
    required Color activeSecBtnBorder,
    required Color activeSecBtnText,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: activeGlassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: activeGlassBorder, width: 1),
        boxShadow: isDark
            ? []
            : [
                const BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. App Header (.app-header)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activeTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KANTIN DIGITAL',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: activeTextMain,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Akun layanan sekolah',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: activeTextMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Secure Area Badge (.secure-area)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: activeTeal.withValues(alpha: isDark ? 0.08 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: activeTeal),
                  const SizedBox(width: 6),
                  Text(
                    'AREA AMAN',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: activeTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Hero Titles
            Text(
              _selectedLoginTab == 0 ? 'Selamat datang kembali.' : 'Masuk Orang Tua Sekolah',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: activeTextMain,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedLoginTab == 0
                  ? 'Masuk untuk memantau saldo, jajan, atau mengelola layanan kantin sekolah.'
                  : 'Pantau jajan, saldo, dan aktivitas anak Anda dengan mudah.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: activeTextMuted,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // 4. Field 1: Username / NISN / Email
            Text(
              _selectedLoginTab == 0 ? 'Username / NISN / Email' : 'NISN Anak',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: activeTextLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: _selectedLoginTab == 0 ? TextInputType.text : TextInputType.number,
              style: GoogleFonts.poppins(fontSize: 14, color: activeTextMain),
              decoration: InputDecoration(
                hintText: _selectedLoginTab == 0 ? 'Masukkan username Anda' : 'Masukkan NISN Anak',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: activeTextPlaceholder),
                filled: true,
                fillColor: activeInputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: activeTextMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: activeInputBorder,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: activeInputBorder,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: activeTeal, width: 1.5),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return _selectedLoginTab == 0
                      ? 'Username, NISN, atau Email wajib diisi'
                      : 'NISN Anak wajib diisi';
                }
                if (_selectedLoginTab == 1 && !RegExp(r'^\d+$').hasMatch(value.trim())) {
                  return 'NISN Anak harus berupa angka';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // 5. Field 2: Kata Sandi
            Text(
              'Kata Sandi',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: activeTextLabel,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.poppins(fontSize: 14, color: activeTextMain),
              decoration: InputDecoration(
                hintText: 'Minimal 6 karakter',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: activeTextPlaceholder),
                filled: true,
                fillColor: activeInputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: activeTextMuted),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: activeTextMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: activeInputBorder,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: activeInputBorder,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: activeTeal, width: 1.5),
                ),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Kata sandi wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 6. Primary Submit Button (.btn-primary)
            PressScale(
              onTap: authState.isLoading ? null : _handleLogin,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: activeTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: activeTeal.withValues(alpha: isDark ? 0.2 : 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: authState.isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'MASUK',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
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
            ),
            const SizedBox(height: 12),

            // 7. Secondary Button (.btn-secondary)
            PressScale(
              onTap: () {
                setState(() {
                  _selectedLoginTab = _selectedLoginTab == 0 ? 1 : 0;
                  _emailController.clear();
                  _passwordController.clear();
                });
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: activeSecBtnBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeSecBtnBorder, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedLoginTab == 0
                          ? Icons.people_outline_rounded
                          : Icons.arrow_back_rounded,
                      size: 18,
                      color: activeSecBtnText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedLoginTab == 0
                          ? 'Masuk sebagai Orang Tua'
                          : 'Kembali ke Login Utama',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: activeSecBtnText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 8. Footer Section (.login-footer)
            Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: activeGlassBorder, width: 1)),
              ),
              child: Column(
                children: [
                  Center(
                    child: PressScale(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.contactCooperative,
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lupa sandi? Hubungi Koperasi Sekolah',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: activeTextMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Data Anda tersimpan dengan aman.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
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
    );
  }

  /// List of demo account items (populated from DB credentials)
  Widget _buildDemoItemsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedLoginTab == 0) ...[
          LoginPreviewItem(
            roleName: 'Kasir / Petugas Kantin',
            identifier: 'petugas',
            password: 'password123',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _emailController.text = 'petugas';
                _passwordController.text = 'password123';
              });
              _showToast('Akun Petugas Kantin berhasil diisi!');
            },
          ),
          LoginPreviewItem(
            roleName: 'Admin Keuangan',
            identifier: 'budi_fin',
            password: 'budi123',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _emailController.text = 'budi_fin';
                _passwordController.text = 'budi123';
              });
              _showToast('Akun Admin Keuangan berhasil diisi!');
            },
          ),
          LoginPreviewItem(
            roleName: 'Siswa (Ahmad - NISN)',
            identifier: '20260012',
            password: 'password123',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _emailController.text = '20260012';
                _passwordController.text = 'password123';
              });
              _showToast('Akun Siswa berhasil diisi!');
            },
          ),
          LoginPreviewItem(
            roleName: 'Super Admin',
            identifier: 'superadmin',
            password: 'admin123',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _emailController.text = 'superadmin';
                _passwordController.text = 'admin123';
              });
              _showToast('Akun Super Admin berhasil diisi!');
            },
          ),
        ] else ...[
          LoginPreviewItem(
            roleName: 'Orang Tua (Wali Siswa - NISN)',
            identifier: '20260012',
            password: 'parent123',
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _emailController.text = '20260012';
                _passwordController.text = 'parent123';
              });
              _showToast('Akun Orang Tua berhasil diisi!');
            },
          ),
        ],
      ],
    );
  }
}