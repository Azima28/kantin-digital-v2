import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
import 'package:kantin_digital/features/admin/widgets/admin_settings_account_section.dart';
import 'package:kantin_digital/features/admin/widgets/admin_settings_broadcast_section.dart';
import 'package:kantin_digital/features/admin/widgets/setting_tile_widget.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

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

    final client = ref.read(supabaseClientProvider);
    try {
      // Create FCM notification log or audit log
      await client.from('audit_logs').insert({
        'actor_name': 'Super Admin',
        'action_type': 'PENGIRIMAN_BROADCAST',
        'description': 'Mengirim notifikasi push global ke kelompok ${_selectedAudience.toUpperCase()}',
        'new_value': {'audience': _selectedAudience, 'message': msg},
      });

      if (mounted) {
        _broadcastController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successPushSent),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.labelFailed} mengirim broadcast'),
            backgroundColor: AppColors.errorRed2,
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

    final client = ref.read(supabaseClientProvider);
    try {
      final String mode = _isSandbox ? 'sandbox' : 'production';
      final String clientKey = _isSandbox ? _mockClientKey : _mockProdKey;

      final Map<String, dynamic> newMidtrans = {
        'mode': mode,
        'client_key': clientKey,
        'is_active': true,
      };

      // 1. Save Maintenance Mode
      await client.from('system_settings').update({
        'value': _isMaintenanceMode,
      }).eq('key', 'maintenance_mode');

      // 2. Save Midtrans Config
      await client.from('system_settings').update({
        'value': newMidtrans,
      }).eq('key', 'midtrans_config');

      // 3. Log Audit
      await client.from('audit_logs').insert({
        'actor_name': 'Super Admin',
        'action_type': 'UBAH_SETELAN',
        'description': 'Super Admin memperbarui setelan global platform (Pemeliharaan & API)',
        'old_value': {
          'maintenance_mode': oldSettings['maintenance_mode'],
          'midtrans_config': oldSettings['midtrans_config'],
        },
        'new_value': {
          'maintenance_mode': _isMaintenanceMode,
          'midtrans_config': newMidtrans,
        },
      });

      ref.invalidate(adminSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successSettingsSaved),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.labelFailedSaveSettings),
            backgroundColor: AppColors.errorRed2,
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text(AppStrings.buttonLogout),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari Master Control?'),
        actions: [
          CupertinoDialogAction(
            child: const Text(AppStrings.buttonCancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text(AppStrings.buttonLogout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final authState = ref.watch(authNotifierProvider);
    final String fullName = authState.profile?['full_name'] ?? 'Super Admin';
    final String email = authState.profile?['email'] ?? 'admin@kantindigital.com';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right,
                color: AppColors.error, size: 22),
            tooltip: AppStrings.buttonLogout,
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          _loadSettings(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top subtitle
                Text(
                  'Kontrol dan konfigurasi platform global.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.darkGray,
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
                const SizedBox(height: 12),

                // ── Responsive Grid for API and Access ────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment API Card
                    Expanded(
                      child: SettingSectionWidget(
                        icon: CupertinoIcons.link,
                        title: 'Payment API',
                        horizontalPadding: 16,
                        verticalPadding: 16,
                        iconRadius: 16,
                        iconBackgroundColor: AppColors.softOrange.withValues(alpha: 0.3),
                        iconColor: AppColors.darkOrange,
                        shadowBlurRadius: 15,
                        children: [
                          // Logo & Status
                          Row(
                            children: [
                              const Text('Midtrans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Env Mode switcher
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Env', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _isSandbox = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _isSandbox ? AppColors.darkTeal : AppColors.offWhite2,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Sandbox',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _isSandbox ? AppColors.white : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _isSandbox = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: !_isSandbox ? AppColors.darkTeal : AppColors.offWhite2,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Prod',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: !_isSandbox ? AppColors.white : AppColors.textDark,
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
                          const Text('Client Key', style: TextStyle(fontSize: 10, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.offWhite2,
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
                                GestureDetector(
                                  onTap: () => setState(() => _obscureKey = !_obscureKey),
                                  child: Icon(
                                    _obscureKey ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                    size: 14,
                                    color: AppColors.darkTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // System Access (Maintenance) Card
                    Expanded(
                      child: SettingSectionWidget(
                        icon: CupertinoIcons.hammer,
                        title: 'System Access',
                        horizontalPadding: 16,
                        verticalPadding: 16,
                        iconRadius: 16,
                        iconBackgroundColor: AppColors.errorLightColor,
                        iconColor: AppColors.errorRed2,
                        titleColor: AppColors.errorRed2,
                        shadowBlurRadius: 15,
                        children: [
                          Text(
                            'Mode pemeliharaan memblokir semua akses login non-admin.',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SettingTileWidget(
                            title: 'Maintenance',
                            trailing: SizedBox(
                              width: 44,
                              height: 28,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: CupertinoSwitch(
                                  value: _isMaintenanceMode,
                                  activeTrackColor: AppColors.darkTeal,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Save Global Settings Button ────────────────────────────
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveGlobalSettings(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkOrange,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isSaving
                      ? const CupertinoActivityIndicator(color: AppColors.white)
                      : const Icon(CupertinoIcons.floppy_disk),
                  label: const Text(
                    'SIMPAN SETELAN GLOBAL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Account & Logout Section ───────────────────────────────
                AdminSettingsAccountSection(
                  fullName: fullName,
                  email: email,
                  onLogout: () => _showLogoutDialog(context, ref),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.darkTeal)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
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
