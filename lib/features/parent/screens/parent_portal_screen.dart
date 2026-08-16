/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/hallmark_color_scheme.dart';
import 'package:kantin_digital/core/theme/hallmark_typography.dart';
import 'package:kantin_digital/core/widgets/hallmark_button.dart';
import 'package:kantin_digital/core/widgets/hallmark_card.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';

/// Hallmark Parent Portal Screen — Editorial Bento Grid Entry Screen
class ParentPortalScreen extends ConsumerStatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  ConsumerState<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends ConsumerState<ParentPortalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nisController.dispose();
    super.dispose();
  }

  Future<void> _checkNis() async {
    if (!_formKey.currentState!.validate()) return;

    final String nisInput = _nisController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = ref.read(supabaseClientProvider);

      final response = await client.rpc('get_student_by_nisn', params: {
        'p_nisn': nisInput,
      });

      Map<String, dynamic> result;
      if (response is Map<String, dynamic>) {
        result = response;
      } else if (response is String) {
        result = jsonDecode(response) as Map<String, dynamic>;
      } else {
        result = {};
      }

      if (result['found'] == false) {
        setState(() {
          _errorMessage = 'NIS / Kode Unik Siswa tidak ditemukan';
        });
        return;
      }

      final profile = result;
      final String role = profile['role'] ?? '';
      final String studentId = profile['id'];

      if (role != 'student') {
        setState(() {
          _errorMessage = 'Kode yang dimasukkan bukan milik siswa';
        });
        return;
      }

      if (mounted) {
        context.go('/parent/dashboard/$studentId');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memeriksa data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: HallmarkCard(
                padding: const EdgeInsets.all(28),
                backgroundColor: colors.surfaceContainer,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Action
                      Align(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context.go('/welcome'),
                          icon: Icon(CupertinoIcons.left_chevron, size: 14, color: colors.brandPrimary),
                          label: Text(
                            AppStrings.buttonBack,
                            style: HallmarkTypography.bodySmall(colors.brandPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand Mark
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colors.brandPrimary.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          CupertinoIcons.creditcard,
                          color: colors.brandPrimary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'KANTIN DIGITAL',
                        style: HallmarkTypography.headingL2(colors.brandPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portal Orang Tua Siswa',
                        style: HallmarkTypography.bodySmall(colors.textMuted),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Cek Saldo & Aktivitas Anak',
                        style: HallmarkTypography.titleL3(colors.textPrimary),
                      ),
                      const SizedBox(height: 20),

                      // NIS Input Field
                      TextFormField(
                        controller: _nisController,
                        keyboardType: TextInputType.number,
                        style: HallmarkTypography.bodyMain(colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Masukkan NIS / Kode Unik Siswa',
                          prefixIcon: Icon(
                            CupertinoIcons.person_crop_square_fill,
                            size: 20,
                            color: colors.textMuted,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'NIS / Kode Unik Siswa wajib diisi';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _checkNis(),
                      ),
                      const SizedBox(height: 12),

                      if (_errorMessage != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _errorMessage!,
                            style: HallmarkTypography.bodySmall(colors.statusError),
                          ),
                        ),
                      const SizedBox(height: 24),

                      HallmarkButton(
                        label: 'Periksa Data Siswa',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _checkNis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
