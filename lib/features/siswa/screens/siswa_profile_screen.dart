import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

class SiswaProfileScreen extends ConsumerWidget {
  const SiswaProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun siswa ini?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordPanel(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.white.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Scale + Fade animation
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _ChangePasswordPanel(parentContext: context),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAvatarChange(BuildContext context, WidgetRef ref) async {
    // Show action sheet to pick source
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Ubah Foto Profil'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(context, ref, ImageSource.camera);
            },
            child: const Text('Ambil Foto dari Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(context, ref, ImageSource.gallery);
            },
            child: const Text('Pilih dari Galeri'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id'];
    if (userId == null) return;

    final client = ref.read(supabaseClientProvider);
    final storageService = StorageService(client);

    final imageFile = await storageService.pickImage(source: source);
    if (imageFile == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto...'),
          duration: Duration(seconds: 60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      await storageService.uploadAvatar(userId: userId, imageFile: imageFile);
      ref.invalidate(siswaStudentProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload foto: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(siswaStudentProvider);
    final authState = ref.watch(authNotifierProvider);
    final parentContactAsync = ref.watch(siswaParentContactProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Siswa';
    final String email = authState.profile?['email'] ?? '';
    final String nis = authState.profile?['nisn'] ?? email.split('@').first;

    final String parentEmail = parentContactAsync.maybeWhen(
      data: (data) => data?['email'] ?? 'budi.subarjo@gmail.com',
      orElse: () => 'budi.subarjo@gmail.com',
    );
    final String parentPhone = parentContactAsync.maybeWhen(
      data: (data) => data?['phone'] ?? '08123456789',
      orElse: () => '08123456789',
    );

    // Avatar URL from profile (dari Supabase Storage)
    final String? avatarUrl = authState.profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: studentAsync.when(
        data: (student) {
          final String studentClass = student?.class_ ?? '8-B';

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            'Akun',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Profile Card ──
                      _buildCard(
                        child: Column(
                          children: [
                            // Avatar + Name + NIS
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _handleAvatarChange(context, ref),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFE5E5EA),
                                          ),
                                          child: ClipOval(
                                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                                ? Image.network(
                                                    avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        const Icon(
                                                          CupertinoIcons.person,
                                                          color: AppColors.primary,
                                                          size: 40,
                                                        ),
                                                  )
                                                : const Icon(
                                                    CupertinoIcons.person,
                                                    color: AppColors.primary,
                                                    size: 40,
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.camera,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    fullName,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'NIS: $nis \u2022 Kelas $studentClass',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textGray,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── KONTAK ORANG TUA ──
                      _buildSectionHeader('KONTAK ORANG TUA'),
                      const SizedBox(height: 8),
                      _buildCard(
                        child: Column(
                          children: [
                            _buildIconRow(
                              icon: CupertinoIcons.envelope,
                              iconColor: AppColors.textGray,
                              label: 'Email',
                              value: parentEmail,
                              showDivider: true,
                            ),
                            _buildIconRow(
                              icon: CupertinoIcons.phone,
                              iconColor: AppColors.textGray,
                              label: 'No. HP',
                              value: parentPhone,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── KEAMANAN & AKSES ──
                      _buildSectionHeader('KEAMANAN & AKSES'),
                      const SizedBox(height: 8),
                      _buildCard(
                        child: Column(
                          children: [
                            _buildIconActionRow(
                              icon: CupertinoIcons.lock,
                              iconColor: AppColors.textGray,
                              label: 'Ubah Sandi Akun',
                              onTap: () =>
                                  _showChangePasswordPanel(context, ref),
                              showDivider: true,
                            ),
                            _buildIconActionRow(
                              icon: CupertinoIcons.square_arrow_right,
                              iconColor: AppColors.error,
                              label: 'Keluar dari Akun',
                              textColor: AppColors.error,
                              onTap: () => _handleLogout(context, ref),
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CupertinoActivityIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Gagal memuat profil: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textGray,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildIconRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.borderLight,
            ),
          ),
      ],
    );
  }

  Widget _buildIconActionRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? textColor,
    required VoidCallback onTap,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: Color(0xFFC7C7CC),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.borderLight,
            ),
          ),
      ],
    );
  }
}

// ── Change Password Floating Panel ──

class _ChangePasswordPanel extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const _ChangePasswordPanel({required this.parentContext});

  @override
  ConsumerState<_ChangePasswordPanel> createState() =>
      _ChangePasswordPanelState();
}

class _ChangePasswordPanelState extends ConsumerState<_ChangePasswordPanel> {
  final _formKey = GlobalKey<FormState>();
  final _oldPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _oldPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final String oldPwd = _oldPwdController.text;
    final String newPwd = _newPwdController.text;

    final authState = ref.read(authNotifierProvider);
    final profileId = authState.profile?['id'];
    if (profileId == null) {
      setState(() => _isSaving = false);
      return;
    }

    // Simpan reference sebelum async gap untuk menghindari context warning
    final messenger = ScaffoldMessenger.of(widget.parentContext);
    final nav = Navigator.of(context);

    try {
      final client = ref.read(supabaseClientProvider);

      // Verify old password
      final profile = await client
          .from('profiles')
          .select('password')
          .eq('id', profileId)
          .single();

      if (!mounted) return;
      if (profile['password'] != oldPwd) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Sandi lama yang dimasukkan salah.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Update new password
      await client
          .from('profiles')
          .update({'password': newPwd})
          .eq('id', profileId);

      if (!mounted) return;
      nav.pop(); // close dialog
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah kata sandi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button + Title
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Ubah Sandi Akun',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            size: 16,
                            color: AppColors.textGray,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Old Password
                _buildPasswordField(
                  controller: _oldPwdController,
                  label: 'Kata Sandi Lama',
                  obscure: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // New Password
                _buildPasswordField(
                  controller: _newPwdController,
                  label: 'Kata Sandi Baru',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Wajib diisi';
                    if (val.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm New Password
                _buildPasswordField(
                  controller: _confirmPwdController,
                  label: 'Konfirmasi Kata Sandi Baru',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Wajib diisi';
                    if (val != _newPwdController.text) {
                      return 'Kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buttons Row
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textGray,
                          side: const BorderSide(color: Color(0xFFD1D1D6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Save Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D1D6), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: Icon(
                CupertinoIcons.lock,
                size: 18,
                color: AppColors.textGray,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 18,
                  color: AppColors.textGray,
                ),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
