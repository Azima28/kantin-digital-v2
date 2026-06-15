import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        // Go to POS Cashier Dashboard
        context.go('/pos');
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

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40),
                // Heading Branding
                Text(
                  AppStrings.welcomeAuth,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.welcomeAuthDesc,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textGray,
                      ),
                ),
                const SizedBox(height: 60),

                // Form Input NIS/Email
                Text(
                  AppStrings.labelEmailOrNis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'budesari.stan@sekolah.sch.id',
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email/NIS wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Form Input Password
                Text(
                  AppStrings.labelPassword,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kata sandi',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),

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
                            AppStrings.buttonLoginKasir,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textGray,
                          fontSize: 13,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
