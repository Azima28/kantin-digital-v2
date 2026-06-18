import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

class KeuanganProfileScreen extends ConsumerStatefulWidget {
  const KeuanganProfileScreen({super.key});

  @override
  ConsumerState<KeuanganProfileScreen> createState() => _KeuanganProfileScreenState();
}

class _KeuanganProfileScreenState extends ConsumerState<KeuanganProfileScreen> {
  static const Color primaryTeal = Color(0xFF003434);
  static const Color dangerRed = Color(0xFFBA1A1A);
  static const Color successGreen = Color(0xFF006A35);

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
              title: const Text('Ubah Kata Sandi'),
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
                  child: const Text('Batal'),
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

                            // 1. Update profiles table password field
                            await client.from('profiles').update({'password': password}).eq('id', profileId);

                            // 2. Try RPC password update if available locally
                            try {
                              await client.rpc('update_auth_user_password', params: {
                                'user_id': profileId,
                                'new_password': password,
                              });
                            } catch (_) {}

                            _passwordController.clear();
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Kata sandi berhasil diubah!'),
                                backgroundColor: successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengubah kata sandi: $e'),
                                backgroundColor: dangerRed,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            setDialogState(() {
                              _isChangingPassword = false;
                            });
                          }
                        },
                  child: _isChangingPassword
                      ? const CupertinoActivityIndicator()
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogout() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun keuangan ini?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              router.go('/login');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).profile;
    final fullName = profile?['full_name'] ?? 'Admin Keuangan';
    final email = profile?['email'] ?? '-';
    final username = profile?['username'] ?? 'budi_fin';
    final school = profile?['assigned_school'] ?? 'SMP Terpadu';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Avatar Bento Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryTeal.withValues(alpha: 0.08),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      fullName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C1B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Keuangan · $school',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: const Color(0xFF6F7978),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Informational Account Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Akun',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFF1B1C1B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Email', email),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildInfoRow('Username', username),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildInfoRow('Level Otoritas', 'L1 (Operator)'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFE4E2E1)),
                    _buildInfoRow('Sekolah Asal', school),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Security Options Card ───
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 8),
                      child: Text(
                        'Pengaturan Keamanan',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryTeal.withValues(alpha: 0.08),
                        child: const Icon(CupertinoIcons.lock_shield, color: primaryTeal, size: 20),
                      ),
                      title: Text(
                        'Ubah Kata Sandi',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: const Color(0xFF1B1C1B),
                        ),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFF6F7978)),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Logout Button ───
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleLogout,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: dangerRed.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: dangerRed.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    '🚪 KELUAR DARI AKUN',
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: dangerRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(color: const Color(0xFF6F7978), fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B1C1B),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
