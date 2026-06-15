import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

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

    final bool success = await ref.read(authNotifierProvider.notifier).login(email, password);

    if (success) {
      if (mounted) {
        final profile = ref.read(authNotifierProvider).profile;
        final String role = profile?['role'] ?? '';
        
        if (role == 'petugas_kantin') {
          context.go('/pos');
        } else if (role == 'student') {
          context.go('/student');
        } else if (role == 'parent') {
          final String studentId = profile?['student_id'] ?? '';
          if (studentId.isNotEmpty) {
            context.go('/parent/dashboard/$studentId');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun orang tua tidak memiliki data anak yang tertaut.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akses ditolak: Hak akses tidak dikenali.'),
              backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showFillSnackBar(String role) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kredensial $role berhasil diisi!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPreviewItem({
    required String roleName,
    required String identifier,
    required String password,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          roleName,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          identifier,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        Text(
          'Sandi: $password',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Gunakan Kredensial',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  CupertinoIcons.square_pencil,
                  size: 8,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () => context.go('/student/welcome'),
          child: Row(
            children: const [
              SizedBox(width: 8),
              Icon(CupertinoIcons.left_chevron, color: AppColors.primary, size: 20),
              SizedBox(width: 4),
              Text(
                'Kembali',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Heading Branding
                        Text(
                          'Yuk, Masuk!',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan masuk ke akun Anda untuk memantau saldo, jajan, atau mengelola kantin.',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Form Input NIS/Email
                        Text(
                          'Email / NISN Siswa',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'petugas@sekolah.sch.id atau 20260012',
                            hintStyle: TextStyle(color: Color(0xFFBDC9C8)),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFBDC9C8)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email/NISN wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Form Input Password
                        Text(
                          AppStrings.labelPassword,
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kata sandi',
                            hintStyle: const TextStyle(color: Color(0xFFBDC9C8)),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFBDC9C8)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                color: const Color(0xFFBDC9C8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 60),

                        // Tombol Masuk
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: authState.isLoading
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : const Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Catatan Koperasi
                        Center(
                          child: Text(
                            AppStrings.contactCooperative,
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 13,
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
          ),
          
          // Unified Multi-Role Preview Overlay (Top Left / Responsive Floating)
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'PREVIEW AKUN UJI COBA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Petugas
                    _buildPreviewItem(
                      roleName: 'KASIR / PETUGAS',
                      identifier: 'petugas@sekolah.sch.id',
                      password: 'password123',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _emailController.text = 'petugas@sekolah.sch.id';
                          _passwordController.text = 'password123';
                        });
                        _showFillSnackBar('Kasir');
                      },
                    ),
                    const Divider(height: 12, color: AppColors.borderLight),
                    
                    // Siswa
                    _buildPreviewItem(
                      roleName: 'SISWA (AHMAD)',
                      identifier: '20260012',
                      password: 'password123',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _emailController.text = '20260012';
                          _passwordController.text = 'password123';
                        });
                        _showFillSnackBar('Siswa');
                      },
                    ),
                    const Divider(height: 12, color: AppColors.borderLight),
                    
                    // Orang Tua
                    _buildPreviewItem(
                      roleName: 'ORANG TUA (WALI AHMAD)',
                      identifier: '20260012',
                      password: 'parent123',
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _emailController.text = '20260012';
                          _passwordController.text = 'parent123';
                        });
                        _showFillSnackBar('Orang Tua');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
