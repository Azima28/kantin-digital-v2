import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _passwordController = TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text(AppStrings.adminChangePassword),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    const Text('Masukkan kata sandi baru untuk akun Anda.'),
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Kata sandi baru',
                      obscureText: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.inactiveGray),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text(AppStrings.buttonCancel),
                  onPressed: () {
                    _passwordController.clear();
                    Navigator.pop(context);
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                          final password = _passwordController.text.trim();
                          if (password.isEmpty) return;

                          setDialogState(() {
                            _isChangingPassword = true;
                          });

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(this.context);

                          try {
                            final client = ref.read(supabaseClientProvider);
                            final profile = ref.read(authNotifierProvider).profile;
                            final profileId = profile?['id'];

                            final currentUserRole = profile?['role'];
                            if (currentUserRole != 'super_admin' && currentUserRole != 'admin') {
                              throw Exception('Tidak memiliki izin untuk mengubah password');
                            }

                            final response = await client.rpc('update_auth_user_password', params: {
                              'p_user_id': profileId,
                              'p_new_password': password,
                              'p_caller_id': profileId,
                            });
                            if (response is Map && response['success'] == false) {
                              throw Exception(response['error'] ?? 'Gagal mengubah kata sandi');
                            }

                            _passwordController.clear();
                            navigator.pop();

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Kata sandi berhasil diubah!'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            _passwordController.clear();
                            if (mounted) {
                              setState(() {
                                _isChangingPassword = false;
                              });
                            }
                          }
                        },
                  child: const Text(AppStrings.buttonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (confirmed) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Super Admin';
    final String email = authState.profile?['email'] ?? 'admin@kantindigital.com';
    final String username = authState.profile?['username'] ?? '';
    final String phone = authState.profile?['phone_number'] ?? '-';
    final String role = authState.profile?['role'] ?? 'super_admin';
    final String displayRole = role == 'super_admin' ? 'Super Admin' : 'Admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Akun Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.darkTeal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bento Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.darkTeal,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkTeal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent.withValues(alpha: 0.15),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayRole,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail Profil Card
              _buildSectionCard(
                title: '${AppStrings.titleDetail} Profil',
                icon: CupertinoIcons.person_crop_circle,
                children: [
                  _buildInfoRow('Nama Lengkap', fullName),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderLight),
                  _buildInfoRow('Email', email),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderLight),
                  _buildInfoRow('Username', username),
                  const Divider(height: 16, thickness: 0.5, color: AppColors.borderLight),
                  _buildInfoRow('No. Telepon', phone),
                ],
              ),
              const SizedBox(height: 16),

              // Keamanan Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 8),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.lock_shield, color: AppColors.darkTeal, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Keamanan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(CupertinoIcons.lock_rotation, color: AppColors.darkTeal, size: 20),
                      ),
                      title: const Text(
                        AppStrings.adminChangePassword,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                      onTap: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLightColor,
                    foregroundColor: AppColors.errorRed2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(CupertinoIcons.square_arrow_right),
                  label: const Text(
                    'KELUAR DARI AKUN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.darkTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textGray,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
