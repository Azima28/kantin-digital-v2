import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/admin/widgets/admin_dropdown_row.dart';
import 'package:kantin_digital/features/admin/widgets/admin_form_text_field.dart';
import 'package:kantin_digital/features/admin/widgets/admin_section_label.dart';

Future<void> showAddFinanceSheet(BuildContext context, WidgetRef ref) async {
  final dynamicSchool = ref.read(academicStructureProvider).valueOrNull?.schoolName ?? 'Sekolah Digital';
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'keu${_randomSuffix()}');
  String school = dynamicSchool;
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
        decoration: BoxDecoration(
          color: context.cardBg,
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
                    color: context.dividerCol,
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
                  color: context.textPrimary,
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
              AdminSectionLabel('USERNAME & KATA SANDI'),
              const SizedBox(height: 8),
              AdminFormTextField(controller: usernameCtrl, hintText: 'Username *'),
              const SizedBox(height: 12),
              AdminFormTextField(
                controller: passCtrl,
                hintText: 'Password Awal *',
                suffix: IconButton(
                  icon: Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Nebula.teal,
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
                items: [dynamicSchool],
                onChanged: (v) => setLocal(() => school = v ?? school),
              ),
              const SizedBox(height: 12),
              AdminDropdownRow(
                label: 'Tingkat Wewenang',
                value: authLevel,
                items: ['L1', 'L2', 'L3'],
                onChanged: (v) => setLocal(() => authLevel = v ?? authLevel),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
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
                            final apiClient = ref.read(apiClientProvider);
                            final email = emailCtrl.text.trim().isNotEmpty
                                ? emailCtrl.text.trim()
                                : '${usernameCtrl.text.trim()}@sekolah.sch.id';

                            final response = await apiClient.post('/admin/finance-officers', body: {
                              'email': email,
                              'password': passCtrl.text.trim(),
                              'full_name': nameCtrl.text.trim(),
                              'username': usernameCtrl.text.trim(),
                              'assigned_school': school,
                              'authority_level': authLevel,
                            });

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal menambahkan admin keuangan');
                            }

                            ref.invalidate(adminUsersProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${nameCtrl.text.trim()} berhasil ditambahkan',
                                  ),
                                  backgroundColor: Nebula.teal,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${AppStrings.labelFailed} menyimpan: $e'),
                                  backgroundColor: Nebula.rose,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? CupertinoActivityIndicator(color: context.cardBg)
                      : Text(
                          'SIMPAN & AKTIFKAN PETUGAS KEUANGAN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: context.cardBg,
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