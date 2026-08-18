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
                'Edit Profil Orang Tua / Wali',
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
              AdminSectionLabel('USERNAME'),
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
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Nebula.teal,
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
                            final apiClient = ref.read(apiClientProvider);

                            final List<String> inputNisns = rawNisns
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();

                            final response = await apiClient.put(
                              '/admin/parents/${profile.id}',
                              body: {
                                'full_name': name,
                                'email': email,
                                'username': username,
                                'phone_number': phone,
                                'relation': relation,
                                'linked_nisns': inputNisns,
                              },
                            );

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal memperbarui profil orang tua');
                            }

                            // Invalidate details and user list providers
                            ref.invalidate(adminParentDetailProvider(profile.id));
                            ref.invalidate(adminUsersProvider);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil orang tua $name berhasil diperbarui'),
                                  backgroundColor: Nebula.teal,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll("Exception: ", "")),
                                  backgroundColor: Nebula.rose,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? CupertinoActivityIndicator(color: context.cardBg)
                      : Text(
                          'SIMPAN PERUBAHAN',
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