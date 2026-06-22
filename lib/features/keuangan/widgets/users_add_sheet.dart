import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';

/// Shows add bottom sheet based on the tab index:
/// 0 → navigate to /finance/students
/// 1 → add parent bottom sheet
/// 2 → add staff bottom sheet
void showAddUserBottomSheet(BuildContext context, WidgetRef ref, int tabIndex) {
  if (tabIndex == 0) {
    context.go('/finance/students');
  } else if (tabIndex == 1) {
    _showAddParentSheet(context, ref);
  } else {
    _showAddStaffSheet(context, ref);
  }
}

String _randomSuffix() {
  final now = DateTime.now();
  return '${now.second}${now.millisecond % 100}';
}

void _showAddParentSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'ortu${_randomSuffix()}');
  final childNisnCtrl = TextEditingController();
  String relation = 'Ayah';
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppStrings.buttonAdd} Orang Tua',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('INFORMASI PRIBADI'),
              const SizedBox(height: 8),
              _buildFormField(nameCtrl, '${AppStrings.labelFullName} *'),
              const SizedBox(height: 12),
              _buildDropdownRow(
                label: 'Hubungan *',
                value: relation,
                items: ['Ayah', 'Ibu', 'Wali'],
                onChanged: (v) => setLocal(() => relation = v ?? relation),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                phoneCtrl,
                'Nomor HP / WhatsApp *',
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                emailCtrl,
                'Email *',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _sectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(
                passCtrl,
                'Password Awal *',
                suffix: IconButton(
                  icon: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: AppColors.darkTeal,
                  ),
                  onPressed: () => setLocal(
                    () => passCtrl.text = 'ortu${_randomSuffix()}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('HUBUNGKAN KE SISWA (NISN)'),
              const SizedBox(height: 8),
              _buildFormField(
                childNisnCtrl,
                'NISN Anak (opsional)',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama dan email wajib diisi'),
                              ),
                            );
                            return;
                          }
                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);
                            final newProfile = await client.rpc('create_user_account', params: {
                              'p_email': emailCtrl.text.trim(),
                              'p_password': passCtrl.text.trim(),
                              'p_full_name': nameCtrl.text.trim(),
                              'p_role': 'parent',
                              'p_phone_number': phoneCtrl.text.trim(),
                              'p_relation': relation,
                              'p_is_active': true,
                            });

                            // Write to audit logs
                            try {
                              final parentId = newProfile['id'];
                              final authProfile = ref.read(authNotifierProvider).profile;
                              final actorName = authProfile?['full_name'] ?? 'Admin Keuangan';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'TAMBAH_PENGGUNA',
                                'description': 'Menambahkan orang tua baru secara manual: ${nameCtrl.text.trim()}',
                                'target_id': parentId,
                                'new_value': {
                                  'full_name': nameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'phone_number': phoneCtrl.text.trim(),
                                  'role': 'parent',
                                },
                              });
                            } catch (_) {}

                            ref.invalidate(keuanganParentsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${nameCtrl.text.trim()} berhasil didaftarkan sebagai orang tua',
                                  ),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${AppStrings.labelFailed} menyimpan'),
                                  backgroundColor: AppColors.errorRed2,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: AppColors.white)
                      : Text(
                          'SIMPAN & DAFTARKAN ORTU',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'kantin${_randomSuffix()}');
  String? selectedCanteen;
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppStrings.buttonAdd} Petugas Kantin',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('INFORMASI PRIBADI'),
              const SizedBox(height: 8),
              _buildFormField(nameCtrl, '${AppStrings.labelFullName} *'),
              const SizedBox(height: 12),
              _buildFormField(
                phoneCtrl,
                'Nomor HP *',
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                emailCtrl,
                'Email (Opsional)',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _sectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(usernameCtrl, 'Username *'),
              const SizedBox(height: 12),
              _buildFormField(
                passCtrl,
                'Password Awal *',
                suffix: IconButton(
                  icon: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: AppColors.darkTeal,
                  ),
                  onPressed: () => setLocal(
                    () => passCtrl.text = 'kantin${_randomSuffix()}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('PENUGASAN STAN KANTIN'),
              const SizedBox(height: 8),
              _buildDropdownRow(
                label: 'Stan Kantin',
                value: selectedCanteen ?? 'Belum Dipilih',
                items: [
                  'Belum Dipilih',
                  'Warung Bude Sari',
                  'Koperasi Minuman',
                  'Stan Bakso Pak Harto',
                  'Stan Nasi Goreng',
                ],
                onChanged: (v) => setLocal(() => selectedCanteen = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty ||
                              usernameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama dan username wajib diisi'),
                              ),
                            );
                            return;
                          }
                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);
                            final email = emailCtrl.text.trim().isEmpty
                                ? '${usernameCtrl.text.trim()}@sekolah.sch.id'
                                : emailCtrl.text.trim();

                            final newProfile = await client.rpc('create_user_account', params: {
                              'p_email': email,
                              'p_password': passCtrl.text.trim(),
                              'p_full_name': nameCtrl.text.trim(),
                              'p_role': 'petugas_kantin',
                              'p_phone_number': phoneCtrl.text.trim(),
                              'p_username': usernameCtrl.text.trim(),
                              'p_canteen_name': selectedCanteen != 'Belum Dipilih' ? selectedCanteen : 'Stan Kantin',
                              'p_is_active': true,
                            });

                            // Write to audit logs
                            try {
                              final staffId = newProfile['id'];
                              final authProfile = ref.read(authNotifierProvider).profile;
                              final actorName = authProfile?['full_name'] ?? 'Admin Keuangan';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'TAMBAH_PENGGUNA',
                                'description': 'Menambahkan petugas kantin baru secara manual: ${nameCtrl.text.trim()}',
                                'target_id': staffId,
                                'new_value': {
                                  'full_name': nameCtrl.text.trim(),
                                  'username': usernameCtrl.text.trim(),
                                  'role': 'petugas_kantin',
                                },
                              });
                            } catch (_) {}

                            ref.invalidate(keuanganStaffProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${nameCtrl.text.trim()} berhasil ditambahkan',
                                  ),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${AppStrings.labelFailed} menyimpan'),
                                  backgroundColor: AppColors.errorRed2,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: AppColors.white)
                      : Text(
                          'SIMPAN & AKTIFKAN PETUGAS',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _sectionLabel(String label) => Text(
  label,
  style: GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedGray,
    letterSpacing: 1.2,
  ),
);

Widget _buildFormField(
  TextEditingController ctrl,
  String hint, {
  TextInputType inputType = TextInputType.text,
  Widget? suffix,
}) => TextField(
  controller: ctrl,
  keyboardType: inputType,
  style: GoogleFonts.inter(fontSize: 14),
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      color: AppColors.mutedGray,
      fontSize: 14,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.offWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderGray),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.borderGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.darkTeal, width: 1.5),
    ),
  ),
);

Widget _buildDropdownRow({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14),
  decoration: BoxDecoration(
    color: AppColors.offWhite,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.borderGray),
  ),
  child: Row(
    children: [
      Text(
        '$label: ',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.mutedGray,
        ),
      ),
      Expanded(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: GoogleFonts.inter(
              color: AppColors.nearBlack,
              fontSize: 14,
            ),
            onChanged: onChanged,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
        ),
      ),
    ],
  ),
);
