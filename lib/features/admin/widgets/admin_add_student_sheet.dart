import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Bottom sheet for adding a new student user.
void showAddStudentSheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final nisnCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final parentPhoneCtrl = TextEditingController();
  final passCtrl = TextEditingController(text: 'siswa${_randomSuffix()}');
  final rfidCtrl = TextEditingController();
  String selectedClass = '7';
  String selectedRombel = 'A';
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Consumer(
        builder: (ctx, ref, child) {
          final classesAsync = ref.watch(classesProvider);
          final rombelsAsync = ref.watch(rombelsProvider);

          if (classesAsync.isLoading || rombelsAsync.isLoading) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 12),
              ),
            );
          }

          if (classesAsync.hasError || rombelsAsync.hasError) {
            final errorMsg = classesAsync.error ?? rombelsAsync.error;
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Text('Gagal memuat data kelas/rombel: $errorMsg'),
              ),
            );
          }

          final classesList = classesAsync.value ?? [];
          final rombelsList = rombelsAsync.value ?? [];

          final classNames = classesList.map((c) => c.name).toList();
          if (classNames.isEmpty) {
            classNames.add('Belum Diisi');
          }
          if (!classNames.contains(selectedClass)) {
            selectedClass = classNames.contains('7') ? '7' : classNames.first;
          }

          final rombelNames = rombelsList.map((r) => r.name).toList();
          if (rombelNames.isEmpty) {
            rombelNames.add('-');
          }
          if (!rombelNames.contains(selectedRombel)) {
            selectedRombel = rombelNames.contains('A') ? 'A' : rombelNames.first;
          }

          return Container(
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownRow(
                          label: 'Kelas *',
                          value: selectedClass,
                          items: classNames,
                          onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownRow(
                          label: 'Rombel *',
                          value: selectedRombel,
                          items: rombelNames,
                          onChanged: (v) => setLocal(() => selectedRombel = v ?? selectedRombel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildFormField(emailCtrl, 'Email (Opsional, otomatis jika kosong)', inputType: TextInputType.emailAddress),
                  const SizedBox(height: 20),
                  _sectionLabel('AKUN SISTEM'),
                  const SizedBox(height: 8),
                  _buildFormField(usernameCtrl, 'Username (Opsional, otomatis jika kosong)'),
                  const SizedBox(height: 12),
                  _buildFormField(passCtrl, 'Password Awal *',
                      suffix: IconButton(
                        icon: const Icon(CupertinoIcons.refresh, size: 18, color: AppColors.darkTeal),
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
                                final client = ref.read(supabaseClientProvider);

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
                                final combinedClass = selectedRombel != '-' ? '$selectedClass-$selectedRombel' : selectedClass;

                                final newProfile = await client.rpc('create_user_account', params: {
                                  'p_email': email,
                                  'p_password': password,
                                  'p_full_name': name,
                                  'p_role': 'student',
                                  'p_phone_number': parentPhone,
                                  'p_username': username,
                                  'p_nisn': nisn,
                                  'p_class': combinedClass,
                                  'p_is_active': true,
                                  'p_rfid_uid': rfidVal,
                                  'p_parent_phone': parentPhone,
                                });

                                final String studentId = newProfile['id'];

                                try {
                                  final authProfile = ref.read(authNotifierProvider).profile;
                                  final actorName = authProfile?['full_name'] ?? 'Super Admin';
                                  final actorId = authProfile?['id'];

                                  await client.from('audit_logs').insert({
                                    'actor_id': actorId,
                                    'actor_name': actorName,
                                    'action_type': 'TAMBAH_PENGGUNA',
                                    'description': 'Super Admin menambahkan siswa baru secara manual: $name (NISN: $nisn)',
                                    'target_id': studentId,
                                    'new_value': {
                                      'full_name': name,
                                      'email': email,
                                      'nisn': nisn,
                                      'class': combinedClass,
                                      'rfid_uid': rfidVal,
                                    },
                                  });
                                } catch (_) {}

                                ref.invalidate(adminUsersProvider);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$name berhasil didaftarkan sebagai siswa'),
                                      backgroundColor: AppColors.successGreen,
                                    ),
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
              );
            },
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
            icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: AppColors.darkTeal),
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
