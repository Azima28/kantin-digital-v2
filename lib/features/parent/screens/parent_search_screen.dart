import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class ParentSearchScreen extends ConsumerStatefulWidget {
  const ParentSearchScreen({super.key});

  @override
  ConsumerState<ParentSearchScreen> createState() => _ParentSearchScreenState();
}

class _ParentSearchScreenState extends ConsumerState<ParentSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nisController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String nisInput = _nisController.text.trim();
    String queryEmail = nisInput;
    if (!queryEmail.contains('@')) {
      queryEmail = '$queryEmail@sekolah.sch.id';
    }

    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await client
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('email', queryEmail)
          .eq('role', 'student')
          .maybeSingle();

      if (profile == null) {
        setState(() {
          _errorMessage = 'NIS Tidak Terdaftar. Silakan hubungi tata usaha sekolah.';
        });
        return;
      }

      // Verify the student profile exists in students table
      final student = await client
          .from('students')
          .select('id')
          .eq('id', profile['id'])
          .maybeSingle();

      if (student == null) {
        setState(() {
          _errorMessage = 'Data siswa belum diinisialisasi di tabel student.';
        });
        return;
      }

      if (mounted) {
        context.push('/parent/dashboard/${profile['id']}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mencari data siswa: $e';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(color: const Color(0xFFBDC9C8).withValues(alpha: 0.3), width: 0.5),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: AppColors.primary),
          onPressed: () => context.go('/student/welcome'),
        ),
        title: Text(
          'Portal Orang Tua',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Headline Branding
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_crop_circle_badge_checkmark,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'KANTIN DIGITAL',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Portal Orang Tua Siswa',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(
                    'Cek Saldo & Top-up Online Uang Saku Anak',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NIS Input
                  Text(
                    'Masukkan NIS / Kode Unik Siswa',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                  TextFormField(
                    controller: _nisController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 20260012',
                      hintStyle: TextStyle(color: Color(0xFFBDC9C8)),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFBDC9C8)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor NIS wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'CEK SALDO & AKTIVITAS ANAK',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
