import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Bottom sheet for editing an existing merchant (canteen operator) profile and data.
void showEditMerchantSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
  CanteenOperator operatorInfo,
) {
  final nameCtrl = TextEditingController(text: profile.fullName);
  final phoneCtrl = TextEditingController(text: profile.phoneNumber);
  final emailCtrl = TextEditingController(text: profile.email);
  final usernameCtrl = TextEditingController(text: profile.username);
  final canteenCtrl = TextEditingController(text: operatorInfo.canteenName);
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                'Edit Profil Pedagang',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, 'INFORMASI PRIBADI'),
              const SizedBox(height: 8),
              _buildFormField(context, nameCtrl, '${AppStrings.labelFullName} *'),
              const SizedBox(height: 12),
              _buildFormField(context, phoneCtrl, 'Nomor HP *', inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField(context, emailCtrl, 'Email *', inputType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionLabel(context, 'AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(context, usernameCtrl, 'Username *'),
              const SizedBox(height: 20),
              _sectionLabel(context, 'INFORMASI STAN KANTIN'),
              const SizedBox(height: 8),
              _buildFormField(context, canteenCtrl, 'Nama Stan Kantin *'),
              const SizedBox(height: 24),
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
                          final canteen = canteenCtrl.text.trim();

                          if (name.isEmpty || phone.isEmpty || email.isEmpty || username.isEmpty || canteen.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequired)),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);

                            final response = await apiClient.put(
                              '/admin/canteen-operators/${profile.id}',
                              body: {
                                'full_name': name,
                                'email': email,
                                'username': username,
                                'phone_number': phone,
                                'canteen_name': canteen,
                              },
                            );

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal memperbarui profil pedagang');
                            }

                            // Invalidate details and user list providers
                            ref.invalidate(adminMerchantDetailProvider(profile.id));
                            ref.invalidate(adminUsersProvider);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil pedagang $name berhasil diperbarui'),
                                  backgroundColor: Nebula.teal,
                                ),
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${AppStrings.labelFailedSave}: ${e.toString()}'),
                                  backgroundColor: Nebula.rose,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'SIMPAN PERUBAHAN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

Widget _sectionLabel(BuildContext context, String label) => Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
        letterSpacing: 1.2,
      ),
    );

Widget _buildFormField(
  BuildContext context,
  TextEditingController ctrl,
  String hint, {
  TextInputType inputType = TextInputType.text,
}) =>
    TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: context.textSecondary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: context.surfaceBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
        ),
      ),
    );

