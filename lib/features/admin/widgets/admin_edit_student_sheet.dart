import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
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
                'Edit Profil Siswa',
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
                items: availableClasses,
                onChanged: (v) => setLocal(() => selectedClass = v ?? selectedClass),
              ),
              const SizedBox(height: 12),
              _buildFormField(context, parentPhoneCtrl, 'Nomor HP Orang Tua (WhatsApp)', inputType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildFormField(context, emailCtrl, 'Email *', inputType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _sectionLabel(context, 'AKUN SISTEM'),
              const SizedBox(height: 8),
              _buildFormField(context, usernameCtrl, 'Username *'),
              const SizedBox(height: 20),
              _sectionLabel(context, 'PENGATURAN SALDO & KARTU'),
              const SizedBox(height: 8),
              _buildFormField(context, limitCtrl, 'Batas Belanja Harian (0 = Tanpa Batas)', inputType: TextInputType.number),
              const SizedBox(height: 12),
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
                          final email = emailCtrl.text.trim();
                          final username = usernameCtrl.text.trim();
                          final phone = parentPhoneCtrl.text.trim();
                          final limitText = limitCtrl.text.trim();
                          final rfid = rfidCtrl.text.trim();

                          if (name.isEmpty || nisn.isEmpty || email.isEmpty || username.isEmpty || rfid.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.adminFieldRequiredRfid)),
                            );
                            return;
                          }

                          setLocal(() => isSaving = true);
                          try {
                            final client = ref.read(supabaseClientProvider);
                            final int parsedLimit = int.tryParse(limitText) ?? 0;
                            final rfidVal = rfid.isNotEmpty ? rfid : null;

                            // 1. Update profiles table
                            await client.from('profiles').update({
                              'full_name': name,
                              'email': email,
                              'username': username,
                              'phone_number': phone.isEmpty ? null : phone,
                            }).eq('id', profile.id);

                            // 2. Update students table
                            await client.from('students').update({
                              'nisn': nisn,
                              'class': selectedClass,
                              'daily_limit': parsedLimit,
                              'rfid_uid': rfidVal,
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
                                  'username': profile.username,
                                  'phone_number': profile.phoneNumber,
                                  'nisn': profile.nisn,
                                  'class': student.class_,
                                  'daily_limit': student.dailyLimit,
                                  'rfid_uid': student.rfidUid,
                                },
                                'new_value': {
                                  'full_name': name,
                                  'email': email,
                                  'username': username,
                                  'phone_number': phone,
                                  'nisn': nisn,
                                  'class': selectedClass,
                                  'daily_limit': parsedLimit,
                                  'rfid_uid': rfidVal,
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

Widget _buildDropdownRow({
  required BuildContext context,
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
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: context.textSecondary, letterSpacing: 1.2),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerCol),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: Nebula.teal),
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
            dropdownColor: context.cardBg,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}
