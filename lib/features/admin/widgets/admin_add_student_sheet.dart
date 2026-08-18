import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/widgets/app_toast.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

/// Bottom sheet for adding a new student user.
void showAddStudentSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final nisnCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final parentPhoneCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'siswa${_randomSuffix()}');
  final rfidCtrl = TextEditingController();
  String selectedClass = '7-A';
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
                '${AppStrings.buttonAdd} Siswa Baru',
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
              _buildFormField(nisnCtrl, 'NISN *', inputType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDropdownRow(
                label: 'Kelas *',
                value: selectedClass,
                items: ['7-A', '7-B', '7-C', '8-A', '8-B', '8-C', '9-A', '9-B', '9-C'],
                onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
              ),
              const SizedBox(height: 12),
              _buildFormField(parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField(emailCtrl, 'Email (Opsional, otomatis jika kosong)', inputType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionLabel('USERNAME & KATA SANDI'),
              const SizedBox(height: 8),
              _buildFormField(usernameCtrl, 'Username (Opsional, otomatis jika kosong)'),
              const SizedBox(height: 12),
              _buildFormField(passCtrl, 'Password Awal *',
                  suffix: IconButton(
                    icon: Icon(CupertinoIcons.refresh, size: 18, color: AppColors.darkTeal),
                    onPressed: () => setLocal(() => passCtrl.text = 'siswa${_randomSuffix()}'),
                  )),
              const SizedBox(height: 20),
              _sectionLabel('KARTU RFID / NFC'),
              const SizedBox(height: 8),
              _buildFormField(rfidCtrl, 'RFID UID / Nomor Kartu (Opsional)'),
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
                          final nisn = nisnCtrl.text.trim();
                          final password = passCtrl.text.trim();
                          final rfid = rfidCtrl.text.trim();
                          if (name.isEmpty || nisn.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequired)),
                            );
                            return;
                          }
                          setLocal(() => isSaving = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);

                            final email = emailCtrl.text.trim().isNotEmpty
                                ? emailCtrl.text.trim()
                                : '$nisn@sekolah.sch.id';
                            final username = usernameCtrl.text.trim().isNotEmpty
                                ? usernameCtrl.text.trim()
                                : 'student_$nisn';
                            final parentPhone = parentPhoneCtrl.text.trim().isNotEmpty
                                ? parentPhoneCtrl.text.trim()
                                : null;
                            final rfidVal = rfid.isNotEmpty ? rfid : null;

                            final response = await apiClient.post('/admin/students', body: {
                              'email': email,
                              'password': password,
                              'full_name': name,
                              'phone_number': parentPhone,
                              'username': username,
                              'nisn': nisn,
                              'class': selectedClass,
                              'rfid_uid': rfidVal,
                            });

                            if (!response.success) {
                              throw Exception(response.message ?? 'Gagal membuat profil siswa.');
                            }

                            ref.invalidate(adminUsersProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              AppToast.showSuccess(
                                context,
                                title: 'Berhasil Disimpan',
                                message: '$name telah aman didaftarkan sebagai siswa.',
                              );
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppStrings.labelFailedSave),
                                  backgroundColor: AppColors.errorRed2,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: AppColors.white)
                      : Text(
                          'SIMPAN & DAFTARKAN SISWA',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );

Widget _buildDropdownRow({
  required String label,
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mutedGray, letterSpacing: 1.2),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: Icon(CupertinoIcons.chevron_down, size: 14, color: AppColors.darkTeal),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.nearBlack),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: GoogleFonts.inter(fontSize: 13)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}
