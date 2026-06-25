import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';

/// Bottom sheet for editing an existing student user's profile and data.
void showEditStudentSheet(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
  Student student,
) {
  final nameCtrl = TextEditingController(text: profile.fullName);
  final nisnCtrl = TextEditingController(text: profile.nisn);
  final emailCtrl = TextEditingController(text: profile.email);
  final usernameCtrl = TextEditingController(text: profile.username);
  final parentPhoneCtrl = TextEditingController(text: profile.phoneNumber);
  final limitCtrl = TextEditingController(text: student.dailyLimit?.toStringAsFixed(0) ?? '0');
  final rfidCtrl = TextEditingController(text: student.rfidUid);
  String selectedClass = student.class_ ?? '7-A';
  bool isSaving = false;

  final List<String> availableClasses = [
    '7-A', '7-B', '7-C',
    '8-A', '8-B', '8-C',
    '9-A', '9-B', '9-C'
  ];

  if (!availableClasses.contains(selectedClass)) {
    availableClasses.add(selectedClass);
  }

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
                'Edit Profil Siswa',
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
                items: availableClasses,
                onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
              ),
              const SizedBox(height: 12),
              _buildFormField(parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField(emailCtrl, 'Email *', inputType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionLabel('AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(usernameCtrl, 'Username *'),
              const SizedBox(height: 20),
              _sectionLabel('PENGATURAN KARTU & LIMIT'),
              const SizedBox(height: 8),
              _buildFormField(rfidCtrl, 'RFID UID / Nomor Kartu (Kosongkan jika tidak ada)'),
              const SizedBox(height: 12),
              _buildFormField(limitCtrl, 'Batas Jajan Harian (0 = Tanpa Batas) *', inputType: TextInputType.number),
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
                          final email = emailCtrl.text.trim();
                          final username = usernameCtrl.text.trim();
                          final rfid = rfidCtrl.text.trim();
                          final limitVal = double.tryParse(limitCtrl.text.trim()) ?? 0;

                          if (name.isEmpty || nisn.isEmpty || email.isEmpty || username.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequired)),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);
                            final parentPhone = parentPhoneCtrl.text.trim().isNotEmpty
                                ? parentPhoneCtrl.text.trim()
                                : null;
                            final rfidVal = rfid.isNotEmpty ? rfid : null;

                            // 1. Update profiles table
                            await client.from('profiles').update({
                              'full_name': name,
                              'email': email,
                              'username': username,
                              'nisn': nisn,
                              'phone_number': parentPhone,
                            }).eq('id', profile.id);

                            // 2. Update students table
                            await client.from('students').update({
                              'class': selectedClass,
                              'rfid_uid': rfidVal,
                              'daily_limit': limitVal,
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
                                'description': 'Super Admin mengedit profil siswa: $name (NISN: $nisn)',
                                'target_id': profile.id,
                                'old_value': {
                                  'full_name': profile.fullName,
                                  'email': profile.email,
                                  'nisn': profile.nisn,
                                  'class': student.class_,
                                  'rfid_uid': student.rfidUid,
                                  'daily_limit': student.dailyLimit,
                                  'phone_number': profile.phoneNumber,
                                },
                                'new_value': {
                                  'full_name': name,
                                  'email': email,
                                  'nisn': nisn,
                                  'class': selectedClass,
                                  'rfid_uid': rfidVal,
                                  'daily_limit': limitVal,
                                  'phone_number': parentPhone,
                                },
                              });
                            } catch (_) {}

                            // Invalidate details and user list providers
                            ref.invalidate(adminStudentDetailProvider(profile.id));
                            ref.invalidate(adminUsersProvider);

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil siswa $name berhasil diperbarui'),
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
