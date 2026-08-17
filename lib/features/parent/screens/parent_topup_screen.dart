import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/widgets/nebula_micro_interaction.dart';
import 'package:kantin_digital/core/widgets/nebula_effects.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/features/parent/widgets/parent_topup_form.dart';

class ParentTopUpScreen extends ConsumerStatefulWidget {
  final String studentId;
  const ParentTopUpScreen({super.key, required this.studentId});

  @override
  ConsumerState<ParentTopUpScreen> createState() => _ParentTopUpScreenState();
}

class _ParentTopUpScreenState extends ConsumerState<ParentTopUpScreen> {
  String _studentName = AppStrings.adminStudents;
  String _studentClass = '';

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/student/lookup', queryParams: {'id': widget.studentId});

      if (response.success && response.data != null) {
        final profile = response.data as Map<String, dynamic>;
        setState(() {
          _studentName = profile['full_name']?.toString() ?? AppStrings.adminStudents;
          _studentClass = profile['class']?.toString() ?? '';
        });
      }
    } catch (_) {
      // Keep defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header Bar
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                bottom: BorderSide(color: context.dividerCol, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                PressScale(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(CupertinoIcons.arrow_left, color: Nebula.teal, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kantin Digital',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Nebula.teal,
                  ),
                ),
              ],
            ),
          ),
          GradientLine(margin: const EdgeInsets.symmetric(vertical: 0)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ParentTopUpForm(
                    studentId: widget.studentId,
                    studentName: _studentName,
                    studentClass: _studentClass,
                  ),
                ),
              ),
            ),
          ),

          // Minimal Footer
          Container(
            decoration: BoxDecoration(
              color: context.surfaceBg,
              border: Border(top: BorderSide(color: context.dividerCol, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '© 2024 Kantin Digital. All rights reserved.',
                style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
