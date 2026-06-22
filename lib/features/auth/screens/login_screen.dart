import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/auth/widgets/login_account_preview.dart';
import 'package:kantin_digital/features/auth/widgets/login_preview_item.dart';
import 'package:kantin_digital/features/auth/widgets/role_toggle_button.dart';

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
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.errorAccessDenied),
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

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () {
            if (widget.from != null && widget.from!.isNotEmpty) {
              context.go(widget.from!);
            } else {
              context.go('/welcome');
            }
          },
          child: Row(
            children: const [
              SizedBox(width: 8),
              Icon(CupertinoIcons.left_chevron, color: AppColors.primary, size: 20),
              SizedBox(width: 4),
              Text(
                AppStrings.buttonBack,
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
            child: Align(
              alignment: Alignment.topCenter,
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
                          _selectedLoginTab == 0 ? 'Yuk, Masuk!' : 'Masuk Orang Tua',
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
                          _selectedLoginTab == 0
                              ? 'Silakan masuk ke akun Anda untuk memantau saldo, jajan, atau mengelola kantin.'
                              : 'Pantau jajan, saldo, dan aktivitas anak Anda dengan mudah.',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form Input
                        Text(
                          _selectedLoginTab == 0 ? 'Username / NISN / Email' : 'NISN Anak',
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
                          keyboardType: _selectedLoginTab == 0 ? TextInputType.text : TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: _selectedLoginTab == 0
                                ? 'Contoh: petugas, 20260012, atau petugas@sekolah.sch.id'
                                : 'Contoh: 20260012',
                            hintStyle: const TextStyle(color: AppColors.inputBorder),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.inputBorder),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                            hintStyle: const TextStyle(color: AppColors.inputBorder),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.inputBorder),
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
                                color: AppColors.inputBorder,
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
                                ? const CupertinoActivityIndicator(color: AppColors.white)
                                : const Text(
                                    'MASUK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pilihan login Orang Tua / Siswa & Staff di bawah
                        RoleToggleButton(
                          selectedLoginTab: _selectedLoginTab,
                          onToggle: () {
                            setState(() {
                              _selectedLoginTab = _selectedLoginTab == 0 ? 1 : 0;
                              _emailController.clear();
                              _passwordController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 32),

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
              child: LoginAccountPreview(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedLoginTab == 0) ...[
                      LoginPreviewItem(
                        roleName: 'KASIR / PETUGAS (USERNAME)',
                        identifier: 'petugas',
                        password: 'password123',
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _emailController.text = 'petugas';
                            _passwordController.text = 'password123';
                          });
                          _showFillSnackBar('Kasir');
                        },
                      ),
                      const Divider(height: 12, color: AppColors.borderLight),
                      
                      // Admin Keuangan (budi_fin — akun asli)
                      LoginPreviewItem(
                        roleName: 'ADMIN KEUANGAN (USERNAME)',
                        identifier: 'budi_fin',
                        password: 'budi123',
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _emailController.text = 'budi_fin';
                            _passwordController.text = 'budi123';
                          });
                          _showFillSnackBar('Admin Keuangan');
                        },
                      ),
                      const Divider(height: 12, color: AppColors.borderLight),

                      // Petugas Keuangan (keuangan — akun testing)
                      LoginPreviewItem(
                        roleName: 'PETUGAS KEUANGAN (USERNAME)',
                        identifier: 'keuangan',
                        password: 'keuangan123',
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _emailController.text = 'keuangan';
                            _passwordController.text = 'keuangan123';
                          });
                          _showFillSnackBar('Petugas Keuangan');
                        },
                      ),
                      const Divider(height: 12, color: AppColors.borderLight),
                      
                      // Siswa
                      LoginPreviewItem(
                        roleName: 'SISWA (AHMAD - NISN)',
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
                      
                      // Super Admin
                      LoginPreviewItem(
                        roleName: 'SUPER ADMIN (MOCK)',
                        identifier: 'superadmin',
                        password: 'admin123',
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _emailController.text = 'superadmin';
                            _passwordController.text = 'admin123';
                          });
                          _showFillSnackBar('Super Admin');
                        },
                      ),
                    ] else ...[
                      // Orang Tua
                      LoginPreviewItem(
                        roleName: 'ORANG TUA (WALI AHMAD - NISN)',
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
