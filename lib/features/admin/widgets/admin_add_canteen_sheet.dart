import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

/// Shows a bottom sheet to add a new canteen operator (petugas kantin).
void showAddCanteenSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'kantin${_randomSuffix()}');
  final canteenCtrl = TextEditingController();
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
                '${AppStrings.buttonAdd} Petugas Kantin Baru',
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
              _buildFormField(canteenCtrl, 'Nama Stan Kantin *'),
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
                              usernameCtrl.text.trim().isEmpty ||
                              canteenCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama, username, dan nama stan wajib diisi',
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

                            final newProfile = await client.rpc(
                                'create_user_account', params: {
                              'p_email': email,
                              'p_password': passCtrl.text.trim(),
                              'p_full_name': nameCtrl.text.trim(),
                              'p_role': 'petugas_kantin',
                              'p_phone_number': phoneCtrl.text.trim(),
                              'p_username': usernameCtrl.text.trim(),
                              'p_canteen_name': canteenCtrl.text.trim(),
                              'p_is_active': true,
                            });

                            // Write to audit logs
                            try {
                              final staffId = newProfile['id'];
                              final authProfile =
                                  ref.read(authNotifierProvider).profile;
                              final actorName =
                                  authProfile?['full_name'] ?? 'Super Admin';
                              final actorId = authProfile?['id'];

                              await client.from('audit_logs').insert({
                                'actor_id': actorId,
                                'actor_name': actorName,
                                'action_type': 'TAMBAH_PENGGUNA',
                                'description':
                                    'Super Admin menambahkan petugas kantin baru secara manual: ${nameCtrl.text.trim()}',
                                'target_id': staffId,
                                'new_value': {
                                  'full_name': nameCtrl.text.trim(),
                                  'username': usernameCtrl.text.trim(),
                                  'role': 'petugas_kantin',
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

String _randomSuffix() {
  final now = DateTime.now();
  return '${now.second}${now.millisecond % 100}';
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
}) =>
    TextField(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
