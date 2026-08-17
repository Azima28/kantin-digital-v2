import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/admin_settings_broadcast_section.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _broadcastController = TextEditingController();
  String _selectedAudience = 'all';

  // API State
  bool _isSandbox = true;
  final String _mockClientKey = 'SB-Mid-client-1234567890';
  final String _mockProdKey = 'PR-Mid-client-0987654321';
  bool _obscureKey = true;

  // Maintenance State
  bool _isMaintenanceMode = false;
  bool _stateLoaded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  void _loadSettings(Map<String, dynamic> settings) {
    if (_stateLoaded) return;

    // Load maintenance mode
    _isMaintenanceMode = settings['maintenance_mode'] == true;

    // Load midtrans mode
    final midtrans = settings['midtrans_config'] ?? {};
    _isSandbox = midtrans['mode'] != 'production';

    _stateLoaded = true;
  }

  Future<void> _sendBroadcast() async {
    final String msg = _broadcastController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/admin/broadcast', body: {
        'audience': _selectedAudience,
        'title': 'Pengumuman Admin',
        'message': msg,
      });

      if (!response.success) {
        throw Exception(response.message ?? 'Gagal mengirim broadcast');
      }

      if (mounted) {
        _broadcastController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPushSent),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengirim broadcast: $e'),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveGlobalSettings(Map<String, dynamic> oldSettings) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final String mode = _isSandbox ? 'sandbox' : 'production';
      final String clientKey = _isSandbox ? _mockClientKey : _mockProdKey;

      final Map<String, dynamic> newMidtrans = {
        'mode': mode,
        'client_key': clientKey,
        'is_active': true,
      };

      await apiClient.post('/admin/settings', body: {
        'maintenance_mode': _isMaintenanceMode,
        'midtrans_config': newMidtrans,
      });

      ref.invalidate(adminSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successSettingsSaved),
            backgroundColor: Nebula.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedSaveSettings),
            backgroundColor: Nebula.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }


  Future<void> _handleAvatarChange() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Ubah Foto Profil Admin'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(ImageSource.camera);
            },
            child: const Text('Ambil Foto dari Kamera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadAvatar(ImageSource.gallery);
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
          content: Text('Mengupload foto profil admin...'),
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
            content: Text('Foto profil admin berhasil diperbarui!'),
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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final authState = ref.watch(authNotifierProvider);
    final String adminName = authState.profile?['full_name'] ?? 'Super Admin';
    final String adminEmail = authState.profile?['email'] ?? 'admin@sekolah.sch.id';
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
          'Setelan Sistem',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _loadSettings(settings);

          final Widget adminProfileCard = Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _handleAvatarChange,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Nebula.teal.withValues(alpha: 0.1),
                          border: Border.all(color: Nebula.teal.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
                                  errorWidget: (_, __, ___) => const Center(
                                    child: Icon(Icons.shield_rounded, size: 28, color: Nebula.teal),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.shield_rounded, size: 28, color: Nebula.teal),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
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
                            size: 12,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adminEmail,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Nebula.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Super Administrator',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Nebula.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final Widget paymentApiCard = SettingSectionWidget(
            icon: CupertinoIcons.link,
            title: 'Payment API',
            horizontalPadding: 16,
            verticalPadding: 16,
            iconRadius: 16,
            iconBackgroundColor: Nebula.amber.withValues(alpha: 0.3),
            iconColor: Nebula.amber,
            shadowBlurRadius: 15,
            children: [
              // Logo & Status
              Row(
                children: [
                  Text('Midtrans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Nebula.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Nebula.teal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Env Mode switcher
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Env', style: TextStyle(fontSize: 11, color: context.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      PressScale(
                        onTap: () => setState(() => _isSandbox = true),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isSandbox ? Nebula.teal : context.surfaceBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sandbox',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _isSandbox ? context.textPrimary : context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      PressScale(
                        onTap: () => setState(() => _isSandbox = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: !_isSandbox ? Nebula.teal : context.surfaceBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Prod',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: !_isSandbox ? context.textPrimary : context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Key field
              Text('Client Key', style: TextStyle(fontSize: 10, color: context.textSecondary)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _obscureKey
                            ? '••••••••••••••••••••'
                            : (_isSandbox ? _mockClientKey : _mockProdKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Courier', fontSize: 10),
                      ),
                    ),
                    PressScale(
                      onTap: () => setState(() => _obscureKey = !_obscureKey),
                      child: Icon(
                        _obscureKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        size: 14,
                        color: Nebula.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget systemAccessCard = SettingSectionWidget(
            icon: CupertinoIcons.hammer,
            title: 'System Access',
            horizontalPadding: 16,
            verticalPadding: 16,
            iconRadius: 16,
            iconBackgroundColor: Nebula.rose.withValues(alpha: 0.1),
            iconColor: Nebula.rose,
            titleColor: Nebula.rose,
            shadowBlurRadius: 15,
            children: [
              Text(
                'Mode pemeliharaan memblokir semua akses login non-admin.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 16),
              SettingTileWidget(
                title: 'Maintenance',
                trailing: SizedBox(
                  width: 44,
                  height: 28,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CupertinoSwitch(
                      value: _isMaintenanceMode,
                      activeTrackColor: Nebula.teal,
                      onChanged: (val) {
                        setState(() {
                          _isMaintenanceMode = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Admin Profile Card with Avatar Upload ──
                adminProfileCard,

                // Top subtitle
                Text(
                  'Kontrol dan konfigurasi platform global.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Broadcast Section ──────────────────────────────────────
                AdminSettingsBroadcastSection(
                  broadcastController: _broadcastController,
                  selectedAudience: _selectedAudience,
                  isSaving: _isSaving,
                  onAudienceChanged: (val) {
                    setState(() {
                      _selectedAudience = val;
                    });
                  },
                  onSend: _sendBroadcast,
                ),
                const GradientLine(),

                // ── Responsive Grid for API and Access ────────────────────
                Responsive.isMobile(context)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          paymentApiCard,
                          const SizedBox(height: 16),
                          systemAccessCard,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: paymentApiCard),
                          const SizedBox(width: 12),
                          Expanded(child: systemAccessCard),
                        ],
                      ),
                const SizedBox(height: 24),

                // ── Save Global Settings Button ────────────────────────────
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveGlobalSettings(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.amber,
                    foregroundColor: context.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isSaving
                      ? CupertinoActivityIndicator(color: context.cardBg)
                      : const Icon(CupertinoIcons.floppy_disk),
                  label: const Text(
                    'SIMPAN SETELAN GLOBAL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => Shimmer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            SkeletonBox(width: 120, height: 14, borderRadius: 4),
                            Spacer(),
                            SkeletonBox(width: 45, height: 26, borderRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SkeletonBox(width: 120, height: 14, borderRadius: 4),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderLight, width: 0.8),
                  ),
                  child: Column(
                    children: List.generate(
                      2,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: const [
                            SkeletonBox(width: 100, height: 14, borderRadius: 4),
                            Spacer(),
                            SkeletonBox(width: 45, height: 26, borderRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
              const SizedBox(height: 12),
              Text('${AppStrings.labelFailed} memuat data'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminSettingsProvider),
                child: const Text(AppStrings.buttonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}