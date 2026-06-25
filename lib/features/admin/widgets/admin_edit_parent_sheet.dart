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

/// Bottom sheet for editing an existing parent user profile and their linked children relationships.
void showEditParentSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
  List<Map<String, dynamic>> children,
) {
  // Pre-load linked children's NISNs
  final List<String> initialNisns = children.map((c) {
    final studentInfo = c['students'] ?? {};
    final profileInfo = studentInfo['profiles'] ?? {};
    return (profileInfo['nisn'] ?? '').toString();
  }).where((n) => n.isNotEmpty).toList();

  final nameCtrl = TextEditingController(text: profile.fullName);
  final phoneCtrl = TextEditingController(text: profile.phoneNumber);
  final emailCtrl = TextEditingController(text: profile.email);
  final usernameCtrl = TextEditingController(text: profile.username);
  final nisnsCtrl = TextEditingController(text: initialNisns.join(', '));
  String relation = profile.relation ?? 'Wali';
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
                'Edit Profil Orang Tua / Wali',
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
              const SizedBox(height: 12),
              AdminDropdownRow(
                label: 'Hubungan Keluarga *',
                value: relation,
                items: const ['Ayah', 'Ibu', 'Wali'],
                onChanged: (v) => setLocal(() => relation = v ?? relation),
              ),
              const SizedBox(height: 20),
              AdminSectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              AdminFormTextField(controller: usernameCtrl, hintText: 'Username *'),
              const SizedBox(height: 20),
              AdminSectionLabel('HUBUNGAN ANAK (SISWA)'),
              const SizedBox(height: 8),
              AdminFormTextField(
                controller: nisnsCtrl,
                hintText: 'Daftar NISN Anak (Pisahkan dengan koma, misal: 20260012, 20260013)',
                inputType: TextInputType.text,
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
                          final String rawNisns = nisnsCtrl.text.trim();

                          if (name.isEmpty || phone.isEmpty || email.isEmpty || username.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequired)),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);

                            // Parse and validate children NISNs
                            final List<String> inputNisns = rawNisns
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            final List<String> validStudentIds = [];
                            if (inputNisns.isNotEmpty) {
                              final List<dynamic> studentsRes = await client
                                  .from('profiles')
                                  .select('id, nisn')
                                  .eq('role', 'student')
                                  .inFilter('nisn', inputNisns);

                              final Map<String, String> nisnToId = {
                                for (var item in studentsRes)
                                  (item['nisn'] ?? '').toString(): (item['id'] ?? '').toString()
                              };

                              final List<String> invalidNisns = inputNisns
                                  .where((n) => !nisnToId.containsKey(n))
                                  .toList();

                              if (invalidNisns.isNotEmpty) {
                                throw Exception('NISN Anak berikut tidak valid/tidak ditemukan: ${invalidNisns.join(", ")}');
                              }

                              for (var nisn in inputNisns) {
                                final id = nisnToId[nisn];
                                if (id != null) {
                                  validStudentIds.add(id);
                                }
                              }
                            }

                            // 1. Update profiles table for parent
                            await client.from('profiles').update({
                              'full_name': name,
                              'email': email,
                              'username': username,
                              'phone_number': phone,
                              'relation': relation,
                            }).eq('id', profile.id);

                            // 2. Update parent_students relation mapping
                            // Delete old mappings
                            await client.from('parent_students').delete().eq('parent_id', profile.id);
                            
                            // Insert new mappings
                            for (var childId in validStudentIds) {
                              await client.from('parent_students').insert({
                                'parent_id': profile.id,
                                'student_id': childId,
                              });
                            }

                            // 3. Write audit log
                            try {
                              final authProfile = ref.read(authNotifierProvider).profile;
                              final actorName = authProfile?['full_name'] ?? 'Super Admin';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'EDIT_PENGGUNA',
                                'description': 'Super Admin mengedit profil orang tua/wali: $name (Menghubungkan ke ${validStudentIds.length} anak)',
                                'target_id': profile.id,
                                'old_value': {
                                  'full_name': profile.fullName,
                                  'email': profile.email,
                                  'username': profile.username,
                                  'phone_number': profile.phoneNumber,
                                  'relation': profile.relation,
                                  'linked_nisns': initialNisns,
                                },
                                'new_value': {
                                  'full_name': name,
                                  'email': email,
                                  'username': username,
                                  'phone_number': phone,
                                  'relation': relation,
                                  'linked_nisns': inputNisns,
                                },
                              });
                            } catch (_) {}

                            // Invalidate details and user list providers
                            ref.invalidate(adminParentDetailProvider(profile.id));
                            ref.invalidate(adminUsersProvider);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil orang tua $name berhasil diperbarui'),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${e.toString().replaceAll("Exception: ", "")}'),
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
