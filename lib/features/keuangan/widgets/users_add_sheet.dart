import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
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
                '${AppStrings.buttonAdd} Orang Tua',
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
              _buildDropdownRow(
                context: context,
                label: 'Hubungan *',
                value: relation,
                items: ['Ayah', 'Ibu', 'Wali'],
                onChanged: (v) => setLocal(() => relation = v ?? relation),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                phoneCtrl,
                'Nomor HP / WhatsApp *',
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                emailCtrl,
                'Email *',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, 'AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(
                context,
                passCtrl,
                'Password Awal *',
                suffix: IconButton(
                  icon: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Nebula.teal,
                  ),
                  onPressed: () => setLocal(
                    () => passCtrl.text = 'ortu${_randomSuffix()}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, 'PENGHUBUNG DATA ANAK'),
              const SizedBox(height: 8),
              _buildFormField(
                context,
                childNisnCtrl,
                'NISN Anak yang akan dihubungkan *',
                inputType: TextInputType.number,
              ),
              const SizedBox(height: 24),
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
                          final name = nameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final password = passCtrl.text.trim();
                          final childNisn = childNisnCtrl.text.trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              phone.isEmpty ||
                              password.isEmpty ||
                              childNisn.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.adminFieldRequired),
                              ),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);

                            final response = await apiClient.post(
                              '/admin/users',
                              body: {
                                'email': email,
                                'password': password,
                                'full_name': name,
                                'role': 'parent',
                                'phone_number': phone,
                                'relation': relation,
                                'student_nisn': childNisn,
                              },
                            );

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal mendaftarkan orang tua');
                            }

                            ref.invalidate(keuanganParentsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Orang tua berhasil didaftarkan & dihubungkan.'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Gagal mendaftarkan orang tua: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'DAFTARKAN ORANG TUA',
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

void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'staff${_randomSuffix()}');
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
                '${AppStrings.buttonAdd} Petugas Kantin',
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
              _buildFormField(
                context,
                phoneCtrl,
                'Nomor HP *',
                inputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                emailCtrl,
                'Email (Opsional)',
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, 'AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(context, usernameCtrl, 'Username *'),
              const SizedBox(height: 12),
              _buildFormField(
                context,
                passCtrl,
                'Password Awal *',
                suffix: IconButton(
                  icon: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Nebula.teal,
                  ),
                  onPressed: () => setLocal(
                    () => passCtrl.text = 'staff${_randomSuffix()}',
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final username = usernameCtrl.text.trim();
                          final password = passCtrl.text.trim();

                          if (name.isEmpty ||
                              phone.isEmpty ||
                              username.isEmpty ||
                              password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppStrings.adminFieldRequired),
                              ),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);

                            final email = emailCtrl.text.trim().isNotEmpty
                                ? emailCtrl.text.trim()
                                : 'staff_${username}_${_randomSuffix()}@kantin.sch.id';

                            final response = await apiClient.post(
                              '/admin/users',
                              body: {
                                'email': email,
                                'password': password,
                                'full_name': name,
                                'role': 'petugas_kantin',
                                'phone_number': phone,
                                'username': username,
                              },
                            );

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal membuat profil petugas.');
                            }

                            ref.invalidate(keuanganStaffProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Petugas baru berhasil terdaftar.'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mendaftarkan: $e'),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'DAFTARKAN PETUGAS KANTIN',
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
  Widget? suffix,
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
        suffixIcon: suffix,
        filled: true,
        fillColor: context.surfaceBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

Widget _buildDropdownRow({
  required BuildContext context,
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                ),
                dropdownColor: context.cardBg,
                onChanged: onChanged,
                items: items
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: TextStyle(color: context.textPrimary),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
