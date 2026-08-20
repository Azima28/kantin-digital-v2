import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/admin/providers/admin_providers.dart';

/// Shows the Import Users from CSV dialog.
/// This dialog is role-aware and adapts the CSV format based on [roleFilter].
void showImportUsersDialog(BuildContext context, WidgetRef ref, String roleFilter) {
  final TextEditingController csvCtrl = TextEditingController();
  bool isProcessing = false;

  String formatGuidance = '';
  String hintText = '';
  String templateText = '';

  if (roleFilter == 'Siswa') {
    final academic = ref.read(academicStructureProvider).asData?.value;
    final r1 = (academic != null && academic.rombels.isNotEmpty) ? academic.rombels.first : 'X RPL 1';
    final r2 = (academic != null && academic.rombels.length > 1) ? academic.rombels[1] : 'X RPL 2';
    final r3 = (academic != null && academic.rombels.length > 2) ? academic.rombels[2] : 'XI RPL 1';

    formatGuidance =
        'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, NISN, Kelas/Rombel, Password';
    hintText =
        'Ahmad Fauzi, ahmad@sekolah.sch.id, 20260001, $r1, password123\nSiti Aminah, siti@sekolah.sch.id, 20260002, $r2, password123';
    templateText =
        'Ahmad Fauzi, ahmad@sekolah.sch.id, 20260001, $r1, password123\n'
            'Siti Aminah, siti@sekolah.sch.id, 20260002, $r2, password123\n'
            'Budi Santoso, budi@sekolah.sch.id, 20260003, $r3, password123';
  } else if (roleFilter == 'Orang Tua') {
    formatGuidance =
        'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, No Telepon, NISN Anak, Hubungan, Password';
    hintText =
        'Salim Subarjo, salim@example.com, +628****5678, 20260001, Ayah, password123';
    templateText =
        'Salim Subarjo, salim@example.com, +628****5678, 20260001, Ayah, password123\n'
            'Rina Aminah, rina@example.com, +628****5432, 20260002, Ibu, password123';
  } else if (roleFilter == 'Kantin') {
    formatGuidance =
        'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, Nama Stan, Username, Password';
    hintText =
        'Stan Bakso, bakso@canteen.com, Stan Bakso Enak, bakso_stan, password123';
    templateText =
        'Stan Bakso, bakso@canteen.com, Stan Bakso Enak, bakso_stan, password123\n'
            'Stan Nasi Goreng, nasgor@canteen.com, Stan Nasgor, nasgor_stan, password123';
  } else if (roleFilter == 'Keuangan') {
    formatGuidance =
        'Format CSV (tanpa spasi/koma berlebih):\nNama, Email, Sekolah, Tingkat Wewenang (L1/L2/L3), Password';
    hintText =
        'Budi Finance, budi.fin@sekolah.sch.id, SMK Negeri 1, L1, password123';
    templateText =
        'Budi Finance, budi.fin@sekolah.sch.id, SMK Negeri 1, L1, password123\n'
            'Siti Finance, siti.fin@sekolah.sch.id, SMK Negeri 1, L2, password123';
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(
            'Import $roleFilter Baru (CSV)',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatGuidance,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: csvCtrl,
                  maxLines: 8,
                  style:
                      const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              csvCtrl.text = templateText;
                            },
                      child: Text('Gunakan Template',
                          style: GoogleFonts.inter(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isProcessing ? null : () => Navigator.pop(ctx),
              child: Text(AppStrings.buttonCancel,
                  style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Nebula.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      final text = csvCtrl.text.trim();
                      if (text.isEmpty) return;

                      setLocal(() {
                        isProcessing = true;
                      });

                      final apiClient = ref.read(apiClientProvider);
                      final lines = text.split('\n');
                      int successCount = 0;
                      int failCount = 0;
                      List<String> errors = [];

                      for (var line in lines) {
                        final trimmed = line.trim();
                        if (trimmed.isEmpty) continue;

                        if (trimmed.toLowerCase().startsWith('nama,') ||
                            trimmed.toLowerCase().startsWith('name,') ||
                            trimmed.toLowerCase().startsWith('email,')) {
                          continue;
                        }

                        final parts = trimmed.split(',');

                        if (roleFilter == 'Siswa') {
                          if (parts.length < 5) {
                            failCount++;
                            errors.add('Format salah (baris: "$trimmed")');
                            continue;
                          }
                          final name = parts[0].trim();
                          final email = parts[1].trim();
                          final nisn = parts[2].trim();
                          final sClass = parts[3].trim();
                          final password = parts[4].trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              nisn.isEmpty ||
                              sClass.isEmpty ||
                              password.isEmpty) {
                            failCount++;
                            errors.add('Data kolom kosong (baris: "$trimmed")');
                            continue;
                          }

                          try {
                            final username = 'student_$nisn';
                            final resp = await apiClient.post('/admin/students', body: {
                              'email': email,
                              'password': password,
                              'full_name': name,
                              'username': username,
                              'nisn': nisn,
                              'class': sClass,
                            });
                            if (resp.success) {
                              successCount++;
                            } else {
                              failCount++;
                              errors.add('Error $name: ${resp.message}');
                            }
                          } catch (e) {
                            failCount++;
                            errors.add('Error $name: $e');
                          }
                        } else if (roleFilter == 'Orang Tua') {
                          if (parts.length < 6) {
                            failCount++;
                            errors.add('Format salah (baris: "$trimmed")');
                            continue;
                          }
                          final name = parts[0].trim();
                          final email = parts[1].trim();
                          final phone = parts[2].trim();
                          final childNisn = parts[3].trim();
                          final relation = parts[4].trim();
                          final password = parts[5].trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              phone.isEmpty ||
                              childNisn.isEmpty ||
                              relation.isEmpty ||
                              password.isEmpty) {
                            failCount++;
                            errors.add('Data kolom kosong (baris: "$trimmed")');
                            continue;
                          }

                          try {
                            final resp = await apiClient.post('/admin/users', body: {
                              'email': email,
                              'password': password,
                              'full_name': name,
                              'role': 'parent',
                              'phone_number': phone,
                              'relation': relation,
                              'student_nisn': childNisn,
                            });

                            if (resp.success) {
                              successCount++;
                            } else {
                              failCount++;
                              errors.add('Error $name: ${resp.message}');
                            }
                          } catch (e) {
                            failCount++;
                            errors.add('Error $name: $e');
                          }
                        } else if (roleFilter == 'Kantin') {
                          if (parts.length < 5) {
                            failCount++;
                            errors.add('Format salah (baris: "$trimmed")');
                            continue;
                          }
                          final name = parts[0].trim();
                          final email = parts[1].trim();
                          final canteenName = parts[2].trim();
                          final username = parts[3].trim();
                          final password = parts[4].trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              canteenName.isEmpty ||
                              username.isEmpty ||
                              password.isEmpty) {
                            failCount++;
                            errors.add('Data kolom kosong (baris: "$trimmed")');
                            continue;
                          }

                          try {
                            final resp = await apiClient.post('/admin/canteen-operators', body: {
                              'email': email,
                              'password': password,
                              'full_name': name,
                              'username': username,
                              'canteen_name': canteenName,
                            });
                            if (resp.success) {
                              successCount++;
                            } else {
                              failCount++;
                              errors.add('Error $name: ${resp.message}');
                            }
                          } catch (e) {
                            failCount++;
                            errors.add('Error $name: $e');
                          }
                        } else if (roleFilter == 'Keuangan') {
                          if (parts.length < 5) {
                            failCount++;
                            errors.add('Format salah (baris: "$trimmed")');
                            continue;
                          }
                          final name = parts[0].trim();
                          final email = parts[1].trim();
                          final school = parts[2].trim();
                          final authLevel = parts[3].trim();
                          final password = parts[4].trim();

                          if (name.isEmpty ||
                              email.isEmpty ||
                              school.isEmpty ||
                              authLevel.isEmpty ||
                              password.isEmpty) {
                            failCount++;
                            errors.add('Data kolom kosong (baris: "$trimmed")');
                            continue;
                          }

                          try {
                            final resp = await apiClient.post('/admin/finance-officers', body: {
                              'email': email,
                              'password': password,
                              'full_name': name,
                              'assigned_school': school,
                              'authority_level': authLevel,
                            });

                            if (resp.success) {
                              successCount++;
                            } else {
                              failCount++;
                              errors.add('Error $name: ${resp.message}');
                            }
                          } catch (e) {
                            failCount++;
                            errors.add('Error $name: $e');
                          }
                        }
                      }

                      // Refresh list
                      ref.invalidate(adminUsersProvider);

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        // Show results
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text('Hasil Import',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold)),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Berhasil: $successCount $roleFilter',
                                    style: GoogleFonts.inter(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${AppStrings.labelFailed}: $failCount $roleFilter',
                                    style: GoogleFonts.inter(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (errors.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text('${AppStrings.titleDetail} Error:',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    ...errors.map(
                                      (err) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Text('- $err',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.red)),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: Text('Tutup',
                                    style: GoogleFonts.inter()),
                              )
                            ],
                          ),
                        );
                      }
                    },
              child: isProcessing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CupertinoActivityIndicator(color: context.cardBg))
                  : Text('Proses Import',
                      style: GoogleFonts.inter()),
            )
          ],
        );
      },
    ),
  );
}