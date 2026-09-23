import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/providers/theme_provider.dart';
import 'package:kantin_digital/core/widgets/app_image_picker_sheet.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';
import 'package:kantin_digital/core/widgets/about_sekantin_sheet.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Settings section for parent dashboard with profile avatar upload, daily limit, and card freeze.
class ParentSettingsSection extends ConsumerStatefulWidget {
  final bool dailyLimitActive;
  final TextEditingController limitController;
  final bool cardFrozen;
  final bool isSaving;
  final ValueChanged<bool> onDailyLimitChanged;
  final ValueChanged<bool> onCardFrozenChanged;
  final VoidCallback onSave;

  const ParentSettingsSection({
    super.key,
    required this.dailyLimitActive,
    required this.limitController,
    required this.cardFrozen,
    required this.isSaving,
    required this.onDailyLimitChanged,
    required this.onCardFrozenChanged,
    required this.onSave,
  });

  @override
  ConsumerState<ParentSettingsSection> createState() => _ParentSettingsSectionState();
}

class _ParentSettingsSectionState extends ConsumerState<ParentSettingsSection> {
  Future<void> _handleAvatarChange() async {
    await showAppImagePickerBottomSheet(
      context,
      title: 'Ubah Foto Profil Orang Tua',
      onSourceSelected: (source) => _uploadAvatar(source),
    );
  }

  Future<void> _uploadAvatar(ImageSource source) async {
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id'];
    if (userId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final storageService = StorageService(apiClient);

    final imageFile = await storageService.pickImage(source: source);
    if (imageFile == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto profil...'),
          duration: Duration(seconds: 60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      final avatarUrl = await storageService.uploadAvatar(
        userId: userId,
        imageFile: imageFile,
      );

      await ref.read(authNotifierProvider.notifier).updateProfileAvatar(avatarUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload foto: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog({
    required String currentName,
    required String currentEmail,
    required String currentPhone,
  }) {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);

    String cleanPhone = currentPhone == '-' ? '' : currentPhone;
    cleanPhone = cleanPhone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleanPhone.startsWith('+62')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('62')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    cleanPhone = cleanPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneController = TextEditingController(text: cleanPhone);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                color: ctx.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ctx.dividerCol, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: ctx.shadowColor,
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Nebula.teal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, color: Nebula.teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Profil Wali Murid',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: ctx.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Perbarui data kontak akun orang tua murid',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: ctx.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Nama Lengkap
                      Text(
                        'Nama Lengkap',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                        style: GoogleFonts.inter(fontSize: 13.5, color: ctx.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Nama lengkap Anda',
                          hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: ctx.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      Text(
                        'Email',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                        style: GoogleFonts.inter(fontSize: 13.5, color: ctx.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'email@sekolah.sch.id',
                          hintStyle: GoogleFonts.inter(color: ctx.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: ctx.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // No. Telepon / WhatsApp with uneditable +62 prefix
                      Text(
                        'No. Telepon / WhatsApp',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) {
                          if (val.startsWith('0')) {
                            final stripped = val.replaceFirst(RegExp(r'^0+'), '');
                            phoneController.value = TextEditingValue(
                              text: stripped,
                              selection: TextSelection.collapsed(offset: stripped.length),
                            );
                          } else if (val.startsWith('62')) {
                            final stripped = val.replaceFirst(RegExp(r'^62'), '');
                            phoneController.value = TextEditingValue(
                              text: stripped,
                              selection: TextSelection.collapsed(offset: stripped.length),
                            );
                          }
                        },
                        style: GoogleFonts.inter(fontSize: 13.5, color: ctx.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.only(left: 14, right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+62',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Nebula.teal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: ctx.dividerCol,
                                ),
                              ],
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '81234567890',
                          hintStyle: GoogleFonts.inter(color: ctx.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                          filled: true,
                          fillColor: ctx.surfaceBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.dividerCol)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: ctx.dividerCol),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                AppStrings.buttonCancel,
                                style: GoogleFonts.inter(color: ctx.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setModalState(() => isSaving = true);
                                      final cleanDigits = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                                      final fullPhone = cleanDigits.isNotEmpty ? '+62$cleanDigits' : null;
                                      final ok = await ref.read(authNotifierProvider.notifier).updateProfileDetails(
                                            fullName: nameController.text.trim(),
                                            email: emailController.text.trim(),
                                            phoneNumber: fullPhone,
                                          );
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ok ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil'),
                                            backgroundColor: ok ? Nebula.teal : Nebula.rose,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Nebula.teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      AppStrings.buttonSave,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final String parentName = authState.profile?['full_name'] ?? 'Orang Tua Murid';
    final String parentEmail = authState.profile?['email'] ?? 'wali@sekolah.sch.id';
    final String parentPhone = authState.profile?['phone_number'] ?? '';
    final String? avatarUrl = authState.profile?['avatar_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Parent Profile Card with Avatar Upload ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _handleAvatarChange,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppAvatar(
                      radius: 29,
                      photoUrl: avatarUrl,
                      role: 'parent',
                      name: parentName,
                      gender: authState.profile?['gender'] as String?,
                      borderColor: Nebula.teal.withValues(alpha: 0.3),
                      borderWidth: 2,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.borderLight, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.camera_fill,
                          size: 11,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parentEmail,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Wali Murid / Orang Tua',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Nebula.teal,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showEditProfileDialog(
                            currentName: parentName,
                            currentEmail: parentEmail,
                            currentPhone: parentPhone,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.pencil, size: 12, color: Nebula.teal),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Profil',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Nebula.teal,
                                  ),
                                ),
                              ],
                            ),
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
        const SizedBox(height: 16),

        // Dark Mode Toggle Card
        Consumer(
          builder: (context, ref, child) {
            final isDark = ref.watch(themeProvider) == ThemeMode.dark;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.dividerCol, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Gelap',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aktifkan mode malam untuk tampilan yang nyaman bagi mata.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: isDark,
                    activeTrackColor: Nebula.teal,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Daily limit toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batas Saku Harian',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Batasi pengeluaran jajan anak per hari.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: widget.dailyLimitActive,
                    activeTrackColor: Nebula.teal,
                    onChanged: widget.onDailyLimitChanged,
                  ),
                ],
              ),
              if (widget.dailyLimitActive) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: widget.limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Limit Harian',
                    hintText: 'Contoh: 20000',
                    prefixIcon: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Nebula.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rp',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Nebula.teal,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card freeze toggle
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bekukan Kartu RFID',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nonaktifkan sementara transaksi kartu jika hilang/dicuri.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: widget.cardFrozen,
                activeTrackColor: Nebula.rose,
                onChanged: widget.onCardFrozenChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        ElevatedButton(
          onPressed: widget.isSaving ? null : widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Nebula.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: widget.isSaving
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  'Simpan Pengaturan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // Tentang SeKantin Tile
        Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerCol, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: Nebula.teal.withValues(alpha: 0.08),
              child: const Icon(CupertinoIcons.info_circle_fill, color: Nebula.teal, size: 20),
            ),
            title: Text(
              'Tentang SeKantin',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              'Informasi filosofi, sistem keamanan, & bantuan',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.textSecondary,
              ),
            ),
            trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: context.textSecondary),
            onTap: () => showAboutSeKantinSheet(context),
          ),
        ),
      ],
    );
  }
}
