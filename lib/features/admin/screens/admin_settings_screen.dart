import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/utils/responsive.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';
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
      final profile = ref.read(authNotifierProvider).profile;
      final profileId = profile?['id'];

      final response = await client.rpc('send_broadcast_notifications', params: {
        'p_audience': _selectedAudience,
        'p_title': 'Pengumuman Admin',
        'p_message': msg,
        'p_caller_id': profileId,
      });

      if (response is Map && response['success'] == false) {
        throw Exception(response['error'] ?? 'Gagal mengirim broadcast');
      }

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

  void _showAddClassDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Tambah Kelas Baru',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkTeal),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Kelas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 7-A, 10-IPA-1, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (val) {
                    final match = RegExp(r'^[0-9]+').firstMatch(val.trim());
                    if (match != null) {
                      levelCtrl.text = match.group(0) ?? '';
                    } else {
                      levelCtrl.text = '0';
                    }
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tingkat / Level (Angka)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: levelCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 7, 8, 10, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final levelStr = levelCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama kelas tidak boleh kosong'),
                              backgroundColor: AppColors.errorRed2,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('classes').insert({
                            'name': name,
                            'level': int.tryParse(levelStr) ?? 0,
                          });

                          ref.invalidate(classesProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kelas berhasil ditambahkan'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambah kelas: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditClassDialog(BuildContext context, SchoolClass schoolClass) {
    final nameCtrl = TextEditingController(text: schoolClass.name);
    final levelCtrl = TextEditingController(text: schoolClass.level.toString());
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Ubah Kelas',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkTeal),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Kelas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 7-A, 10-IPA-1, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tingkat / Level (Angka)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: levelCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 7, 8, 10, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final levelStr = levelCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama kelas tidak boleh kosong'),
                              backgroundColor: AppColors.errorRed2,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('classes').update({
                            'name': name,
                            'level': int.tryParse(levelStr) ?? 0,
                          }).eq('id', schoolClass.id);

                          ref.invalidate(classesProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kelas berhasil diperbarui'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui kelas: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteClassConfirm(BuildContext context, SchoolClass schoolClass) {
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Hapus Kelas',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.errorRed2),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus kelas "${schoolClass.name}"?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.nearBlack),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Peringatan: Seluruh siswa yang terdaftar di kelas ini akan terlepas dari kelasnya (menjadi tanpa kelas). Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(fontSize: 11, color: AppColors.textGray),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('classes').delete().eq('id', schoolClass.id);

                          ref.invalidate(classesProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kelas berhasil dihapus'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menghapus kelas: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed2,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Hapus'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildClassesManagementCard(BuildContext context, List<SchoolClass> classes) {
    return SettingSectionWidget(
      icon: CupertinoIcons.square_grid_2x2,
      title: 'Daftar Kelas',
      horizontalPadding: 16,
      verticalPadding: 16,
      iconRadius: 16,
      iconBackgroundColor: AppColors.primaryLight,
      iconColor: AppColors.primary,
      shadowBlurRadius: 15,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kelola daftar kelas aktif',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGray),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddClassDialog(context),
              icon: const Icon(CupertinoIcons.plus, size: 14),
              label: const Text('Tambah Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Belum ada data kelas.',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.offWhite2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderLight,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) {
                final cls = classes[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          cls.level > 0 ? cls.level.toString() : '-',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.nearBlack,
                              ),
                            ),
                            Text(
                              cls.level > 0 ? 'Tingkat ${cls.level}' : 'Tingkat Umum/Tidak Ditentukan',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil, size: 16, color: AppColors.darkTeal),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditClassDialog(context, cls),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, size: 16, color: AppColors.errorRed2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteClassConfirm(context, cls),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showAddRombelDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Tambah Rombel Baru',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkTeal),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Rombel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: A, B, 1, 2, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama rombel tidak boleh kosong'),
                              backgroundColor: AppColors.errorRed2,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('rombels').insert({
                            'name': name,
                          });

                          ref.invalidate(rombelsProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rombel berhasil ditambahkan'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambah rombel: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRombelDialog(BuildContext context, SchoolRombel rombel) {
    final nameCtrl = TextEditingController(text: rombel.name);
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Ubah Rombel',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkTeal),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nama Rombel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGray),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: A, B, 1, 2, dll.',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama rombel tidak boleh kosong'),
                              backgroundColor: AppColors.errorRed2,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('rombels').update({
                            'name': name,
                          }).eq('id', rombel.id);

                          ref.invalidate(rombelsProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rombel berhasil diperbarui'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui rombel: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteRombelConfirm(BuildContext context, SchoolRombel rombel) {
    bool localSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Hapus Rombel',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.errorRed2),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus rombel "${rombel.name}"?',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.nearBlack),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Peringatan: Seluruh siswa yang terdaftar di rombel ini akan terlepas dari rombelnya (menjadi tanpa rombel). Tindakan ini tidak dapat dibatalkan.',
                  style: TextStyle(fontSize: 11, color: AppColors.textGray),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: localSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: AppColors.textGray)),
              ),
              ElevatedButton(
                onPressed: localSaving
                    ? null
                    : () async {
                        setLocalState(() {
                          localSaving = true;
                        });

                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client.from('rombels').delete().eq('id', rombel.id);

                          ref.invalidate(rombelsProvider);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rombel berhasil dihapus'),
                                backgroundColor: AppColors.successGreen,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          setLocalState(() {
                            localSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menghapus rombel: $e'),
                                backgroundColor: AppColors.errorRed2,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed2,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: localSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CupertinoActivityIndicator(color: AppColors.white),
                      )
                    : const Text('Hapus'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRombelsManagementCard(BuildContext context, List<SchoolRombel> rombels) {
    return SettingSectionWidget(
      icon: CupertinoIcons.square_stack_3d_up,
      title: 'Daftar Rombel',
      horizontalPadding: 16,
      verticalPadding: 16,
      iconRadius: 16,
      iconBackgroundColor: AppColors.softOrange.withValues(alpha: 0.3),
      iconColor: AppColors.darkOrange,
      shadowBlurRadius: 15,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kelola daftar rombel aktif',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGray),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddRombelDialog(context),
              icon: const Icon(CupertinoIcons.plus, size: 14),
              label: const Text('Tambah Rombel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.darkOrange,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rombels.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Belum ada data rombel.',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.offWhite2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: rombels.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderLight,
                indent: 12,
                endIndent: 12,
              ),
              itemBuilder: (context, index) {
                final rom = rombels[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.darkOrange.withValues(alpha: 0.1),
                        child: const Icon(
                          CupertinoIcons.circle,
                          size: 10,
                          color: AppColors.darkOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rombel ${rom.name}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.nearBlack,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.pencil, size: 16, color: AppColors.darkTeal),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditRombelDialog(context, rom),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(CupertinoIcons.trash, size: 16, color: AppColors.errorRed2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteRombelConfirm(context, rom),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminSettingsProvider);
    final authState = ref.watch(authNotifierProvider);
    final isSuperAdmin = authState.profile?['role'] == AuthRoles.superAdmin;
    final rombelsAsync = ref.watch(rombelsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Setelan Sistem',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.darkTeal,
          ),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _loadSettings(settings);

          final classesAsync = ref.watch(classesProvider);

          final Widget classesManagementCard = classesAsync.when(
            data: (classesList) => _buildClassesManagementCard(context, classesList),
            loading: () => SettingSectionWidget(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'Daftar Kelas',
              iconBackgroundColor: AppColors.primaryLight,
              iconColor: AppColors.primary,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CupertinoActivityIndicator(color: AppColors.primary)),
                ),
              ],
            ),
            error: (err, stack) => SettingSectionWidget(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'Daftar Kelas',
              iconBackgroundColor: AppColors.primaryLight,
              iconColor: AppColors.primary,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text('Gagal memuat kelas: $err', style: const TextStyle(color: AppColors.errorRed2)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(classesProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final Widget rombelsManagementCard = rombelsAsync.when(
            data: (rombelsList) => _buildRombelsManagementCard(context, rombelsList),
            loading: () => SettingSectionWidget(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'Daftar Rombel',
              iconBackgroundColor: AppColors.softOrange.withValues(alpha: 0.3),
              iconColor: AppColors.darkOrange,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CupertinoActivityIndicator(color: AppColors.darkOrange)),
                ),
              ],
            ),
            error: (err, stack) => SettingSectionWidget(
              icon: CupertinoIcons.square_stack_3d_up,
              title: 'Daftar Rombel',
              iconBackgroundColor: AppColors.softOrange.withValues(alpha: 0.3),
              iconColor: AppColors.darkOrange,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Text('Gagal memuat rombel: $err', style: const TextStyle(color: AppColors.errorRed2)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(rombelsProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
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
          );

          final Widget systemAccessCard = SettingSectionWidget(
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
          );

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
                Responsive.isMobile(context)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          paymentApiCard,
                          const SizedBox(height: 16),
                          if (isSuperAdmin) ...[
                            classesManagementCard,
                            const SizedBox(height: 16),
                            rombelsManagementCard,
                            const SizedBox(height: 16),
                          ],
                          systemAccessCard,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                paymentApiCard,
                                if (isSuperAdmin) ...[
                                  const SizedBox(height: 16),
                                  classesManagementCard,
                                  const SizedBox(height: 16),
                                  rombelsManagementCard,
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: systemAccessCard),
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
                const SizedBox(height: 20),
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
