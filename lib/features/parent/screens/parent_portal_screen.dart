import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
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
      
      // Query profiles table to find matching student NISN
      final profile = await client
          .from('profiles')
          .select('id, role, full_name')
          .eq('nisn', nisInput)
          .maybeSingle();

      if (profile == null) {
        setState(() {
          _errorMessage = 'NIS / Kode Unik Siswa tidak ditemukan';
        });
        return;
      }

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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => context.go('/welcome'),
                                icon: const Icon(CupertinoIcons.left_chevron, size: 14, color: AppColors.primary),
                                label: const Text(
                                  'Kembali',
                                  style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Brand logo section
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.creditcard,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'KANTIN DIGITAL',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Portal Orang Tua Siswa',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // Heading
                            Text(
                              'Cek Saldo & Aktivitas Anak',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Input field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _errorMessage != null ? AppColors.error : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.person_crop_square_fill, color: AppColors.textGray, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nisController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: AppColors.textDark,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan NIS / Kode Unik Siswa',
                                        hintStyle: GoogleFonts.beVietnamPro(color: AppColors.textGray.withValues(alpha: 0.7), fontSize: 15),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                        filled: false,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'NIS / Kode Unik Siswa wajib diisi';
                                        }
                                        return null;
                                      },
                                      onFieldSubmitted: (_) => _checkNis(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Inline error message
                            if (_errorMessage != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppColors.error,
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
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _checkNis,
                                child: _isLoading
                                    ? const CupertinoActivityIndicator(color: Colors.white)
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'CEK SALDO & AKTIVITAS ANAK',
                                            style: GoogleFonts.beVietnamPro(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 16),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),

                        // Spacing before footer when keyboard is active or space is low
                        const SizedBox(height: 32),

                        // Footer
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sistem Informasi Pembayaran Terintegrasi',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '© 2024 Kantin Digital',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: AppColors.textGray,
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
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: isWide
          ? Row(
              children: [
                // Left panel: Background Image
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(bgImageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(bgImageUrl),
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
