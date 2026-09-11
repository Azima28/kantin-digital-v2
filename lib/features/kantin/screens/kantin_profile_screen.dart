import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/widgets/logout_confirmation_dialog.dart';
import 'package:kantin_digital/core/widgets/app_image_picker_sheet.dart';
import 'package:kantin_digital/core/widgets/change_password_panel.dart';
import 'package:kantin_digital/core/widgets/theme_toggle_tile.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/kantin/providers/pos_providers.dart';
import 'package:kantin_digital/features/public/providers/public_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/app_avatar.dart';

class KantinProfileScreen extends ConsumerStatefulWidget {
  const KantinProfileScreen({super.key});

  @override
  ConsumerState<KantinProfileScreen> createState() => _KantinProfileScreenState();
}

class _KantinProfileScreenState extends ConsumerState<KantinProfileScreen> {
  final TextEditingController _deliveryFeeController = TextEditingController(text: '2000');
  bool _isDeliveryEnabled = true;
  bool _isDeliveryInitialized = false;
  bool _isSavingDelivery = false;
  Timer? _deliveryDebounce;

  @override
  void dispose() {
    _deliveryDebounce?.cancel();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.white.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
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
              child: ChangePasswordPanel(parentContext: context),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog({
    required String currentName,
    required String currentUsername,
    required String currentPhone,
    required String currentEmail,
  }) {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername);
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
                                  'Edit Detail Profil',
                                  style: GoogleFonts.inter(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: ctx.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Perbarui identitas akun kasir / stan Anda',
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

                      // Nama Petugas
                      Text(
                        'Nama Petugas',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama petugas wajib diisi' : null,
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

                      // Username
                      Text(
                        'Username',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usernameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                        style: GoogleFonts.inter(fontSize: 13.5, color: ctx.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Username login',
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

                      // No. Telepon / WhatsApp
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
                                            username: usernameController.text.trim(),
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

  Future<void> _autoSaveDelivery({bool? enabled, int? fee}) async {
    final operatorId = ref.read(authNotifierProvider).profile?['id'];
    if (operatorId == null) return;

    final targetEnabled = enabled ?? _isDeliveryEnabled;
    final targetFee = fee ?? (int.tryParse(_deliveryFeeController.text.replaceAll('.', '').trim()) ?? 2000);

    setState(() => _isSavingDelivery = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch('/pos/delivery-settings', body: {
        'is_delivery_enabled': targetEnabled,
        'delivery_fee': targetFee,
      });

      ref.invalidate(canteenOperatorProvider);
      ref.invalidate(publicCanteensProvider);
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSavingDelivery = false);
      }
    }
  }

  void _onFeeChanged(String val) {
    _deliveryDebounce?.cancel();
    _deliveryDebounce = Timer(const Duration(milliseconds: 600), () {
      final fee = int.tryParse(val.replaceAll('.', '').trim());
      if (fee != null) {
        _autoSaveDelivery(fee: fee);
      }
    });
  }

  Future<void> _handleAvatarChange() async {
    await showAppImagePickerBottomSheet(
      context,
      title: 'Ubah Foto Profil Stan',
      onSourceSelected: (source) => _uploadAvatar(source),
    );
  }

  Future<void> _uploadAvatar(ImageSource source) async {
    final authState = ref.read(authNotifierProvider);
    final String? userId = authState.profile?['id'];
    if (userId == null) return;

    final apiClient = ref.read(apiClientProvider);
    final storageService = StorageService(apiClient);

    final imageFile = await storageService.pickImage(context: context, source: source);
    if (imageFile == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mengupload foto profil stan...'),
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
      ref.invalidate(canteenOperatorProvider);
      ref.invalidate(publicCanteensProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil stan berhasil diperbarui!'),
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
    final String canteenName = authState.profile?['canteen_name'] ?? 'Stan Kantin';
    final String fullName = authState.profile?['full_name'] ?? 'Petugas Kantin';
    final String email = authState.profile?['email'] ?? '';
    final String username = authState.profile?['username'] ?? '';
    final String phone = authState.profile?['phone_number'] ?? '-';
    final operatorAsync = ref.watch(canteenOperatorProvider);

    operatorAsync.whenData((op) {
      if (op != null && !_isDeliveryInitialized) {
        _isDeliveryInitialized = true;
        _isDeliveryEnabled = op.isDeliveryEnabled;
        _deliveryFeeController.text = op.deliveryFee.toString();
      }
    });

    final String? avatarUrl = authState.profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: context.dividerCol, width: 0.5),
        ),
        title: Text(
          'Akun Saya',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 18),
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
                      Nebula.teal,
                      Nebula.tealDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Nebula.teal.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Editable Profile Avatar with Camera Button
                    GestureDetector(
                      onTap: _handleAvatarChange,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppAvatar(
                            radius: 42,
                            photoUrl: avatarUrl,
                            role: 'petugas_kantin',
                            name: canteenName,
                            borderColor: Colors.white.withValues(alpha: 0.5),
                            borderWidth: 2,
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.camera_fill,
                                size: 14,
                                color: Nebula.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      canteenName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.cardBg,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.cardBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Petugas Kantin · Kasir',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.cardBg.withValues(alpha: 0.9),
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
                trailing: InkWell(
                  onTap: () => _showEditProfileDialog(
                    currentName: fullName,
                    currentUsername: username,
                    currentPhone: phone,
                    currentEmail: email,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.pencil, size: 13, color: Nebula.teal),
                        const SizedBox(width: 4),
                        Text(
                          'Edit Profil',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Nebula.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                children: [
                  _buildInfoRow('Nama Stan', canteenName),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Nama Petugas', fullName),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Email', email),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('Username', username),
                  Divider(height: 16, thickness: 0.5, color: context.borderLight),
                  _buildInfoRow('No. Telepon', phone),
                ],
              ),
              const SizedBox(height: 16),

              // Pengaturan Layanan Antar (Delivery) Card
              _buildDeliverySettingsCard(context),
              const SizedBox(height: 16),

              // Preferensi & Keamanan Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 6),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.settings, color: Nebula.teal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Preferensi & Keamanan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeToggleTile(
                      showDivider: true,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                        child: Icon(CupertinoIcons.lock_rotation, color: Nebula.teal, size: 20),
                      ),
                      title: Text(
                        AppStrings.adminChangePassword,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Kelola kata sandi akun kasir Anda',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                      trailing: Icon(CupertinoIcons.chevron_forward, size: 16, color: context.textSecondary),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(CupertinoIcons.square_arrow_right, size: 20),
                  label: Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.cardBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.rose,
                    foregroundColor: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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

  Widget _buildDeliverySettingsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Layanan Antar (Delivery)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isSavingDelivery)
                const CupertinoActivityIndicator(radius: 8)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                      const SizedBox(width: 3),
                      Text(
                        'Tersimpan',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terima Pesanan Delivery',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDeliveryEnabled
                          ? 'Siswa dapat memilih opsi antar ke meja/kelas'
                          : 'Siswa hanya dapat memilih ambil sendiri (Pickup)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _isDeliveryEnabled,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  setState(() => _isDeliveryEnabled = val);
                  _autoSaveDelivery(enabled: val);
                },
              ),
            ],
          ),

          // Ongkir Input
          if (_isDeliveryEnabled) ...[
            const SizedBox(height: 14),
            Text(
              'Tarif Ongkos Kirim (Delivery Fee)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _deliveryFeeController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
              onChanged: _onFeeChanged,
              onSubmitted: (val) => _autoSaveDelivery(),
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rp',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '2000',
                filled: true,
                fillColor: context.surfaceBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Nebula.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}