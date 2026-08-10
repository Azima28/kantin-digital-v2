import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/features/siswa/providers/siswa_providers.dart';

/// Shows a custom modern dialog to freeze or activate the student card.
Future<void> showFreezeCardDialog(
  BuildContext context,
  WidgetRef ref,
  bool currentStatus,
  String studentId,
) async {
  final isDark = context.isDark;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF242424) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (currentStatus ? Nebula.rose : Nebula.teal).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentStatus ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: currentStatus ? Nebula.rose : Nebula.teal,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentStatus ? 'Bekukan Kartu' : 'Aktifkan Kartu',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                currentStatus
                    ? 'Apakah Anda yakin ingin membekukan kartu? Kartu tidak akan bisa digunakan jajan sementara waktu.'
                    : 'Apakah Anda yakin ingin mengaktifkan kembali kartu Anda?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        AppStrings.buttonCancel,
                        style: GoogleFonts.poppins(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStatus ? Nebula.rose : Nebula.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final client = ref.read(supabaseClientProvider);
                          await client
                              .from('students')
                              .update({'is_active': !currentStatus})
                              .eq('id', studentId);

                          ref.invalidate(siswaStudentProvider);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(!currentStatus
                                    ? 'Kartu berhasil diaktifkan kembali!'
                                    : 'Kartu Anda telah dibekukan sementara.'),
                                backgroundColor: !currentStatus ? Nebula.teal : Nebula.rose,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${AppStrings.labelFailed} memproses status kartu'),
                                backgroundColor: Nebula.rose,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        currentStatus ? 'Ya, Bekukan' : 'Ya, Aktifkan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
