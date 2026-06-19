import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
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
            content: Text('Notifikasi push broadcast berhasil dikirim!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim broadcast: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
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
            content: Text('Setelan global berhasil disimpan!'),
            backgroundColor: Color(0xFF006A35),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan setelan: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
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
        title: const Text('Keluar dari Akun'),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari Master Control?'),
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
                context.go('/login');
              }
            },
            child: const Text('Keluar'),
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
    const Color primaryTeal = Color(0xFF003434);
    const Color accentOrange = Color(0xFF904D00);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right,
                color: AppColors.error, size: 22),
            tooltip: 'Keluar',
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
                  'Global platform controls and configurations.',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    color: const Color(0xFF3F4848),
                  ),
                ),
                const SizedBox(height: 24),

                // Broadcast Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: primaryTeal.withValues(alpha: 0.1),
                            child: const Icon(CupertinoIcons.speaker_2, color: primaryTeal, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Push Broadcast',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target Dropdown
                      Text(
                        'Target Audience',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAudience,
                            isExpanded: true,
                            icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: primaryTeal),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1B),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Users')),
                              DropdownMenuItem(value: 'merchants', child: Text('Merchants Only')),
                              DropdownMenuItem(value: 'students', child: Text('Students Only')),
                              DropdownMenuItem(value: 'staff', child: Text('Staff Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAudience = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message textarea
                      Text(
                        'Message Content',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _broadcastController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Type your notification message here...',
                            hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Send Button
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _sendBroadcast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(CupertinoIcons.paperplane_fill, size: 16),
                        label: const Text(
                          'KIRIM NOTIFIKASI PUSH',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Responsive Grid for API and Access
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment API Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFFFE0C2).withValues(alpha: 0.3),
                                  child: const Icon(CupertinoIcons.link, color: accentOrange, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Payment API',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Logo & Status
                            Row(
                              children: [
                                const Text('Midtrans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF9EE),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF006A35)),
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
                                          color: _isSandbox ? primaryTeal : const Color(0xFFF5F3F2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Sandbox',
                                          style: TextStyle(
                                            fontSize: 9, 
                                            fontWeight: FontWeight.bold,
                                            color: _isSandbox ? Colors.white : AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _isSandbox = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: !_isSandbox ? primaryTeal : const Color(0xFFF5F3F2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Prod',
                                          style: TextStyle(
                                            fontSize: 9, 
                                            fontWeight: FontWeight.bold,
                                            color: !_isSandbox ? Colors.white : AppColors.textDark,
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
                                color: const Color(0xFFF5F3F2),
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
                                      color: primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // System Access (Maintenance) Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: _isMaintenanceMode 
                                ? const Color(0xFFFFDAD6) 
                                : Colors.transparent,
                            width: 1,
                          ),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFFFDAD6),
                                  child: const Icon(CupertinoIcons.hammer, color: Color(0xFFBA1A1A), size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'System Access',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFBA1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Mode pemeliharaan memblokir semua akses login non-admin.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Maintenance',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 44,
                                  height: 28,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: CupertinoSwitch(
                                      value: _isMaintenanceMode,
                                      activeTrackColor: primaryTeal,
                                      onChanged: (val) {
                                        setState(() {
                                          _isMaintenanceMode = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save Global Settings Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveGlobalSettings(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500), // Accent Orange
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isSaving 
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Icon(CupertinoIcons.floppy_disk),
                  label: const Text(
                    'SIMPAN SETELAN GLOBAL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // Account & Logout Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: primaryTeal.withValues(alpha: 0.1),
                            child: const Icon(CupertinoIcons.person_solid,
                                color: primaryTeal, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Akun & Keamanan',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // User info row
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: primaryTeal.withValues(alpha: 0.1),
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1B1C1B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Super Admin',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDAD6),
                          foregroundColor: const Color(0xFFBA1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        icon: const Icon(CupertinoIcons.square_arrow_right,
                            size: 18),
                        label: const Text(
                          'KELUAR DARI AKUN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator(color: primaryTeal)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
