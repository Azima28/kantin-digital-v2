import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_dropdown_row.dart';
import 'package:kantin_digital/features/admin/widgets/admin_form_text_field.dart';
import 'package:kantin_digital/features/admin/widgets/admin_section_label.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

Future<void> showAddFinanceSheet(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'keu${_randomSuffix()}');
  String school = 'SMP Terpadu';
  String authLevel = 'L1';
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
                '${AppStrings.buttonAdd} Admin Keuangan Baru',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 20),
              AdminSectionLabel('INFORMASI PRIBADI'),
              const SizedBox(height: 8),
              AdminFormTextField(controller: nameCtrl, hintText: '${AppStrings.labelFullName} *'),
              const SizedBox(height: 12),
              AdminFormTextField(
                controller: emailCtrl,
                hintText: 'Email (Opsional)',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              AdminSectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              AdminFormTextField(controller: usernameCtrl, hintText: 'Username *'),
              const SizedBox(height: 12),
              AdminFormTextField(
                controller: passCtrl,
                hintText: 'Password Awal *',
                suffix: IconButton(
                  icon: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: AppColors.darkTeal,
                  ),
                  onPressed: () => setLocal(
                    () => passCtrl.text = 'keu${_randomSuffix()}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AdminSectionLabel('PENUGASAN SEKOLAH & WEWENANG'),
              const SizedBox(height: 8),
              AdminDropdownRow(
                label: 'Sekolah',
                value: school,
                items: ['SMP Terpadu'],
                onChanged: (v) => setLocal(() => school = v ?? school),
              ),
              const SizedBox(height: 12),
              AdminDropdownRow(
                label: 'Tingkat Wewenang',
                value: authLevel,
                items: ['L1', 'L2', 'L3'],
                onChanged: (v) => setLocal(() => authLevel = v ?? authLevel),
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
                                content: Text(
                                  'Nama dan username wajib diisi',
                                ),
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
                              'p_role': 'petugas_keuangan',
                              'p_username': usernameCtrl.text.trim(),
                              'p_is_active': true,
                            });

                            final officerId = newProfile['id'];
                            await client.from('finance_officers').update({
                              'assigned_school': school,
                              'authority_level': authLevel,
                            }).eq('id', officerId);

                            // Write to audit logs
                            try {
                              final authProfile = ref.read(authNotifierProvider).profile;
                              final actorName = authProfile?['full_name'] ?? 'Super Admin';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'TAMBAH_PENGGUNA',
                                'description': 'Super Admin menambahkan admin keuangan baru secara manual: ${nameCtrl.text.trim()}',
                                'target_id': officerId,
                                'new_value': {
                                  'full_name': nameCtrl.text.trim(),
                                  'username': usernameCtrl.text.trim(),
                                  'role': 'petugas_keuangan',
                                  'assigned_school': school,
                                  'authority_level': authLevel,
                                },
                              });
                            } catch (_) {}

                            ref.invalidate(adminUsersProvider);
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
                          'SIMPAN & AKTIFKAN PETUGAS KEUANGAN',
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

String _randomSuffix() {
  final now = DateTime.now();
  return '${now.second}${now.millisecond % 100}';
}
