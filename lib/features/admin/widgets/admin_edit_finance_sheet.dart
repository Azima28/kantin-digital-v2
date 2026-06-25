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
import 'package:kantin_digital/core/models/models.dart';

/// Bottom sheet for editing an existing finance officer profile and data.
void showEditFinanceSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
  FinanceOfficer officer,
) {
  final nameCtrl = TextEditingController(text: profile.fullName);
  final phoneCtrl = TextEditingController(text: profile.phoneNumber);
  final emailCtrl = TextEditingController(text: profile.email);
  final usernameCtrl = TextEditingController(text: profile.username);
  String school = officer.assignedSchool;
  String authLevel = officer.authorityLevel;
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
                'Edit Profil Admin Keuangan',
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
                controller: phoneCtrl,
                hintText: 'Nomor HP *',
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AdminFormTextField(
                controller: emailCtrl,
                hintText: 'Email *',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              AdminSectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              AdminFormTextField(controller: usernameCtrl, hintText: 'Username *'),
              const SizedBox(height: 20),
              AdminSectionLabel('PENUGASAN SEKOLAH & WEWENANG'),
              const SizedBox(height: 8),
              AdminDropdownRow(
                label: 'Sekolah',
                value: school,
                items: const ['SMP Terpadu'],
                onChanged: (v) => setLocal(() => school = v ?? school),
              ),
              const SizedBox(height: 12),
              AdminDropdownRow(
                label: 'Tingkat Otoritas',
                value: authLevel,
                items: const ['L1', 'L2', 'L3'],
                onChanged: (v) => setLocal(() => authLevel = v ?? authLevel),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final username = usernameCtrl.text.trim();

                          if (name.isEmpty || phone.isEmpty || email.isEmpty || username.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequired)),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);

                            // 1. Update profiles table
                            await client.from('profiles').update({
                              'full_name': name,
                              'email': email,
                              'username': username,
                              'phone_number': phone,
                            }).eq('id', profile.id);

                            // 2. Update finance_officers table
                            await client.from('finance_officers').update({
                              'assigned_school': school,
                              'authority_level': authLevel,
                            }).eq('id', profile.id);

                            // 3. Write audit log
                            try {
                              final authProfile = ref.read(authNotifierProvider).profile;
                              final actorName = authProfile?['full_name'] ?? 'Super Admin';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'EDIT_PENGGUNA',
                                'description': 'Super Admin mengedit profil admin keuangan: $name',
                                'target_id': profile.id,
                                'old_value': {
                                  'full_name': profile.fullName,
                                  'email': profile.email,
                                  'username': profile.username,
                                  'phone_number': profile.phoneNumber,
                                  'assigned_school': officer.assignedSchool,
                                  'authority_level': officer.authorityLevel,
                                },
                                'new_value': {
                                  'full_name': name,
                                  'email': email,
                                  'username': username,
                                  'phone_number': phone,
                                  'assigned_school': school,
                                  'authority_level': authLevel,
                                },
                              });
                            } catch (_) {}

                            // Invalidate details and user list providers
                            ref.invalidate(adminFinanceDetailProvider(profile.id));
                            ref.invalidate(adminUsersProvider);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil admin keuangan $name berhasil diperbarui'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${AppStrings.labelFailedSave}: ${e.toString()}'),
                                  backgroundColor: AppColors.errorRed2,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: AppColors.white)
                      : Text(
                          'SIMPAN PERUBAHAN',
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
