import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_digital/core/services/storage_service.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/admin_settings_broadcast_section.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';
import 'package:kantin_digital/core/widgets/shimmer_loading.dart';
import 'package:kantin_digital/core/widgets/app_image_picker_sheet.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _broadcastController = TextEditingController();
  final _clientKeyController = TextEditingController();
  final _serverKeyController = TextEditingController();
  final _merchantIdController = TextEditingController();
  String _selectedAudience = 'all';

  // API State
  bool _isSandbox = true;
  bool _isPaymentApiActive = true;
  bool _obscureClientKey = true;
  bool _obscureServerKey = true;

  // Maintenance State
  bool _isMaintenanceMode = false;
  bool _stateLoaded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _broadcastController.dispose();
    _clientKeyController.dispose();
    _serverKeyController.dispose();
    _merchantIdController.dispose();
    super.dispose();
  }

  void _loadSettings(Map<String, dynamic> settings) {
    if (_stateLoaded) return;

    // Load maintenance mode
    _isMaintenanceMode = settings['maintenance_mode'] == true;

    // Load midtrans config
    final midtrans = settings['midtrans_config'] is Map ? Map<String, dynamic>.from(settings['midtrans_config'] as Map) : <String, dynamic>{};
    _isSandbox = midtrans['mode'] != 'production';
    _isPaymentApiActive = midtrans['is_active'] != false;
    _clientKeyController.text = midtrans['client_key']?.toString() ?? 'SB-Mid-client-1234567890';
    _serverKeyController.text = midtrans['server_key']?.toString() ?? 'SB-Mid-server-1234567890';
    _merchantIdController.text = midtrans['merchant_id']?.toString() ?? 'G123456';

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

      final Map<String, dynamic> newMidtrans = {
        'mode': mode,
        'client_key': _clientKeyController.text.trim(),
        'server_key': _serverKeyController.text.trim(),
        'merchant_id': _merchantIdController.text.trim(),
        'is_active': _isPaymentApiActive,
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
    await showAppImagePickerBottomSheet(
      context,
      title: 'Ubah Foto Profil Admin',
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
            title: 'Payment Gateway (Midtrans)',
            horizontalPadding: 16,
            verticalPadding: 16,
            iconRadius: 16,
            iconBackgroundColor: Nebula.teal.withValues(alpha: 0.12),
            iconColor: Nebula.teal,
            shadowBlurRadius: 15,
            children: [
              // Logo & Status Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Midtrans',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: context.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isPaymentApiActive
                              ? Nebula.teal.withValues(alpha: 0.12)
                              : Nebula.rose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isPaymentApiActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _isPaymentApiActive ? Nebula.teal : Nebula.rose,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: _isPaymentApiActive,
                      activeTrackColor: Nebula.teal,
                      onChanged: (val) => setState(() => _isPaymentApiActive = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Env Mode switcher
              Text(
                'Mode Lingkungan (Environment)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isSandbox = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isSandbox ? Nebula.teal : context.surfaceBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSandbox ? Nebula.teal : context.dividerCol,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Sandbox (Uji Coba)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isSandbox ? Colors.white : context.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isSandbox = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isSandbox ? Nebula.teal : context.surfaceBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !_isSandbox ? Nebula.teal : context.dividerCol,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Production (Live)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: !_isSandbox ? Colors.white : context.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Client Key field
              Text(
                'Client Key',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _clientKeyController,
                obscureText: _obscureClientKey,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: InputDecoration(
                  hintText: _isSandbox ? 'SB-Mid-client-...' : 'Mid-client-...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureClientKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      size: 16,
                      color: Nebula.teal,
                    ),
                    onPressed: () => setState(() => _obscureClientKey = !_obscureClientKey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Server Key field
              Text(
                'Server Key (Secret)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _serverKeyController,
                obscureText: _obscureServerKey,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: InputDecoration(
                  hintText: _isSandbox ? 'SB-Mid-server-...' : 'Mid-server-...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureServerKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      size: 16,
                      color: Nebula.teal,
                    ),
                    onPressed: () => setState(() => _obscureServerKey = !_obscureServerKey),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Merchant ID field
              Text(
                'Merchant ID',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _merchantIdController,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Contoh: G123456789',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: context.textSecondary.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerCol)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
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

          final academicAsync = ref.watch(academicStructureProvider);
          final academic = academicAsync.asData?.value;

          final Widget academicStructureCard = Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: const Icon(CupertinoIcons.building_2_fill, color: Nebula.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Struktur Akademik & Rombel',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            academic != null
                                ? 'Jenjang ${academic.schoolType.toUpperCase()} • ${academic.majors.length} Jurusan • ${academic.rombels.length} Rombel'
                                : 'Kelola jenjang, jurusan, dan kelas paralel',
                            style: GoogleFonts.inter(fontSize: 11.5, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: context.dividerCol),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: Colors.white),
                    label: Text(
                      'Kelola Jurusan & Rombel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => context.push('/admin/settings/academic'),
                  ),
                ),
              ],
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Admin Profile Card with Avatar Upload ──
                adminProfileCard,

                // ── Master Academic Structure & Rombels Card ──
                academicStructureCard,

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