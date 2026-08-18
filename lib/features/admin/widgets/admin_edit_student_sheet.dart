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

/// Bottom sheet for editing an existing student user's profile and data.
/// Updated with a 2-column grid layout matching the requested design.
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
  final limitCtrl = TextEditingController(
    text: student.dailyLimit?.toStringAsFixed(0) ?? '0',
  );
  final rfidCtrl = TextEditingController(text: student.rfidUid);
  String selectedClass = student.class_ ?? '7-A';
  bool isSaving = false;

  final academic = ref.read(academicStructureProvider).asData?.value;
  final List<String> availableClasses = (academic != null && academic.rombels.isNotEmpty)
      ? List<String>.from(academic.rombels)
      : [
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
      builder: (ctx, setLocal) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
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
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerCol,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Profil Siswa',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Nebula.teal,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. INFORMASI PRIBADI
                _sectionLabel(context, 'INFORMASI PRIBADI'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildLabeledFormField(
                        context,
                        label: 'Nama Lengkap',
                        controller: nameCtrl,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildLabeledFormField(
                        context,
                        label: 'NISN',
                        controller: nisnCtrl,
                        inputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildLabeledDropdownRow(
                        context: context,
                        label: 'Kelas',
                        value: selectedClass,
                        items: availableClasses,
                        onChanged: (v) =>
                            setLocal(() => selectedClass = v ?? selectedClass),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildLabeledFormField(
                        context,
                        label: 'Nomor HP Orang Tua (WhatsApp)',
                        controller: parentPhoneCtrl,
                        hint: 'Masukkan nomor...',
                        inputType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildLabeledFormField(
                  context,
                  label: 'Email',
                  controller: emailCtrl,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 22),

                // 2. USERNAME
                _sectionLabel(context, 'USERNAME'),
                const SizedBox(height: 10),
                _buildLabeledFormField(
                  context,
                  label: 'Username',
                  controller: usernameCtrl,
                ),
                const SizedBox(height: 22),

                // 3. PENGATURAN SALDO & KARTU
                _sectionLabel(context, 'PENGATURAN SALDO & KARTU'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildLabeledFormField(
                        context,
                        label: 'Saldo Awal / Batas Harian',
                        controller: limitCtrl,
                        inputType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildLabeledFormField(
                        context,
                        label: 'UID Kartu (RFID)',
                        controller: rfidCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Nebula.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
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

                            if (name.isEmpty ||
                                nisn.isEmpty ||
                                email.isEmpty ||
                                username.isEmpty ||
                                rfid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.adminFieldRequiredRfid),
                                ),
                              );
                              return;
                            }

                            setLocal(() => isSaving = true);
                            try {
                              final apiClient = ref.read(apiClientProvider);
                              final int parsedLimit = int.tryParse(limitText) ?? 0;
                              final rfidVal = rfid.isNotEmpty ? rfid : null;

                              final response = await apiClient.put(
                                '/admin/students/${profile.id}',
                                body: {
                                  'full_name': name,
                                  'email': email,
                                  'username': username,
                                  'nisn': nisn,
                                  'phone_number': phone.isEmpty ? null : phone,
                                  'daily_limit': parsedLimit,
                                  'rfid_uid': rfidVal,
                                  'class': selectedClass,
                                },
                              );

                              if (!response.success) {
                                throw Exception(response.message ?? 'Gagal memperbarui profil siswa');
                              }

                              // Invalidate details and user list providers
                              ref.invalidate(
                                adminStudentDetailProvider(profile.id),
                              );
                              ref.invalidate(adminUsersProvider);

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Profil siswa $name berhasil diperbarui',
                                    ),
                                    backgroundColor: Nebula.teal,
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => isSaving = false);
                              String rawError = e.toString();
                              String errorMsg = rawError;
                              if (rawError.contains('23505') ||
                                  rawError.contains('already exists') ||
                                  rawError.contains('unique constraint')) {
                                errorMsg =
                                    'NISN, Username, atau RFID UID sudah terdaftar pada pengguna lain.';
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppStrings.labelFailedSave}: $errorMsg',
                                    ),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
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

Widget _buildLabeledFormField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  String? hint,
  TextInputType inputType = TextInputType.text,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: inputType,
        style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: context.textSecondary.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          filled: true,
          fillColor: context.surfaceBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.dividerCol.withValues(alpha: 0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.dividerCol.withValues(alpha: 0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Nebula.teal, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

Widget _buildLabeledDropdownRow({
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
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 48,
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerCol.withValues(alpha: 0.6)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(CupertinoIcons.chevron_down, size: 14, color: Nebula.teal),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
            dropdownColor: context.cardBg,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}
