import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';

/// Shows a modal bottom sheet for adding a new student.
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
            right: 20),
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
                '${AppStrings.buttonAdd} Siswa Baru',
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
              _buildFormField(context, nisnCtrl, 'NISN *', inputType: TextInputType.number),
              const SizedBox(height: 12),
              _buildDropdownRow(
                context: context,
                label: 'Kelas *',
                value: selectedClass,
                items: ['7-A', '7-B', '7-C', '8-A', '8-B', '8-C', '9-A', '9-B', '9-C'],
                onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
              ),
              const SizedBox(height: 12),
              _buildFormField(context, parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField(context, emailCtrl, 'Email (Opsional, otomatis jika kosong)', inputType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionLabel(context, 'AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(context, usernameCtrl, 'Username (Opsional, otomatis jika kosong)'),
              const SizedBox(height: 12),
              _buildFormField(context, passCtrl, 'Password Awal *',
                  suffix: IconButton(
                    icon: const Icon(CupertinoIcons.refresh, size: 18, color: Nebula.teal),
                    onPressed: () => setLocal(() => passCtrl.text = 'siswa${_randomSuffix()}'),
                  )),
              const SizedBox(height: 20),
              _sectionLabel(context, 'KARTU RFID / NFC'),
              const SizedBox(height: 8),
              _buildFormField(context, rfidCtrl, 'RFID UID / Nomor Kartu *'),
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
                          final nisn = nisnCtrl.text.trim();
                          final password = passCtrl.text.trim();
                          final rfid = rfidCtrl.text.trim();
                          if (name.isEmpty || nisn.isEmpty || password.isEmpty || rfid.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequiredRfid)),
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

                            ref.invalidate(keuanganStudentsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Siswa baru berhasil terdaftar & aktif.')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setLocal(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Pendaftaran gagal: $e')),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'SIMPAN & DAFTARKAN SISWA',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
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
        hintStyle: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.surfaceBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.dividerCol)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.dividerCol)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Nebula.teal, width: 1.5)),
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
          Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary)),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
                dropdownColor: context.cardBg,
                onChanged: onChanged,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: context.textPrimary)))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
