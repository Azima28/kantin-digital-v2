import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class ParentPortalScreen extends ConsumerStatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  ConsumerState<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends ConsumerState<ParentPortalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nisController.dispose();
    super.dispose();
  }

  Future<void> _checkNis() async {
    if (!_formKey.currentState!.validate()) return;

    final String nisInput = _nisController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      
      // Use RPC for NISN lookup (bypasses RLS)
      final response = await client.rpc('get_student_by_nisn', params: {
        'p_nisn': nisInput,
      });
      
      Map<String, dynamic> result;
      if (response is Map<String, dynamic>) {
        result = response;
      } else if (response is String) {
        result = jsonDecode(response) as Map<String, dynamic>;
      } else {
        result = {};
      }
      
      if (result['found'] == false) {
        setState(() {
          _errorMessage = 'NIS / Kode Unik Siswa tidak ditemukan';
        });
        return;
      }
      
      final profile = result;

      final String role = profile['role'] ?? '';
      final String studentId = profile['id'];

      if (role != 'student') {
        setState(() {
          _errorMessage = 'Kode yang dimasukkan bukan milik siswa';
        });
        return;
      }

      // Successful lookup, redirect to child dashboard
      if (mounted) {
        context.go('/parent/dashboard/$studentId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memeriksa data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String bgImageUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDBrETCshHL1OtadMkevYxNXWoblvY3_eaW0Sk9QwBoSuocB4nFETu9B_s50rkB9wHonPRRZ-oiicHgGmjZaMu7jp3Qg2wlMNF9oWj6V8b6X-HlezzaUYU57Zf98uvu_928QX-R07vADGj2VFnO9xNaRbmhSjcLqh-KwovqNG1u2RNhZYdL4BE1aLY2xI-jAf5HCiKhAat4U6En6ZVawcS9NJA_9ZblRja_9l9Klf--WJrjJNKeSeSrJoWHWgQWRx_ubjAXR93Ixvo';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 768;

    Widget buildPortalForm() {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: 450,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: context.borderLight,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor,
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Main content (Form + Brand logo)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Back Button to welcome screen
                              Align(
                                alignment: Alignment.topLeft,
                                child: PressScale(
                                  onTap: () => context.go('/welcome'),
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {},
                                    icon: const Icon(CupertinoIcons.left_chevron, size: 14, color: Nebula.teal),
                                    label: Text(
                                      AppStrings.buttonBack,
                                      style: TextStyle(color: Nebula.teal, fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Brand logo section
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Nebula.teal.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.creditcard,
                                  color: Nebula.teal,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'KANTIN DIGITAL',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Nebula.teal,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Portal Orang Tua Siswa',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Heading
                              Text(
                                'Cek Saldo & Aktivitas Anak',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Input field
                              TextFormField(
                                controller: _nisController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: context.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan NIS / Kode Unik Siswa',
                                  prefixIcon: const Icon(CupertinoIcons.person_crop_square_fill, size: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'NIS / Kode Unik Siswa wajib diisi';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _checkNis(),
                              ),
                              const SizedBox(height: 16),

                              // Inline error message
                              if (_errorMessage != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.inter(
                                        color: Nebula.rose,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Action button
                              SizedBox(
                                width: double.infinity,
                                child: PressScale(
                                  onTap: _isLoading ? null : _checkNis,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Nebula.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : () {},
                                    child: _isLoading
                                        ? CupertinoActivityIndicator(color: context.cardBg)
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'CEK SALDO & AKTIVITAS ANAK',
                                                style: GoogleFonts.inter(
                                                  color: context.cardBg,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(CupertinoIcons.arrow_right, color: context.cardBg, size: 16),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Spacing before footer when keyboard is active or space is low
                          const SizedBox(height: 24),
                          GradientLine(),
                          const SizedBox(height: 16),

                          // Footer
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sistem Informasi Pembayaran Terintegrasi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '© 2024 Kantin Digital',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isWide
          ? Row(
              children: [
                // Left panel: Background Image
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(bgImageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        color: Nebula.teal.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
                // Right panel: Portal Form
                SizedBox(
                  width: 480,
                  child: buildPortalForm(),
                ),
              ],
            )
          : Stack(
              children: [
                // Background image
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(bgImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Dark glass overlay
                Container(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                // Portal Form
                SafeArea(
                  child: buildPortalForm(),
                ),
              ],
            ),
    );
  }
}